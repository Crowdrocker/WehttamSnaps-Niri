# Package Reference

Package reference for iNiR, organized by category. The existing package tables
below describe the Arch-based install. Void Linux uses the same user-facing
profiles through XBPS plus a small set of pinned or Flatpak providers.

The PKGBUILDs live in `sdata/dist-arch/`.

> **`inir-deps`** is a meta-package that depends on all the groups below. It exists so that `pacman -Qdtq | pacman -Rns -` (clean orphans) doesn't remove iNiR's dependencies. It has no files of its own.

## Void Linux

Void uses the normal per-user installer with XBPS-backed dependency profiles.
The executable source of truth is `sdata/dist-void/install-deps.sh`; use
`docs/VOID_CAPABILITIES.md` for provider status and `docs/VOID.md` for the
runtime/install architecture. Provider versions and checksums live in the
installer script, not this reference.

Important Void package-name and provider differences:

| Capability | Void provider | Notes |
|---|---|---|
| Fish shell | `fish-shell` | Provides `/usr/bin/fish` |
| Qt 6 Qt5 compatibility | `qt6-qt5compat` | Void package name |
| Quickshell | `quickshell` | Official XBPS package |
| Python Pillow | `python3-Pillow` | Toolkit profile |
| Geolocation | `geoclue2` | Toolkit profile |
| ImageMagick | `ImageMagick` | Screencapture profile |
| Network editor | `network-manager-applet` | Base profile with `NetworkManager` |
| QML syntax highlighting | `kf6-syntax-highlighting` | Required base runtime for both sidebars |
| KDE integration | `kf6-kconfig`, `plasma-integration` | Toolkit/fonts-theme profiles |
| OCR | `tesseract-ocr` plus language packages | Vertical models are pinned upstream artifacts |
| Night light | `wlsunset` | Base profile |
| Wallpaper | `awww` | Official XBPS package |
| Darkly Qt style/settings | pinned Darkly v0.5.39 source + `kf6-kdecoration-devel` and other Qt6/KF6 build deps | Built with Qt6 and KDecoration enabled so both the KStyle and `darkly-settings6` KCM are present |

Validated non-XBPS providers are used only where Void does not provide a
suitable package: pinned upstream ydotool, WARP, adw-gtk3, WhiteSur,
Capitaine, Darkly, selected UI fonts and vertical OCR models, plus Mission
Center from Flathub.

The Void Darkly provider is intentionally stricter than a simple
`darkly6.so` presence check. A complete install also requires
`org.kde.kdecoration3.kcm/kcm_darklydecoration.so`; otherwise
`darkly-settings6` opens with a missing-plugin error even though normal Qt apps
can still use the style. Doctor treats that partial state as repairable.

Terminal theming is distro-independent. Foot's managed color file is
`~/.config/foot/inir-colors.ini`; `foot.ini` should include that path. The old
`~/.config/foot/colors.ini` name is treated as a legacy artifact and removed or
cleaned during repair/uninstall paths.

Void intentionally installs `dunst` for the `dunstify` client. The package
itself is not an installer conflict; a running `dunst` daemon remains a
runtime conflict.

---

## Core (`inir-core`)

Essential packages for Niri + ii to function.

| Package | Purpose |
|---------|---------|
| `niri` | Compositor |
| `awww` | Wallpaper daemon |
| `coreutils` | Basic utils |
| `cliphist` | Clipboard history |
| `curl` | HTTP requests |
| `ripgrep` | Fast search |
| `jq` | JSON parsing |
| `python` | Python interpreter (scripts) |
| `xdg-user-dirs` | User directories |
| `xdg-utils` | xdg-settings, xdg-open |
| `rsync` | File sync |
| `git` | Version control |
| `wl-clipboard` | Wayland clipboard (wl-copy, wl-paste) |
| `libnotify` | Notifications |
| `pacman-contrib` | checkupdates for update notifications |
| `wlsunset` | Night light / blue light filter |
| `xdg-desktop-portal` | XDG portal base |
| `xdg-desktop-portal-gtk` | GTK portal |
| `xdg-desktop-portal-gnome` | GNOME portal (screenshare) |
| `polkit` | Privilege elevation (iNiR shows the password dialog itself) |
| `networkmanager` | Network management |
| `gnome-keyring` | Secrets storage |
| `nautilus` | File manager |
| `kitty` | Terminal (default) |
| `fish` | Fish shell (required for scripts) |
| `gum` | TUI for setup script |
| `xwayland-satellite` | X11 compatibility |

---

## Quickshell (`inir-quickshell`)

Qt6 stack and Quickshell runtime.

### From official repos

| Package | Purpose |
|---------|---------|
| `qt6-declarative` | QML engine |
| `qt6-base` | Qt core |
| `qt6-svg` | SVG support |
| `qt6-wayland` | Wayland integration |
| `qt6-5compat` | Qt5 compatibility |
| `qt6-imageformats` | Image formats |
| `qt6-multimedia` | Media playback |
| `qt6-tools` | Qt tools |
| `qt6-translations` | Translations |
| `jemalloc` | Memory allocator |
| `libpipewire` | PipeWire integration |
| `libxcb` | X11 bridge |
| `wayland` | Wayland libs |
| `libdrm` | DRM/display |
| `mesa` | OpenGL |
| `kirigami` | KDE components |
| `kdialog` | KDE dialogs |
| `syntax-highlighting` | Code highlighting |
| `qt6ct` | Qt6 config tool |
| `breeze-icons` | Breeze icon theme (lightweight) |
| `plasma-integration` | KDE platform theme (reads kdeglobals for Qt colors) |

### From AUR

| Package | Purpose |
|---------|---------|
| `qt6-avif-image-plugin` | AVIF image support |

---

## Audio (`inir-audio`)

Audio stack and media controls.

| Package | Purpose |
|---------|---------|
| `pipewire` | Audio server |
| `pipewire-pulse` | PulseAudio compat |
| `pipewire-alsa` | ALSA compat |
| `wireplumber` | Session manager |
| `playerctl` | Media player control |
| `plasma-browser-integration` | Browser media sessions for MPRIS controls/artwork |
| `pavucontrol` | Volume control GUI |
| `mpv` | Media playback backend |
| `mpv-mpris` | MPRIS bridge for mpv |
| `yt-dlp` | YouTube extraction backend |
| `deno` | JavaScript runtime used by yt-dlp for current YouTube challenges |
| `yt-dlp-ejs` | YouTube challenge solver scripts (Arch/package-managed path) |
| `socat` | IPC fallback for YTMusic control |
| `cava` | Audio visualizer |
| `easyeffects` | Audio effects |
| `lsp-plugins-lv2` | EasyEffects equalizer backend |

`pipewire-jack` is an optional/recommended extra depending on your audio setup.

---

## Screenshots & Recording (`inir-screencapture`)

Region tools dependencies.

| Package | Purpose |
|---------|---------|
| `grim` | Screenshots |
| `slurp` | Region selection |
| `swappy` | Screenshot editor |
| `tesseract` | OCR engine |
| `tesseract-data-eng` / `spa` / `rus` | English, Spanish, Russian OCR data |
| `tesseract-data-jpn` / `jpn_vert` | Japanese horizontal/vertical OCR data |
| `tesseract-data-chi_sim*` / `chi_tra*` | Simplified/Traditional Chinese horizontal/vertical OCR data |
| `wf-recorder` | Screen recording |
| `imagemagick` | Image processing |
| `ffmpeg` | Video processing |

---

## Input Toolkit (`inir-toolkit`)

Input simulation, hardware control, and idle management.

| Package | Purpose |
|---------|---------|
| `upower` | Power management |
| `wtype` | Wayland typing |
| `ydotool` | Input simulation |
| `python-evdev` | Evdev bindings |
| `python-pillow` | Image processing |
| `brightnessctl` | Backlight control |
| `ddcutil` | DDC/CI for monitors |
| `geoclue` | Geolocation |
| `swayidle` | Idle management (screen off, lock, suspend) |
| `swaylock` | Screen locker |
| `blueman` | Bluetooth manager GUI |
| `fprintd` | Fingerprint authentication (lock screen) |
| `libqalculate` | Calculator backend |
| `tesseract` | OCR engine |
| `tesseract-data-eng` / `spa` / `rus` | English, Spanish, Russian OCR data |
| `tesseract-data-jpn` / `jpn_vert` | Japanese horizontal/vertical OCR data |
| `tesseract-data-chi_sim*` / `chi_tra*` | Simplified/Traditional Chinese horizontal/vertical OCR data |

---

## Fonts & Theming (`inir-fonts`)

Fonts, theming, and utilities.

### From official repos

| Package | Purpose |
|---------|---------|
| `fontconfig` | Font configuration |
| `ttf-dejavu` | DejaVu fonts |
| `ttf-liberation` | Liberation fonts |
| `glib2` | GLib utilities |
| `translate-shell` | Translation CLI |
| `kvantum` | Qt theming |

### Official packages recently promoted from AUR

`ttf-material-symbols-variable`, `ttf-jetbrains-mono-nerd`, `adw-gtk-theme`,
`capitaine-cursors`, `mission-center`, and `uv` are installed from Arch `extra`.
Keeping them on the mirror path avoids unnecessary AUR builds and is friendlier
to users whose networks cannot reliably reach GitHub/AUR endpoints.

### From AUR

| Package | Purpose | Required |
|---------|---------|----------|
| `darkly-bin` | Darkly Qt style (Material You widget style for Qt apps) | Yes |
| `ttf-roboto-flex` | Roboto Flex variable font | Yes (default UI font) |
| `ttf-oxanium` | Oxanium font | Yes (ZZZ and Angel styles) |
| `ttf-gabarito-git` | Gabarito variable font | Yes (default title font) |
| `ttf-readex-pro` | Readex Pro font | No (has fallback) |
| `ttf-rubik-vf` | Rubik variable font | No (has fallback) |
| `otf-space-grotesk` | Space Grotesk font | No (has fallback) |
| `ttf-twemoji` | Twitter emoji | No (has fallback) |

> **Note:** Optional fonts will be downloaded directly from GitHub if AUR packages are unavailable (e.g., due to regional restrictions). The UI will use system fallback fonts if installation fails completely.

---

## Optional

Not installed by default, but useful. The shell handles their absence gracefully.

| Package | Purpose | Used by |
|---------|---------|---------|
| `warp-cli` | Cloudflare WARP VPN toggle | Quick toggles panel |
| `ollama` | Local LLM for AI chat | Sidebar AI assistant |
| `whisper-cpp` | Local speech-to-text, no API key needed | Voice input and voice search |
| `cava` | Audio visualizer | Bar widget (optional) |
| `easyeffects` | Audio effects | Quick toggles panel |
| `lsp-plugins-lv2` | EasyEffects equalizer backend | Media Controls equalizer |
| `yt-dlp` | YouTube video/audio extraction | YTMusic sidebar |
| `mpv` | Media player | YTMusic sidebar |
| `deno` | JavaScript runtime for yt-dlp | YTMusic sidebar (YouTube challenge solving) |

> **Note:** `cava` and `easyeffects` are included in `inir-audio` but are optional features. The toggles will be hidden if the packages aren't installed.

> **YTMusic Requirements:** iNiR provisions its Python browsing runtime and a current playback `yt-dlp` (including SecretStorage and EJS support) in the managed venv. The shell selects that managed binary before an older distro copy. Playback also requires `mpv`, `socat`, and Deno >= 2.3. Package-managed Arch/Nix installations provide the equivalent closed runtime through their package metadata. `inir doctor` repairs the managed Python/Deno runtime instead of asking users to install Python packages manually.
