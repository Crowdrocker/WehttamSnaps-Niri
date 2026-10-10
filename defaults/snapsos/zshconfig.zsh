
## command aliases
alias find="fzf --layout=reverse --preview='bat {}'"
alias microfind='micro $(pwd)/$(fzf --layout=reverse --preview="bat {}")'
alias ls='eza -al --color=always --group-directories-first --icons' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons'  # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons'  # long format
alias lt='eza -aT --level=4 --color=always --group-directories-first --icons' # tree listing
alias l.="eza -a | grep -e '^\.'"                                     # show only dotfiles
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias update='sudo pacman -Syu'
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'
alias apt='man pacman'
alias apt-get='man pacman'
alias jctl="journalctl -p 3 -xb"
alias cmdhist='CMD=$(history -i | tac | fzf | sed "s/.*:..  //"); sleep 0.1 && wtype $CMD'
alias tipme='~/.config/snapsos/tips/tips.sh'
alias alltips='cat ~/.config/snapsos/tips/tips.list | fzf'
alias cowtip='cowsay -r $(shuf -n 1 ~/.config/snapsos/tips/tips.list) | lolcat'
alias fetch='~/.config/snapsos/fastfetch/fetch.sh'
alias fetchconf='~/.config/snapsos/fastfetch/fetch-conf.sh'
alias yurifetch='fastfetch -l ~/Documents/yuri.png'

## tools
alias pacgui=~/.config/snapsos/tuis/pkg-install.sh
alias aurgui=~/.config/snapsos/tuis/aur-install.sh
alias git-projects=~/.config/snapsos/tuis/project.select.sh
alias mangoconf=~/.config/snapsos/mango-config.sh
alias documentation=~/.config/snapsos/tuis/documentation.sh
alias tldrtui=~/.config/snapsos/help/cmd-help.sh
alias helptui=~/.config/snapsos/help/help.sh

export EDITOR=micro
export IMAGEPROGRAM='satty --filename'
export SHELL=/bin/zsh


# sets your terminal icon (leftmost section of prompt if your distro is not detected.)
# distro options with previews (must use nerdfont in editor to preview):
# Arch:         '\uF303'               # 
# centos:       '\uF304'$s             # 
# CoreOS:       '\uF305'$s             # 
# debian:       '\uF306'               # 
# raspbian:     '\uF315'               # 
# elementaryOS: '\uF309'$s             # 
# fedora:       '\uF30a'$s             # 
# gentoo:       '\uF30d'$s             # 
# mageia:       '\uF310'               # 
# mint:         '\uF30e'$s             # 
# nixos:        '\uF313'$s             # 
# manjaro:      '\uF312'$s             # 
# devuan:       '\uF307'$s             # 
# alpine:       '\uF300'$s             # 
# AOSC:         '\uF301'$s             # 
# openSUSE      '\uF314'$s             # 
# sabayon       '\uF317'$s             # 
# slackware     '\uF319'$s             # 
# void          '\UF32E'$s             # 
# artix         '\UF31F'$s             # 
# ubuntu        '\uF31b'$s             # 
# kali          '\uF327'$s             # 
# RHEL          '\UF111B'$s            # 󱄛
# amazon        '\uF270'$s             # 
# endeavourOS   '\UF322'$s             # 
# rocky linux   '\UF32B'$s             # 
# alma linux    '\UF31D'$s             # 
# guix          '\UF325'$s             # 
# neon          '\uF17C'               # 
# general tux   '\uF17C'               # 

## you can also use any other symbol from nerdfonts. 
## https://www.nerdfonts.com/cheat-sheet
## example: the xbox logo is ed3e on the site, so to get it, fill in $`\uED3E`

export POWERLEVEL9K_LINUX_ICON=$'\uF303'

## if your OS is detected and you want to change it, uncomment the following line and set it:
# export POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION=$'\uF303'

function plz() {
    if [ -z "$1" ]; then
        sudo $(fc -ln 1 | tail -1)
    else
        sudo "$@"
    fi
}
## filetype aliases, default-opens them with the set program
alias -s json=$EDITOR
alias -s yaml=$EDITOR
alias -s md=$EDITOR
alias -s toml=$EDITOR
alias -s conf=$EDITOR
alias -s yml=$EDITOR
alias -s txt=$EDITOR
alias -s css=$EDITOR
alias -s html=$EDITOR
alias -s png=$IMAGEPROGRAM
alias -s jpg=$IMAGEPROGRAM
alias -s jpeg=$IMAGEPROGRAM
alias -s webp=$IMAGEPROGRAM
alias -s nix=$EDITOR

eval "$(zoxide init zsh --cmd cd )"
source <(fzf --zsh)
