#!/bin/bash

CONFDIR="/home/$(whoami)/.config/mango"
echo "confdir is $CONFDIR"

app=micro

while $true; do
    selected=$(ls -1 $CONFDIR | fzf --layout=reverse --preview="bat $CONFDIR/{}")

    echo "selected is $selected"

    STRING=$(cat $CONFDIR/$selected | fzf --layout 'reverse' --preview-window 'down:50%,wrap-word' --preview-label='alt+b - open documentation in browser' --preview-label-pos='top'  --bind 'alt-b:execute(~/.config/snapsos/config-overview/browser.sh {})' --preview='~/.config/snapsos/config-overview/checker.sh {}')

done
