#!/bin/bash

while true; do
    ls ~/.config/snapsos/help/topics 2>/dev/null || ls /usr/share/snapsos/help/topics 2>/dev/null || ls updated-help-topics 2>/dev/null
    SELECTED=$(ls ~/.config/snapsos/help/topics 2>/dev/null | fzf --layout=reverse --preview-window 'right:70%:wrap-word' --preview="clear && bat --style=plain -S -f -m '*:Markdown' ~/.config/snapsos/help/topics/{}" --bind 'enter:execute(bat --style=plain -S -f -m "*:Markdown" ~/.config/snapsos/help/topics/{})')
done
