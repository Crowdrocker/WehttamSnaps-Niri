#!/bin/bash

while $true; do
    CMD=""
    SELECTED=$(ls ~/.config/snapsos/help/topics | fzf --layout=reverse --preview-window 'right:70%:wrap-word' --preview="clear && bat --style=plain -S -f -m '*:Markdown' ~/.config/snapsos/help/topics/{}")
done
