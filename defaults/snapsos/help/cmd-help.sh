#!/bin/bash


while $true; do
    CMD=$(cat ~/.config/snapsos/help/cmds.list | fzf --layout=reverse --preview-window=right:70% --preview='tldr --color always $(echo {} | sed "s/ls (eza)/eza/" | sed "s/cd (zoxide)/z/")')
    man $(echo "$CMD" | sed 's/ls (eza)/eza/' | sed 's/cd (zoxide)/z/' )
done
