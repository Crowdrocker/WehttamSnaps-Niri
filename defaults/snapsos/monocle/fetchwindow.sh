#!/bin/bash


INDEX="$1"
MONITOR=$2

while [ -e ~/.config/monocle-$MONITOR.lock ]; do
    sleep 0.01
done

WINDOWTITLE=$(cat ~/.config/monocle-$MONITOR.state | grep -e "index:$INDEX" | cut -d'\' -f2)




echo "$WINDOWTITLE"
