#!/usr/bin/env bash
# === WALLPAPER MANAGER ===
# WehttamSnaps Niri Setup
# GitHub: https://github.com/Crowdrocker
#
# Download wallpapers from Wallhaven API
# Integrates with Noctalia wallpaper selector

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
CONFIG_FILE="$HOME/.config/wehttamsnaps/wallpaper-config.json"
WALLPAPER_DIR="$HOME/.config/wehttamsnaps/wallpapers"
CACHE_DIR="$HOME/.cache/wehttamsnaps/wallpapers"
API_BASE="https://wallhaven.cc/api/v1"

# Create directories
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$CACHE_DIR"
mkdir -p "$(dirname "$CONFIG_FILE")"

# Function to load config
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE"
    else
        echo '{}'
    fi
}

# Function to save config
save_config() {
    local config="$1"
    echo "$config" > "$CONFIG_FILE"
}

# Function to get API key
get_api_key() {
    local config=$(load_config)
    echo "$config" | jq -r '.api_key // empty'
}

# Function to set API key
set_api_key() {
    local key="$1"
    local config=$(load_config)

    # Update or add api_key
    config=$(echo "$config" | jq --arg key "$key" '.api_key = $key')
    save_config "$config"

    echo -e "${GREEN}✓ API key saved${NC}"
    log "API key configured"
}

# Function to notify
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"

    if command -v notify-send &> /dev/null; then
        notify-send -u "$urgency" -a "Wallpaper Manager" "$title" "$message"
    fi
}

# Function to log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$CACHE_DIR/wallpaper-manager.log"
}

# Function to download wallpaper
download_wallpaper() {
    local url="$1"
    local filename="$2"
    local output="$WALLPAPER_DIR/$filename"

    echo -e "${BLUE}Downloading: $filename${NC}"

    if curl -L -o "$output" "$url" --progress-bar; then
        echo -e "${GREEN}✓ Downloaded: $filename${NC}"
        log "Downloaded: $filename from $url"
        return 0
    else
        echo -e "${RED}✗ Failed to download: $filename${NC}"
        log "Failed to download: $filename"
        return 1
    fi
}

# Function to search wallpapers
search_wallpapers() {
    local query="$1"
    local categories="${2:-111}"  # 111 = General, Anime, People
    local purity="${3:-100}"      # 100 = SFW only
    local sorting="${4:-toplist}" # toplist, random, date_added, relevance, views, favorites
    local page="${5:-1}"
    local per_page="${6:-24}"

    local api_key=$(get_api_key)
    local url="$API_BASE/search?q=$query&categories=$categories&purity=$purity&sorting=$sorting&page=$page&per_page=$per_page"

    # Add API key if available (allows NSFW and higher rate limits)
    if [[ -n "$api_key" ]]; then
        url="$url&apikey=$api_key"
    fi

    echo -e "${BLUE}Searching Wallhaven for: $query${NC}"
    log "Search query: $query (categories=$categories, purity=$purity, sorting=$sorting)"

    # Fetch results
    local response=$(curl -s "$url")

    # Check for errors
    if echo "$response" | jq -e '.error' &> /dev/null; then
        local error=$(echo "$response" | jq -r '.error')
        echo -e "${RED}✗ API Error: $error${NC}"
        log "API error: $error"
        return 1
    fi

    # Cache results
    echo "$response" > "$CACHE_DIR/last-search.json"

    # Display results
    local total=$(echo "$response" | jq -r '.meta.total')
    echo -e "${GREEN}Found $total wallpapers${NC}\n"

    echo "$response" | jq -r '.data[] | "\(.id) - \(.resolution) - \(.colors | join(", "))"' | nl

    return 0
}

# Function to download by ID
download_by_id() {
    local wallpaper_id="$1"
    local api_key=$(get_api_key)

    # Build URL
    local url="$API_BASE/w/$wallpaper_id"
    if [[ -n "$api_key" ]]; then
        url="$url?apikey=$api_key"
    fi

    echo -e "${BLUE}Fetching wallpaper info: $wallpaper_id${NC}"

    # Get wallpaper info
    local response=$(curl -s "$url")

    # Check for errors
    if echo "$response" | jq -e '.error' &> /dev/null; then
        local error=$(echo "$response" | jq -r '.error')
        echo -e "${RED}✗ API Error: $error${NC}"
        return 1
    fi

    # Extract download URL
    local download_url=$(echo "$response" | jq -r '.data.path')
    local resolution=$(echo "$response" | jq -r '.data.resolution')
    local category=$(echo "$response" | jq -r '.data.category')

    # Generate filename
    local filename="${wallpaper_id}_${resolution}.jpg"

    echo -e "${CYAN}Resolution: $resolution${NC}"
    echo -e "${CYAN}Category: $category${NC}"

    # Download
    if download_wallpaper "$download_url" "$filename"; then
        notify "Wallpaper Downloaded" "$filename ($resolution)" "normal"
        echo -e "\n${GREEN}Wallpaper saved to: $WALLPAPER_DIR/$filename${NC}"

        # Ask if user wants to set it
        read -p "Set as wallpaper now? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            set_wallpaper "$WALLPAPER_DIR/$filename"
        fi

        return 0
    else
        return 1
    fi
}

# Function to download from search results
download_from_search() {
    if [[ ! -f "$CACHE_DIR/last-search.json" ]]; then
        echo -e "${RED}✗ No search results cached. Run search first.${NC}"
        return 1
    fi

    # Show results again
    echo -e "${BLUE}Last search results:${NC}\n"
    cat "$CACHE_DIR/last-search.json" | jq -r '.data[] | "\(.id) - \(.resolution) - \(.colors | join(", "))"' | nl

    echo ""
    read -p "Enter wallpaper number to download (or 'all' for all): " selection

    if [[ "$selection" == "all" ]]; then
        # Download all results
        local ids=$(cat "$CACHE_DIR/last-search.json" | jq -r '.data[].id')
        local count=0

        echo -e "${BLUE}Downloading all wallpapers...${NC}"

        for id in $ids; do
            if download_by_id "$id"; then
                ((count++))
            fi
            sleep 1  # Rate limiting
        done

        notify "Batch Download Complete" "Downloaded $count wallpapers" "normal"
        echo -e "\n${GREEN}Downloaded $count wallpapers${NC}"
    else
        # Download single wallpaper
        local id=$(cat "$CACHE_DIR/last-search.json" | jq -r ".data[$((selection - 1))].id")

        if [[ -n "$id" ]] && [[ "$id" != "null" ]]; then
            download_by_id "$id"
        else
            echo -e "${RED}✗ Invalid selection${NC}"
            return 1
        fi
    fi
}

# Function to get random wallpapers
random_wallpapers() {
    local count="${1:-10}"
    local categories="${2:-111}"
    local purity="${3:-100}"

    echo -e "${BLUE}Fetching $count random wallpapers...${NC}"

    # Use toplist sorting with random seed
    search_wallpapers "" "$categories" "$purity" "random" "1" "$count"
}

# Function to set wallpaper via Noctalia
set_wallpaper() {
    local wallpaper_path="$1"

    if [[ ! -f "$wallpaper_path" ]]; then
        echo -e "${RED}✗ Wallpaper file not found: $wallpaper_path${NC}"
        return 1
    fi

    echo -e "${BLUE}Setting wallpaper...${NC}"

    # Try Noctalia first
    if command -v qs &> /dev/null; then
        qs -c noctalia-shell ipc call wallpaper set "$wallpaper_path" &> /dev/null || true
    fi

    # Fallback to swww if installed
    if command -v swww &> /dev/null; then
        swww img "$wallpaper_path" --transition-type fade --transition-duration 2 &> /dev/null || true
    fi

    # Fallback to swaybg if installed
    if command -v swaybg &> /dev/null; then
        pkill swaybg 2>/dev/null || true
        swaybg -i "$wallpaper_path" -m fill &> /dev/null &
    fi

    echo -e "${GREEN}✓ Wallpaper set${NC}"
    notify "Wallpaper Set" "$(basename "$wallpaper_path")" "normal"
    log "Wallpaper set: $wallpaper_path"
}

# Function to browse collections
browse_collections() {
    local username="$1"
    local api_key=$(get_api_key)

    if [[ -z "$api_key" ]]; then
        echo -e "${RED}✗ API key required to browse collections${NC}"
        echo -e "${YELLOW}Set your API key with: $0 set-key YOUR_KEY${NC}"
        return 1
    fi

    echo -e "${BLUE}Fetching collections for user: $username${NC}"

    local url="$API_BASE/collections/$username?apikey=$api_key"
    local response=$(curl -s "$url")

    # Check for errors
    if echo "$response" | jq -e '.error' &> /dev/null; then
        local error=$(echo "$response" | jq -r '.error')
        echo -e "${RED}✗ API Error: $error${NC}"
        return 1
    fi

    # Display collections
    echo "$response" | jq -r '.data[] | "\(.id) - \(.label) (\(.count) wallpapers)"' | nl

    echo ""
    read -p "Enter collection number to download: " selection

    local collection_id=$(echo "$response" | jq -r ".data[$((selection - 1))].id")

    if [[ -n "$collection_id" ]] && [[ "$collection_id" != "null" ]]; then
        download_collection "$username" "$collection_id"
    else
        echo -e "${RED}✗ Invalid selection${NC}"
        return 1
    fi
}

# Function to download collection
download_collection() {
    local username="$1"
    local collection_id="$2"
    local api_key=$(get_api_key)

    echo -e "${BLUE}Downloading collection $collection_id...${NC}"

    local url="$API_BASE/collections/$username/$collection_id?apikey=$api_key"
    local response=$(curl -s "$url")

    # Get all wallpaper IDs
    local ids=$(echo "$response" | jq -r '.data[].id')
    local count=0

    for id in $ids; do
        if download_by_id "$id"; then
            ((count++))
        fi
        sleep 1  # Rate limiting
    done

    notify "Collection Downloaded" "Downloaded $count wallpapers" "normal"
    echo -e "\n${GREEN}Downloaded $count wallpapers from collection${NC}"
}

# Function to show help
show_help() {
    cat << EOF
${BLUE}═══════════════════════════════════════════════════════════════${NC}
${BLUE}          WehttamSnaps Wallpaper Manager${NC}
${BLUE}═══════════════════════════════════════════════════════════════${NC}

${YELLOW}Usage:${NC} $0 [command] [options]

${YELLOW}Setup:${NC}
  set-key API_KEY       Save your Wallhaven API key
  show-key              Show current API key (masked)

${YELLOW}Search & Download:${NC}
  search QUERY          Search for wallpapers
  download ID           Download wallpaper by ID
  download-search       Download from last search results
  random [COUNT]        Get random wallpapers (default: 10)

${YELLOW}Collections:${NC}
  collections USER      Browse user's collections

${YELLOW}Management:${NC}
  list                  List downloaded wallpapers
  set PATH              Set wallpaper
  clean                 Remove downloaded wallpapers

${YELLOW}Examples:${NC}
  $0 set-key abc123def456
  $0 search "nature landscape"
  $0 download-search
  $0 random 20
  $0 collections username
  $0 set ~/Pictures/wallpaper.jpg

${YELLOW}Search Options:${NC}
  Categories: 111 (General+Anime+People), 100 (General only)
  Purity: 100 (SFW), 110 (SFW+Sketchy)
  Sorting: toplist, random, date_added, relevance, views, favorites

${YELLOW}Get API Key:${NC}
  1. Create account at https://wallhaven.cc
  2. Go to https://wallhaven.cc/settings/account
  3. Find "API Key" section
  4. Copy your key
  5. Run: $0 set-key YOUR_KEY

${YELLOW}Benefits of API Key:${NC}
  • Access to NSFW content (if you want)
  • Higher rate limits
  • Access to collections
  • Search your favorites
  • No rate limiting

${YELLOW}Locations:${NC}
  Config: $CONFIG_FILE
  Wallpapers: $WALLPAPER_DIR
  Cache: $CACHE_DIR

${BLUE}═══════════════════════════════════════════════════════════════${NC}
EOF
}

# Function to list downloaded wallpapers
list_wallpapers() {
    echo -e "${BLUE}Downloaded wallpapers:${NC}\n"

    if [[ ! -d "$WALLPAPER_DIR" ]] || [[ -z "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]]; then
        echo -e "${YELLOW}No wallpapers downloaded yet${NC}"
        return
    fi

    local count=0
    for file in "$WALLPAPER_DIR"/*; do
        if [[ -f "$file" ]]; then
            local size=$(du -h "$file" | cut -f1)
            local basename=$(basename "$file")
            echo -e "${GREEN}$basename${NC} (${size})"
            ((count++))
        fi
    done

    echo -e "\n${CYAN}Total: $count wallpapers${NC}"
    echo -e "${CYAN}Location: $WALLPAPER_DIR${NC}"
}

# Function to show API key (masked)
show_api_key() {
    local key=$(get_api_key)

    if [[ -z "$key" ]]; then
        echo -e "${YELLOW}No API key configured${NC}"
        echo -e "${BLUE}Get your key at: https://wallhaven.cc/settings/account${NC}"
        return 1
    fi

    # Mask key (show first 4 and last 4 chars)
    local masked="${key:0:4}...${key: -4}"
    echo -e "${GREEN}API Key: $masked${NC}"
}

# Function to clean wallpapers
clean_wallpapers() {
    echo -e "${YELLOW}This will delete all downloaded wallpapers.${NC}"
    read -p "Are you sure? [y/N] " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$WALLPAPER_DIR"/*
        echo -e "${GREEN}✓ Wallpapers cleaned${NC}"
        log "Wallpapers cleaned"
    else
        echo -e "${BLUE}Cancelled${NC}"
    fi
}

# Main logic
main() {
    local command="${1:-help}"

    case "$command" in
        set-key)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error: API key required${NC}"
                echo "Usage: $0 set-key YOUR_API_KEY"
                exit 1
            fi
            set_api_key "$2"
            ;;
        show-key)
            show_api_key
            ;;
        search)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error: Search query required${NC}"
                echo "Usage: $0 search 'your query'"
                exit 1
            fi
            search_wallpapers "$2" "${3:-111}" "${4:-100}" "${5:-toplist}"
            ;;
        download)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error: Wallpaper ID required${NC}"
                echo "Usage: $0 download WALLPAPER_ID"
                exit 1
            fi
            download_by_id "$2"
            ;;
        download-search)
            download_from_search
            ;;
        random)
            random_wallpapers "${2:-10}" "${3:-111}" "${4:-100}"
            ;;
        collections)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error: Username required${NC}"
                echo "Usage: $0 collections USERNAME"
                exit 1
            fi
            browse_collections "$2"
            ;;
        list)
            list_wallpapers
            ;;
        set)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error: Wallpaper path required${NC}"
                echo "Usage: $0 set /path/to/wallpaper.jpg"
                exit 1
            fi
            set_wallpaper "$2"
            ;;
        clean)
            clean_wallpapers
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Check for required commands
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required${NC}"
    echo "Install with: paru -S curl"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required${NC}"
    echo "Install with: paru -S jq"
    exit 1
fi

# Run main function
main "$@"
