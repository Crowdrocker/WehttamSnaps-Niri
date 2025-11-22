```bash
#!/bin/bash
# Quick verification script

echo "WehttamSnaps Setup Verification"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

total=0
found=0
missing=0
todo=0

check_file() {
    local file="$1"
    local required="$2"
    ((total++))

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
        ((found++))
    else
        if [ "$required" = "required" ]; then
            echo -e "${RED}✗${NC} $file (MISSING - REQUIRED)"
            ((missing++))
        else
            echo -e "${YELLOW}⚠${NC} $file (TODO - you need to create)"
            ((todo++))
        fi
    fi
}

check_executable() {
    local file="$1"
    ((total++))

    if [ -x "$file" ]; then
        echo -e "${GREEN}✓${NC} $file (executable)"
        ((found++))
    else
        echo -e "${RED}✗${NC} $file (missing or not executable)"
        ((missing++))
    fi
}

echo "ROOT FILES:"
check_file "README.md" "required"
check_file "install.sh" "required"
check_file "VERSION" "required"
check_file "logo.txt" "todo"
echo ""

echo "NIRI CONFIGS:"
check_file "configs/niri/config.kdl" "required"
check_file "configs/niri/conf.d/00-base.kdl" "required"
check_file "configs/niri/conf.d/10-keybinds.kdl" "required"
check_file "configs/niri/conf.d/20-rules.kdl" "required"
check_file "configs/niri/conf.d/30-workspaces.kdl" "required"
check_file "configs/niri/conf.d/99-overrides.kdl" "todo"
echo ""

echo "TERMINAL CONFIGS:"
check_file "configs/ghostty/config" "required"
check_file "configs/starship/starship.toml" "required"
check_file "configs/fastfetch/config.jsonc" "required"
check_file "configs/shell/.aliases" "required"
echo ""

echo "SCRIPTS:"
check_executable "scripts/install.sh"
check_executable "scripts/toggle-gamemode.sh"
check_executable "scripts/jarvis-manager.sh"
check_executable "scripts/webapp-launcher.sh"
check_executable "scripts/audio-setup.sh"
check_executable "scripts/KeyHints.sh"
check_executable "scripts/welcome.py"
check_executable "scripts/config-watcher.sh"
check_executable "scripts/wallpaper-manager.sh"
echo ""

echo "DOCUMENTATION:"
check_file "docs/QUICKSTART.md" "required"
check_file "docs/STEAM-LAUNCH-OPTIONS.md" "required"
check_file "docs/AUDIO-ROUTING.md" "required"
check_file "docs/TROUBLESHOOTING.md" "required"
check_file "docs/GAMING.md" "required"
check_file "docs/NIRI-COLOR-SCHEMES.md" "required"
check_file "docs/CONFIG-WATCHER.md" "required"
check_file "docs/WALLPAPER-MANAGER.md" "required"
echo ""

echo "WEBAPPS:"
webapp_count=$(ls -1 webapps/*.webapp 2>/dev/null | wc -l)
((total++))
if [ $webapp_count -eq 15 ]; then
    echo -e "${GREEN}✓${NC} All 15 webapp configs present"
    ((found++))
else
    echo -e "${YELLOW}⚠${NC} Only $webapp_count/15 webapp configs"
    ((todo++))
fi
echo ""

echo "PACKAGE LISTS:"
check_file "packages/core.list" "required"
check_file "packages/photography.list" "required"
check_file "packages/gaming.list" "required"
check_file "packages/streaming.list" "required"
check_file "packages/optional.list" "required"
check_file "packages/development.list" "required"
echo ""

echo "PLYMOUTH:"
check_file "plymouth/wehttamsnaps-spinner/wehttamsnaps-spinner.plymouth" "required"
check_file "plymouth/wehttamsnaps-spinner/wehttamsnaps-spinner.script" "required"
check_file "plymouth/wehttamsnaps-spinner/logo.png" "todo"
check_file "plymouth/wehttamsnaps-spinner/progress_bg.png" "todo"
check_file "plymouth/wehttamsnaps-spinner/progress_fill.png" "todo"
echo ""

echo "JARVIS SOUNDS:"
check_file "sounds/jarvis-startup.mp3" "todo"
check_file "sounds/jarvis-shutdown.mp3" "todo"
check_file "sounds/jarvis-notification.mp3" "todo"
check_file "sounds/jarvis-warning.mp3" "todo"
check_file "sounds/jarvis-gaming.mp3" "todo"
check_file "sounds/jarvis-streaming.mp3" "todo"
echo ""

echo "================================"
echo "SUMMARY:"
echo -e "${GREEN}✓ Found:${NC} $found/$total files"
echo -e "${RED}✗ Missing:${NC} $missing/$total files"
echo -e "${YELLOW}⚠ TODO:${NC} $todo/$total files (you need to create)"
echo ""

if [ $missing -eq 0 ]; then
    echo -e "${GREEN}All required files present!${NC}"
    if [ $todo -gt 0 ]; then
        echo -e "${YELLOW}You still need to create $todo files (sounds, images)${NC}"
    else
        echo -e "${GREEN}Setup is 100% complete!${NC}"
    fi
else
    echo -e "${RED}Missing $missing required files. Check the list above.${NC}"
fi
```
