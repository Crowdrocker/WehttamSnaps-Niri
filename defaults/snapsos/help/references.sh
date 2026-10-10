#!/bin/bash
while $true; do
    cat ~/.config/snapsos/help/$1.list | fzf -e --layout=reverse
done
