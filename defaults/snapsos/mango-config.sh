#!/bin/bash

CONFDIR="/home/$(whoami)/.config/mango"
echo "confdir is $CONFDIR"

app=micro

selected=$(ls -1 $CONFDIR | fzf --layout=reverse --preview="bat $CONFDIR/{}")

echo "selected is $selected"

$app $CONFDIR/$selected

echo "opened $CONFDIR/$selected in $app"

