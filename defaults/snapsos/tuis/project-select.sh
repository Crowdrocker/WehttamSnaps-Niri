#!/bin/bash

dirstate=$(cat ~/.config/projectdir.state)

DIR=/home/$(whoami)/$dirstate

# Find directories containing a '.git' folder and get their absolute paths
REPOS=$(find "$(realpath "$DIR")" -maxdepth 5 -name ".git" -type d -exec dirname {} \; | xargs -I {} readlink -f {})

SELECTED=$(echo "$REPOS" | fzf --layout=reverse --preview="clear && eza -al --color=always --group-directories-first --icons {} && echo "-----------------------------------------------------" && cat {}/README.md ")

echo $SELECTED

CMD="code-oss -n $SELECTED"

mmsg dispatch spawn_shell,"$CMD"