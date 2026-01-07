# ~/.bashrc or ~/.bash_aliases
# WehttamSnaps Cyberpunk Aliases

# ═══════════════════════════════════════════════════════════════════
# SYSTEM MAINTENANCE
# ═══════════════════════════════════════════════════════════════════

# Update system
alias update='sudo pacman -Syu && yay -Syu'
alias upd='sudo pacman -Syu'
alias upyay='yay -Syu'

# Clean package cache
alias clean='sudo pacman -Sc && yay -Sc'
alias cleanall='sudo pacman -Scc && yay -Scc'
alias cleancache='paccache -r && yay -Sc'

# Remove orphaned packages
alias orphans='sudo pacman -Rns $(pacman -Qtdq)'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null && echo "System cleaned!"'

# List explicitly installed packages
alias listpkgs='pacman -Qe'
alias listpkgsyay='yay -Qe'

# Search packages
alias search='pacman -Ss'
alias searchyay='yay -Ss'

# ═══════════════════════════════════════════════════════════════════
# SYSTEM INFO
# ═══════════════════════════════════════════════════════════════════

alias sysinfo='fastfetch'
alias hardware='inxi -Fxz'
alias diskspace='df -h | grep -E "^/dev/"'
alias meminfo='free -h'
alias cpuinfo='lscpu'

# ═══════════════════════════════════════════════════════════════════
# NIRI & WEHTTAMSNAPS
# ═══════════════════════════════════════════════════════════════════

# Edit configs
alias editniri='kate ~/.config/niri/config.kdl'
alias editkeybinds='kate ~/.config/niri/10-wiri_keybinds.kdl'
alias editstartup='kate ~/.config/niri/05-wiri_startup.kdl'
alias editrules='kate ~/.config/niri/20-wiri_rules.kdl'
alias editws='kate ~/.config/niri/30-workspaces.kdl'
alias editws='kate ~/.config/wehttamsnaps/'

# Niri management
alias nreload='niri msg action reload-config'
alias nvalidate='niri validate'
alias nquick='~/.config/niri/scripts/niri_quick_settings.sh'

# WehttamSnaps specific
alias welcome='python3 ~/.config/wehttamsnaps/scripts/welcome.py --force'
alias keyhints='~/.config/wehttamsnaps/scripts/KeyHints.sh'
alias jarvis='~/.config/wehttamsnaps/scripts/jarvis-manager.sh'

# ═══════════════════════════════════════════════════════════════════
# FILE OPERATIONS
# ═══════════════════════════════════════════════════════════════════

# Enhanced ls
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
alias llt='eza -la --tree --level=2 --icons'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias docs='cd ~/Documents'
alias dl='cd ~/Downloads'
alias pics='cd ~/Pictures'
alias vids='cd ~/Videos'
alias conf='cd ~/.config'
alias games='cd ~/Games'

# File operations with confirmation
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias mkdir='mkdir -pv'

# ═══════════════════════════════════════════════════════════════════
# APPLICATIONS
# ═══════════════════════════════════════════════════════════════════

# Browsers
alias brave='brave --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias vivaldi='vivaldi-stable --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias firefox='firefox-developer-edition'

# File managers
alias fm='thunar'
alias nfm='nautilus'

# Editors
alias v='nvim'
alias vim='nvim'
alias k='kate'

# ═══════════════════════════════════════════════════════════════════
# GAMING
# ═══════════════════════════════════════════════════════════════════

# Launch gaming mode
alias gamemode='~/.config/wehttamsnaps/scripts/jarvis-manager.sh'
alias gaming='sound-system gaming-toggle'

# Gaming platforms
alias steam='sound-system steam-launch && steam'
alias lutris='lutris'
alias heroic='heroic'

# Mod managers
alias vortex='wine ~/.wine/drive_c/Program\ Files/Vortex/Vortex.exe'
alias mo2='wine ~/.wine/drive_c/Modding/MO2/ModOrganizer.exe'

# ═══════════════════════════════════════════════════════════════════
# AUDIO & MEDIA
# ═══════════════════════════════════════════════════════════════════

# Audio routing
alias audioroute='~/.config/wehttamsnaps/scripts/audio-routing.sh gaming'
alias audiograph='qpwgraph'
alias audiomix='pavucontrol'

# Media players
alias music='spotify-launcher'
alias mpv='mpv --vo=gpu --hwdec=auto'

# ═══════════════════════════════════════════════════════════════════
# DEVELOPMENT
# ═══════════════════════════════════════════════════════════════════

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gpl='git pull'

# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv venv'
alias activate='source venv/bin/activate'

# ═══════════════════════════════════════════════════════════════════
# NETWORKING
# ═══════════════════════════════════════════════════════════════════

alias ports='netstat -tulanp'
alias myip='curl ifconfig.me'
alias localip='ip addr show | grep "inet " | grep -v 127.0.0.1'
alias speedtest='speedtest-cli'
alias ping='ping -c 5'

# ═══════════════════════════════════════════════════════════════════
# PROCESSES
# ═══════════════════════════════════════════════════════════════════

alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias killall='killall -v'
alias topcpu='ps auxf | sort -nr -k 3 | head -5'
alias topmem='ps auxf | sort -nr -k 4 | head -5'

# ═══════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════

# Quick edit this file
alias aliases='kate ~/.bash_aliases && source ~/.bash_aliases'

# Reload shell config
alias reload='source ~/.bashrc'

# Weather
alias weather='curl wttr.in'

# Copy to clipboard
alias copy='wl-copy'
alias paste='wl-paste'

# Quick notes
alias note='kate ~/Documents/notes.txt'

# Clock
alias clock='tty-clock -c -C 6 -r'

# ═══════════════════════════════════════════════════════════════════
# FUN STUFF
# ═══════════════════════════════════════════════════════════════════

alias matrix='cmatrix -C cyan'
alias pipes='pipes.sh'
alias starwars='telnet towel.blinkenlights.nl'

# ═══════════════════════════════════════════════════════════════════
# CUSTOM FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick backup
backup() {
    cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
}

# Find and replace in files
replace() {
    find . -type f -exec sed -i "s/$1/$2/g" {} +
}

# ═══════════════════════════════════════════════════════════════════
# STARTUP MESSAGE
# ═══════════════════════════════════════════════════════════════════

# Display cyberpunk greeting
echo -e "\033[1;36m"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   ╦ ╦┌─┐┬ ┬┌┬┐┌┬┐┌─┐┌┬┐╔═╗┌┐┌┌─┐┌─┐┌─┐"
echo "   ║║║├┤ ├─┤ │  │ ├─┤│││╚═╗│││├─┤├─┘└─┐"
echo "   ╚╩╝└─┘┴ ┴ ┴  ┴ ┴ ┴┴ ┴╚═╝┘└┘┴ ┴┴  └─┘"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "\033[0m"
echo -e "\033[1;35mThe future is now. Type 'welcome' to see the guide.\033[0m"
echo ""
