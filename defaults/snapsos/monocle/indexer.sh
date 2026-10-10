#!/bin/bash

MONITOR=$1

# get all clients on that monitor: mmsg get all-clients | jq '.clients[] | select( .monitor == "HDMI-A-1") | .id' -r

MONOCLEMON=$(mmsg get all-monitors | jq -r '.monitors[] | select(.tags[] | select(.is_active == true) | .layout | test("M|K|VK")) | .name')

ACTIVEMON=$(mmsg get all-monitors | jq '.monitors[] | select(.active == true) | .name' -r)
#echo "activemon is $ACTIVEMON"
ACTIVETAG=$(mmsg get tags $MONITOR | jq '.tags[] | select(.is_active == true) | .index' -r)
#echo "activetag is $ACTIVETAG"
ACTIVEWINDOWS=$(mmsg get all-clients | jq -r --arg ACTIVETAG "$ACTIVETAG" --arg ACTIVEMON "$MONITOR" '.clients[] | select(.tags[] == ($ACTIVETAG | tonumber) and .monitor == $ACTIVEMON) | .id' | sort)
#echo "active windows are:"
#echo "----------------------------------------"
#echo "$ACTIVEWINDOWS"
#echo "----------------------------------------"
echo "lock" > ~/.config/monocle-$MONITOR.lock
sleep 0.05
INDEX=0
echo "" > ~/.config/monocle-$MONITOR.state


while read LINE; do
    ID=$LINE
    TITLE=$(mmsg get all-clients | jq -r --arg ID "$LINE" '.clients[] | select(.id == ($ID | tonumber)) | .title' ) 
    INDEX=$((INDEX+1))
    echo "index:$INDEX \ $TITLE \ $ID" >> ~/.config/monocle-$MONITOR.state

done <<< "$ACTIVEWINDOWS"

sleep 0.05
rm ~/.config/monocle-$MONITOR.lock

echo "(running)"