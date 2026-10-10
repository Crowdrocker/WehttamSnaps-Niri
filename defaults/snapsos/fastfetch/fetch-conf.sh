#!/bin/bash

bash -c ~/.config/snapsos/fastfetch/update-files.sh

SRC_DIR="$HOME/.config/snapsos/fastfetch/gen"
CONF_DIR="$HOME/.config/snapsos/fastfetch/conf"

SELECTEDLOGO=$(ls -1 $SRC_DIR | fzf --layout=reverse --preview-window=right:70% --prompt='Select a logo: ' --preview-label='Preview:' --preview='bat ~/.config/snapsos/fastfetch/gen/{}')

SELECTEDCONF=$(ls -1 $CONF_DIR | fzf --layout=reverse --preview-window=down:70%,nowrap --color='pointer:green,marker:green' --prompt='Select a config style: ' --preview-label='Preview:' --preview='bash -c "fastfetch --disable-linewrap 1 -l none -c ~/.config/snapsos/fastfetch/conf/{}"')

echo "$SELECTEDLOGO:$SELECTEDCONF" > ~/.config/fetch.state
