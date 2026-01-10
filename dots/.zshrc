# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# ~/.config/wehttamsnaps/shell/.aliases
# WehttamSnaps Cyberpunk Aliases
# Cleaned up to work with existing .bashrc

# ═══════════════════════════════════════════════════════════════════
# SYSTEM MAINTENANCE
# ═══════════════════════════════════════════════════════════════════

# Update system (enhanced versions)
alias update='sudo pacman -Syu && yay -Syu'
alias upd='sudo pacman -Syu'
alias upyay='yay -Syu'
alias updall='sudo pacman -Syu && yay -Syu && flatpak update'

# Clean package cache
alias clean='sudo pacman -Sc && yay -Sc'
alias cleanall='sudo pacman -Scc && yay -Scc'
alias cleancache='paccache -r && yay -Sc'

# Remove orphaned packages
alias orphans='sudo pacman -Rns $(pacman -Qtdq)'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null && echo "✓ System cleaned!"'

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
alias meminfo='free -h'
alias cpuinfo='lscpu'

# ═══════════════════════════════════════════════════════════════════
# NIRI & WEHTTAMSNAPS
# ═══════════════════════════════════════════════════════════════════

# Edit configs
alias editniri='kate ~/.config/niri/config.kdl'
alias editkeybinds='kate ~/.config/niri/snaps/10-wiri_keybinds.kdl'
alias editstartup='kate ~/.config/niri/snaps/05-wiri_startup.kdl'
alias editrules='kate ~/.config/niri/snaps/20-wiri_rules.kdl'
alias editws='kate ~/.config/niri/snaps/30-workspaces.kdl'
alias editsnaps='kate ~/.config/wehttamsnaps/'
alias editalias='kate ~/.config/wehttamsnaps/shell/.aliases && source ~/.bashrc'

# Niri management
alias nreload='niri msg action reload-config'
alias nvalidate='niri validate'
alias nquick='~/.config/niri/scripts/niri_quick_settings.sh'

# WehttamSnaps specific
alias welcome='python3 ~/.config/wehttamsnaps/scripts/welcome.py --force'
alias keyhints='~/.config/wehttamsnaps/scripts/KeyHints.sh'
alias jarvis='~/.config/wehttamsnaps/scripts/jarvis-manager.sh'

# ═══════════════════════════════════════════════════════════════════
# FILE OPERATIONS (Enhanced with eza if available)
# ═══════════════════════════════════════════════════════════════════

# Override with eza if installed
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -la --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
    alias llt='eza -la --tree --level=2 --icons'
    alias lsa='eza -la --icons --group-directories-first'
fi

# Quick navigation (additional to existing)
alias docs='cd ~/Documents'
alias dl='cd ~/Downloads'
alias pics='cd ~/Pictures'
alias vids='cd ~/Videos'
alias conf='cd ~/.config'
alias games='cd ~/Games'
alias snaps='cd ~/.config/wehttamsnaps'

# ═══════════════════════════════════════════════════════════════════
# APPLICATIONS
# ═══════════════════════════════════════════════════════════════════

# Browsers (with Wayland support)
alias brave='brave --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias vivaldi='vivaldi-stable --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias firefox='firefox-developer-edition'

# File managers
alias fm='thunar'
alias nfm='nautilus'

# Editors (v and vim already set to nvim in .bashrc)
alias k='kate'

# ═══════════════════════════════════════════════════════════════════
# GAMING
# ═══════════════════════════════════════════════════════════════════

# Launch gaming mode
alias gamemode='sound-system gaming-toggle'
alias gaming='sound-system gaming-toggle'

# Gaming platforms (steam already has sound-system integration)
alias steam='sound-system steam-launch && steam'
alias lutris='lutris'
alias heroic='heroic'

# Mod managers (adjust paths to your Wine prefixes)
alias vortex='wine ~/.wine/drive_c/Program\ Files/Vortex/Vortex.exe'
alias mo2='wine ~/.wine/drive_c/Modding/MO2/ModOrganizer.exe'
alias stl='~/.local/share/Steam/steamapps/common/SteamTinkerLaunch/steamtinkerlaunch'

# ═══════════════════════════════════════════════════════════════════
# AUDIO & MEDIA
# ═══════════════════════════════════════════════════════════════════

# Audio routing
alias audioroute='~/.config/wehttamsnaps/scripts/audio-routing.sh gaming'
alias audiograph='qpwgraph'
alias audiomix='pavucontrol'

# Media players
alias music='spotify-launcher'
alias spot='spotify-launcher'
alias mpv='mpv --vo=gpu --hwdec=auto'

# ═══════════════════════════════════════════════════════════════════
# DEVELOPMENT (Git shortcuts already in .bashrc via gcom/lazyg)
# ═══════════════════════════════════════════════════════════════════

# Python
alias py='python3'
alias venv='python3 -m venv venv'
alias activate='source venv/bin/activate'

# Quick project shortcuts
alias cdniri='cd ~/.config/niri'
alias cdsnaps='cd ~/.config/wehttamsnaps'
alias cddots='cd ~/dotfiles' # adjust to your dotfiles location

# ═══════════════════════════════════════════════════════════════════
# NETWORKING (some already in .bashrc)
# ═══════════════════════════════════════════════════════════════════

alias myip='curl ifconfig.me'
alias localip='ip addr show | grep "inet " | grep -v 127.0.0.1'
alias speedtest='speedtest-cli'

# ═══════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════

# Reload shell config
alias reload='source ~/.bashrc'

# Weather
alias weather='curl wttr.in'

# Copy to clipboard (Wayland)
alias copy='wl-copy'
alias paste='wl-paste'

# Quick notes
alias note='kate ~/Documents/notes.txt'

# Clock
alias clock='tty-clock -c -C 6 -r'

# Screenshot shortcuts
alias ss='grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png && sound-system screenshot'
alias ssregion='grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png && sound-system screenshot'

# ═══════════════════════════════════════════════════════════════════
# CUSTOM FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

# Make directory and cd into it (mkdirg already exists in .bashrc)
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Quick backup (with timestamp)
backup() {
    cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
    echo "✓ Backed up: $1.backup-$(date +%Y%m%d-%H%M%S)"
}

# Find and replace in files
replace() {
    if [ $# -lt 2 ]; then
        echo "Usage: replace <search> <replace>"
        return 1
    fi
    find . -type f -exec sed -i "s/$1/$2/g" {} +
    echo "✓ Replaced '$1' with '$2'"
}

# Quick git commit and push
gcp() {
    git add .
    git commit -m "$1"
    git push
    echo "✓ Committed and pushed: $1"
}

# Update all the things
updateall() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 Updating System Packages..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    sudo pacman -Syu && yay -Syu

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Updating Flatpaks..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    flatpak update -y

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ All updates complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ═══════════════════════════════════════════════════════════════════
# CYBERPUNK GREETING (Optional - uncomment if desired)
# ═══════════════════════════════════════════════════════════════════

# echo -e "\033[1;36m╔══════════════════════════════════════════════════════════════╗\033[0m"
# echo -e "\033[1;36m║         \033[1;35mWehttamSnaps\033[1;36m - The future is now                   ║\033[0m"
# echo -e "\033[1;36m╚══════════════════════════════════════════════════════════════╝\033[0m"
# echo -e "\033[1;35mType 'welcome' for the quick start guide\033[0m"
# echo ""

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
