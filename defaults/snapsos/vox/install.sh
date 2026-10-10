#!/usr/bin/env bash
# install.sh — install system and Python dependencies for vox.
# Detects the package manager (pacman/apt/dnf), installs required
# libraries, optionally downloads the Vosk speech model, and verifies setup.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Color helpers for output.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
err()   { echo -e "${RED}[✗]${NC} $1"; }
header(){ echo -e "\n${BOLD}$1${NC}"; }

# Detect the system package manager.
detect_pm() {
    if   command -v pacman &>/dev/null; then echo "pacman"
    elif command -v apt   &>/dev/null; then echo "apt"
    elif command -v dnf   &>/dev/null; then echo "dnf"
    else echo "unknown"
    fi
}

PKG_MANAGER=$(detect_pm)

# List system packages needed for each distribution.
system_packages() {
    case "$PKG_MANAGER" in
        pacman)
            # whisper-cpp-vulkan provides whisper-cli, whisper-server, and
            # libwhisper.so.  On standard Arch try gst-plugin-whisper instead.
            if pacman -Si whisper-cpp-vulkan &>/dev/null; then
                WHISPER_PKG="whisper-cpp-vulkan"
            else
                WHISPER_PKG="gst-plugin-whisper"
            fi
            cat <<PKGS
python-gobject
gst-plugins-base
gst-plugins-good
gtk-layer-shell
pipewire
pipewire-pulse
ydotool
$WHISPER_PKG
PKGS
            ;;
        apt)
            cat <<PKGS
python3-gi
python3-gi-cairo
gir1.2-gstreamer-1.0
gstreamer1.0-plugins-base
gstreamer1.0-plugins-good
pipewire
pipewire-pulse
ydotool
PKGS
            ;;
        dnf)
            cat <<PKGS
python3-gobject
gstreamer1-plugins-base
gstreamer1-plugins-good
pipewire
pipewire-pulse
ydotool
PKGS
            ;;
        *)
            echo ""
            ;;
    esac
}

# Installation steps.
step_check_python() {
    header "1. Checking Python"
    if command -v python3 &>/dev/null; then
        info "Python $(python3 --version)"
    else
        err "python3 not found"
        exit 1
    fi
}

step_check_package_manager() {
    header "2. Checking package manager"
    case "$PKG_MANAGER" in
        pacman) info "Detected: pacman (Arch)" ;;
        apt)    info "Detected: apt (Debian/Ubuntu)" ;;
        dnf)    info "Detected: dnf (Fedora)" ;;
        *)
            warn "Unknown package manager — skipping system deps."
            warn "Install these manually:"
            warn "  python-gobject (PyGObject), GStreamer (base + good plugins),"
            warn "  pipewire (or pulseaudio), ydotool"
            ;;
    esac
}

step_install_system_deps() {
    header "3. System dependencies"

    local pkgs
    pkgs=$(system_packages)
    [[ -z "$pkgs" ]] && return

    echo "  The following packages are needed:"
    echo "$pkgs" | sed 's/^/    • /'

    read -r -p "  Install them with $PKG_MANAGER? [Y/n] " yn
    yn=${yn:-y}
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        case "$PKG_MANAGER" in
            pacman)
                sudo pacman -S --needed --noconfirm $pkgs
                ;;
            apt)
                sudo apt update && sudo apt install -y $pkgs
                ;;
            dnf)
                sudo dnf install -y $pkgs
                ;;
        esac
        info "System packages installed"
    else
        warn "Skipping system packages — install them manually if vox fails."
    fi
}

step_install_python_deps() {
    header "4. Python dependencies"
    info "All Python dependencies come from system packages (already installed)."
}

step_install_desktop() {
    header "5. Desktop file"

    local desktop_src="$SCRIPT_DIR/vox-config.desktop"
    local desktop_dst="${XDG_DATA_HOME:-$HOME/.local/share}/applications/vox-config.desktop"

    mkdir -p "$(dirname "$desktop_dst")"
    cp "$desktop_src" "$desktop_dst"
    info "Desktop file installed to $desktop_dst"
}

step_download_model() {
    header "6. Whisper speech model"

    local models_dir="${XDG_CONFIG_HOME:-$HOME/.config}/snapsos/vox/models"
    local model_path="$models_dir/ggml-medium.en.bin"

    if [[ -f "$model_path" ]]; then
        info "Whisper model already present at $model_path"
        return
    fi

    read -r -p "  Download the medium English Whisper model (~1.5 GB)? [Y/n] " yn
    yn=${yn:-y}
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        mkdir -p "$models_dir"
        local url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin"

        echo "  Downloading from Hugging Face (this may take a while)..."
        if command -v curl &>/dev/null; then
            curl -# -L "$url" -o "$model_path"
        elif command -v wget &>/dev/null; then
            wget --show-progress "$url" -O "$model_path"
        else
            err "Neither curl nor wget available — download manually:"
            err "  $url"
            err "  Place at: $model_path"
            return
        fi
        info "Model downloaded to $model_path"
    else
        warn "Model will be auto-downloaded on first 'vox daemon' run."
    fi
}

step_verify() {
    header "7. Verification"

    local errors=0

    # Python imports.
    if python3 -c "import gi" &>/dev/null; then
        info "PyGObject (gi) — OK"
        for mod in Gst Gtk; do
            if python3 -c "import gi; gi.require_version('Gst','1.0'); gi.require_version('Gtk','3.0'); from gi.repository import $mod" &>/dev/null; then
                info "PyGObject ($mod) — OK"
            else
                warn "PyGObject ($mod) — not available"
                ((errors++))
            fi
        done
    else
        warn "PyGObject (gi) — not available"
        ((errors++))
    fi

    # whisper-server (from whisper-cpp).
    if command -v whisper-server &>/dev/null; then
        info "whisper-server — OK"
    else
        warn "whisper-server — not found (needed for daemon mode; install whisper-cpp)"
        ((errors++))
    fi

    # gtk-layer-shell (Wayland overlay).
    if python3 -c "import gi; gi.require_version('GtkLayerShell','0.1'); from gi.repository import GtkLayerShell" &>/dev/null; then
        info "gtk-layer-shell — OK"
    else
        warn "gtk-layer-shell — not available (overlay window won't work; install gtk-layer-shell)"
        ((errors++))
    fi

    # ydotool.
    if command -v ydotool &>/dev/null; then
        info "ydotool — OK"
    else
        warn "ydotool — not found (needed for 'type' actions)"
        ((errors++))
    fi

    # Audio server (pipewire or pulseaudio).
    if command -v pw-cli &>/dev/null && pw-cli info &>/dev/null 2>&1; then
        info "PipeWire — running"
    elif command -v pactl &>/dev/null && pactl info &>/dev/null 2>&1; then
        info "PulseAudio — running"
    else
        warn "No audio server detected (pipewire/pulseaudio) — daemon won't capture mic"
        ((errors++))
    fi

    # Config file.
    if [[ -f "$SCRIPT_DIR/config.json" ]]; then
        python3 -c "
import sys, json
sys.path.insert(0, '$SCRIPT_DIR')
from vox.config_manager import load_config
load_config()
" &>/dev/null && info "config.json — valid" || { warn "config.json — parse error"; ((errors++)); }
    else
        warn "config.json — not found"
        ((errors++))
    fi

    if ((errors == 0)); then
        echo -e "\n${GREEN}${BOLD}All checks passed — vox is ready!${NC}"
    else
        echo -e "\n${YELLOW}${BOLD}$errors issue(s) found — review warnings above.${NC}"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo "${BOLD}vox — install script${NC}"
echo "===================="
echo "Repo: $SCRIPT_DIR"

step_check_python
step_check_package_manager
step_install_system_deps
step_install_python_deps
step_install_desktop
step_download_model
step_verify

echo ""
echo "  Run ${BOLD}vox daemon${NC} to start listening"
echo "  Run ${BOLD}vox config${NC} to open the tree editor"
echo ""
