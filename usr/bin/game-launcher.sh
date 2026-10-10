#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║   WehttamSnaps — Rofi Game Launcher                             ║
# ║   Author : Matthew (GitHub: Crowdrocker)                        ║
# ║                                                                  ║
# ║   Features:                                                      ║
# ║     • Auto-scans Steam library on LINUXDRIVE                    ║
# ║     • Manual extras from games.conf                             ║
# ║     • Cover art from Steam CDN (cached locally)                 ║
# ║     • Launches via steam://rungameid/APPID                      ║
# ║     • iDroid sound on launch                                    ║
# ║     • Cyberpunk HUD rofi theme                                  ║
# ║                                                                  ║
# ║   Usage:                                                         ║
# ║     game-launcher.sh              open launcher                 ║
# ║     game-launcher.sh --scan       scan + cache covers only      ║
# ║     game-launcher.sh --list       print detected games          ║
# ║     game-launcher.sh --clear      clear cover art cache         ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════
# CONFIG
# ══════════════════════════════════════════════════════════════════

STEAM_LIBRARY="/run/media/wehttamsnaps/LINUXDRIVE/SteamLibrary"
STEAM_APPS="$STEAM_LIBRARY/steamapps"
STEAM_DEFAULT="$HOME/.steam/steam/steamapps"
GAMES_CONF="$HOME/.config/wehttamsnaps/games.conf"
COVER_CACHE="$HOME/.cache/wehttamsnaps/covers"
COVER_SIZE="300x450"          # portrait cover art ratio
FALLBACK_COVER="$HOME/.config/wehttamsnaps/covers/fallback.jpg"
SOUND="/usr/local/bin/sound-system"
THEME="$HOME/.config/rofi/themes/wehttamsnaps-games.rasi"
LOG="$HOME/.cache/wehttamsnaps/game-launcher.log"

# Steam CDN cover art URL template
# portrait (library covers) — 300×450
STEAM_CDN="https://steamcdn-a.akamaihd.net/steam/apps/%s/library_600x900_2x.jpg"
# fallback header image
STEAM_HEADER="https://steamcdn-a.akamaihd.net/steam/apps/%s/header.jpg"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$COVER_CACHE"
mkdir -p "$(dirname "$LOG")"
mkdir -p "$HOME/.config/wehttamsnaps"

# ══════════════════════════════════════════════════════════════════
# LOGGING
# ══════════════════════════════════════════════════════════════════

log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

# ══════════════════════════════════════════════════════════════════
# STEAM LIBRARY SCAN
# ══════════════════════════════════════════════════════════════════

# Returns lines of "AppID|Name" from steamapps/appmanifest_*.acf files
scan_steam_library() {
    local dirs=()

    # Primary gaming drive
    [[ -d "$STEAM_APPS" ]] && dirs+=("$STEAM_APPS")

    # Default Steam install
    [[ -d "$STEAM_DEFAULT" ]] && dirs+=("$STEAM_DEFAULT")

    # Extra libraries from libraryfolders.vdf
    local vdf="$HOME/.steam/steam/steamapps/libraryfolders.vdf"
    if [[ -f "$vdf" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ \"path\"[[:space:]]+\"([^\"]+)\" ]]; then
                local extra_path="${BASH_REMATCH[1]}/steamapps"
                [[ -d "$extra_path" ]] && dirs+=("$extra_path")
            fi
        done < "$vdf"
    fi

    for dir in "${dirs[@]}"; do
        for acf in "$dir"/appmanifest_*.acf; do
            [[ -f "$acf" ]] || continue

            local appid name
            appid=$(grep -m1 '"appid"' "$acf" 2>/dev/null | grep -oP '"\K[0-9]+(?=")' || true)
            name=$(grep -m1 '"name"' "$acf" 2>/dev/null | grep -oP '"\K[^"]+(?="[^"]*$)' || true)

            # Skip empty, tools, and Proton/redistributables
            [[ -z "$appid" || -z "$name" ]] && continue
            [[ "$name" =~ ^(Proton|Steam\ Linux|Steamworks|DirectX|Microsoft|vcredist|dotnet) ]] && continue
            [[ "$appid" -lt 100 ]] && continue

            echo "${appid}|${name}"
        done
    done | sort -t'|' -k2 | uniq
}

# ══════════════════════════════════════════════════════════════════
# MANUAL GAME LIST
# ══════════════════════════════════════════════════════════════════

read_manual_games() {
    [[ ! -f "$GAMES_CONF" ]] && return

    while IFS='|' read -r name appid cover_path; do
        # Skip comments and blank lines
        [[ "$name" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${name// }" ]] && continue

        appid="${appid// /}"
        [[ -z "$appid" || "$appid" == "0" ]] && continue

        echo "${appid}|${name}"
    done < "$GAMES_CONF"
}

# ══════════════════════════════════════════════════════════════════
# COVER ART
# ══════════════════════════════════════════════════════════════════

# Download cover art for a given AppID if not already cached
fetch_cover() {
    local appid="$1"
    local dst="$COVER_CACHE/${appid}.jpg"

    [[ -f "$dst" ]] && echo "$dst" && return

    # Try portrait library cover first
    local url
    url=$(printf "$STEAM_CDN" "$appid")

    if command -v curl &>/dev/null; then
        if curl -sf --max-time 5 -o "$dst" "$url" 2>/dev/null; then
            log "Downloaded cover: $appid"
            echo "$dst"
            return
        fi
        # Fallback to header image
        url=$(printf "$STEAM_HEADER" "$appid")
        if curl -sf --max-time 5 -o "$dst" "$url" 2>/dev/null; then
            log "Downloaded header: $appid"
            echo "$dst"
            return
        fi
    fi

    # Use fallback cover
    [[ -f "$FALLBACK_COVER" ]] && echo "$FALLBACK_COVER" || echo ""
}

# Pre-fetch covers for all games (called by --scan)
prefetch_covers() {
    local games
    mapfile -t games < <(build_game_list)

    local total=${#games[@]}
    local i=0

    echo -e "${CYAN}Fetching cover art for ${total} games...${NC}"

    for entry in "${games[@]}"; do
        local appid name
        appid=$(cut -d'|' -f1 <<< "$entry")
        name=$(cut -d'|' -f2 <<< "$entry")
        (( i++ )) || true

        local dst="$COVER_CACHE/${appid}.jpg"
        if [[ ! -f "$dst" ]]; then
            printf "  [%d/%d] %s..." "$i" "$total" "$name"
            fetch_cover "$appid" > /dev/null
            echo -e " ${GREEN}✓${NC}"
        else
            printf "  [%d/%d] %s... ${CYAN}cached${NC}\n" "$i" "$total" "$name"
        fi
    done

    echo -e "\n${GREEN}✓ Cover art cache complete${NC}"
    echo "  Location: $COVER_CACHE"
}

# Create a fallback cover image (solid dark with text) using ImageMagick
create_fallback_cover() {
    local dst="$HOME/.config/wehttamsnaps/covers/fallback.jpg"
    mkdir -p "$(dirname "$dst")"

    if command -v convert &>/dev/null; then
        convert -size 300x450 \
            gradient:"#0d0a1a-#130f22" \
            -fill "#00ffd133" \
            -draw "rectangle 0,0 299,449" \
            -fill "#00ffd1" \
            -font "Share-Tech-Mono" \
            -pointsize 20 \
            -gravity center \
            -annotate 0 "NO COVER" \
            "$dst" 2>/dev/null && \
            log "Created fallback cover" || true
    fi

    echo "$dst"
}

# ══════════════════════════════════════════════════════════════════
# BUILD MERGED GAME LIST
# ══════════════════════════════════════════════════════════════════

build_game_list() {
    # Merge Steam scan + manual list, deduplicate by AppID
    declare -A seen

    # Steam scan gets priority for names
    while IFS='|' read -r appid name; do
        [[ -z "$appid" ]] && continue
        seen["$appid"]="$name"
    done < <(scan_steam_library)

    # Manual extras — only add if AppID not already seen
    while IFS='|' read -r appid name; do
        [[ -z "$appid" ]] && continue
        [[ -z "${seen[$appid]+x}" ]] && seen["$appid"]="$name"
    done < <(read_manual_games)

    # Output sorted by name
    for appid in "${!seen[@]}"; do
        echo "${appid}|${seen[$appid]}"
    done | sort -t'|' -k2
}

# ══════════════════════════════════════════════════════════════════
# ROFI DISPLAY
# ══════════════════════════════════════════════════════════════════

# Build the rofi input — one line per game with icon path annotation
build_rofi_input() {
    local games
    mapfile -t games < <(build_game_list)
    local count=${#games[@]}

    # Rofi reads: "Display name\0icon\x1f/path/to/icon.jpg\n"
    for entry in "${games[@]}"; do
        local appid name cover
        appid=$(cut -d'|' -f1 <<< "$entry")
        name=$(cut -d'|' -f2 <<< "$entry")
        cover=$(fetch_cover "$appid")

        if [[ -n "$cover" ]]; then
            printf "%s\0icon\x1f%s\n" "$name" "$cover"
        else
            printf "%s\n" "$name"
        fi
    done

    log "Built rofi input: ${count} games"
}

# Map a selected game name back to its AppID
name_to_appid() {
    local selected="$1"
    build_game_list | while IFS='|' read -r appid name; do
        [[ "$name" == "$selected" ]] && echo "$appid" && return
    done
}

# ══════════════════════════════════════════════════════════════════
# LAUNCH
# ══════════════════════════════════════════════════════════════════

launch_game() {
    local appid="$1"
    local name="$2"

    log "Launching: $name (AppID: $appid)"

    # iDroid launch sound
    [[ -x "$SOUND" ]] && "$SOUND" steam-launch 2>/dev/null &

    # Notify
    command -v notify-send &>/dev/null && \
        notify-send "iDROID" "Launching: $name" \
            -i "$COVER_CACHE/${appid}.jpg" \
            -t 3000 2>/dev/null || true

    # Launch via Steam protocol
    xdg-open "steam://rungameid/${appid}" &

    log "Launch command sent: steam://rungameid/${appid}"
}

# ══════════════════════════════════════════════════════════════════
# MAIN LAUNCHER
# ══════════════════════════════════════════════════════════════════

open_launcher() {
    # Make sure Steam is running (needed for xdg-open protocol)
    if ! pgrep -x steam > /dev/null 2>&1; then
        log "Steam not running — starting Steam first"
        steam -silent &
        sleep 2
    fi

    local games
    mapfile -t games < <(build_game_list)
    local count=${#games[@]}

    # Build rofi input
    local rofi_input
    rofi_input=$(build_rofi_input)

    local game_count_msg="iDROID GAME LIBRARY  ·  ${count} GAMES  ·  WEHTTAMSNAPS"

    # Check theme exists, fall back to default
    local theme_arg=()
    if [[ -f "$THEME" ]]; then
        theme_arg=(-theme "$THEME")
    else
        theme_arg=(-theme "~/.config/rofi/themes/wehttamsnaps.rasi")
    fi

    # Launch rofi
    local selected
    selected=$(echo "$rofi_input" | rofi \
        -dmenu \
        -i \
        -p "game ❯" \
        -mesg "$game_count_msg" \
        -show-icons \
        -icon-size 148 \
        -eh 2 \
        -no-custom \
        "${theme_arg[@]}" \
        2>/dev/null) || true

    [[ -z "$selected" ]] && exit 0

    # Strip rofi's icon annotation if present
    selected="${selected%%$'\0'*}"

    # Look up AppID
    local appid
    appid=$(name_to_appid "$selected")

    if [[ -z "$appid" ]]; then
        log "Could not find AppID for: $selected"
        command -v notify-send &>/dev/null && \
            notify-send "Game Launcher" "Could not find AppID for: $selected" -t 3000 || true
        exit 1
    fi

    launch_game "$appid" "$selected"
}

# ══════════════════════════════════════════════════════════════════
# HELP
# ══════════════════════════════════════════════════════════════════

show_help() {
    cat << EOF

${CYAN}WehttamSnaps Game Launcher${NC}

${YELLOW}Usage:${NC}
  game-launcher.sh              Open the launcher
  game-launcher.sh --scan       Pre-fetch all cover art
  game-launcher.sh --list       Print detected games + AppIDs
  game-launcher.sh --clear      Clear cover art cache
  game-launcher.sh --help       This help

${YELLOW}Game sources:${NC}
  Steam scan   $STEAM_APPS
  Manual list  $GAMES_CONF

${YELLOW}Cover art cache:${NC}
  $COVER_CACHE

${YELLOW}Add to Niri config.kdl:${NC}
  Mod+Shift+G {
      spawn "sh" "-c" "/usr/local/bin/sound-system gaming-toggle && ~/.config/wehttamsnaps/scripts/game-launcher.sh";
  }

${YELLOW}Or a dedicated keybind:${NC}
  Mod+Alt+G {
      spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/game-launcher.sh";
  }

EOF
}

# ══════════════════════════════════════════════════════════════════
# ENTRY POINT
# ══════════════════════════════════════════════════════════════════

case "${1:-launch}" in
    launch|"")
        open_launcher
        ;;
    --scan|-s)
        echo -e "${CYAN}Scanning Steam library...${NC}"
        mapfile -t games < <(build_game_list)
        echo -e "${GREEN}Found ${#games[@]} games${NC}"
        prefetch_covers
        ;;
    --list|-l)
        echo -e "\n${CYAN}Detected games:${NC}\n"
        build_game_list | while IFS='|' read -r appid name; do
            local_cover="$COVER_CACHE/${appid}.jpg"
            cached=$([[ -f "$local_cover" ]] && echo "${GREEN}✓${NC}" || echo "${YELLOW}—${NC}")
            printf "  ${CYAN}%-10s${NC} %-45s %b\n" "$appid" "$name" "$cached"
        done
        echo ""
        ;;
    --clear|-c)
        echo -e "${YELLOW}Clearing cover art cache...${NC}"
        rm -f "$COVER_CACHE"/*.jpg
        echo -e "${GREEN}✓ Cache cleared: $COVER_CACHE${NC}"
        ;;
    --help|-h|help)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown argument: $1${NC}"
        show_help
        exit 1
        ;;
esac
