#!/bin/bash

ACTIVEMON=$(mmsg get all-monitors | jq '.monitors[] | select(.active == true) | .name' -r)
ACTIVETAG=$(mmsg get tags DP-1 | jq '.tags[] | select(.is_active == true) | .index' -r)
ACTIVEWINDOWS=$(mmsg get all-clients | jq -r --arg ACTIVETAG "$ACTIVETAG" --arg ACTIVEMON "$ACTIVEMON" '.clients[] | select(.tags[] == ($ACTIVETAG | tonumber) and .monitor == $ACTIVEMON) | .id')


TARGETMON=$(cat ~/.config/marker.workspace | cut -d: -f1)
TARGETTAG=$(cat ~/.config/marker.workspace | cut -d: -f2)
TARGETWINDOWS=$(cat ~/.config/marker.state)


echo "swapping between: $ACTIVEMON:$ACTIVETAG and $TARGETMON:$TARGETTAG"
echo "swapping the following windows on $ACTIVEMON:"
echo "$ACTIVEWINDOWS"
echo ""
echo "with the following windows on $TARGETMON"
echo "$TARGETWINDOWS"

ACTIVECOMB=""
TARGETCOMB=""

while read LINE; do
    ACTIVECOMB=$(echo "$ACTIVECOMB
    $ACTIVEMON:$ACTIVETAG:$LINE")

done <<< "$ACTIVEWINDOWS"

while read LINE; do
    TARGETCOMB=$(echo "$TARGETCOMB
    $TARGETMON:$TARGETTAG:$LINE")

done <<< "$TARGETWINDOWS"

TARGETCOMB=$(echo "$TARGETCOMB" | sed 1d)
ACTIVECOMB=$(echo "$ACTIVECOMB" | sed 1d)

echo "combined active is:"
echo "$ACTIVECOMB"
echo ""
echo "combined target is:"
echo "$TARGETCOMB"

LIST=$(paste <(echo "$ACTIVECOMB") <(echo "$TARGETCOMB") | awk -F'\t' 'NF == 2 {print $1; print $2}')


while read LINE; do
    if [ "$LINE" == "" ]; then
        currentactive=$(mmsg get all-monitors | jq '.monitors[] | select(.active == true) | .name' -r)
        if [ "$currentactive" == "$ACTIVEMON" ]; then
            mmsg dispatch viewcrossmon,$TARGETTAG,name:$TARGETMON
        else
            mmsg dispatch viewcrossmon,$ACTIVETAG,name:$ACTIVEMON
        fi 
    else
        lmon=$(echo "$LINE" | cut -d: -f1)
        ltag=$(echo "$LINE" | cut -d: -f2)
        lclient=$(echo "$LINE" | cut -d: -f3)
        if [ "$lmon" == $ACTIVEMON ]; then
            mmsg dispatch viewcrossmon,$ltag,name:$lmon
            sleep 0.01
            mmsg dispatch tagcrossmon,$TARGETTAG,name:$TARGETMON client,$lclient
            echo "moved $lclient to $TARGETMON:$TARGETTAG"
        else
            mmsg dispatch viewcrossmon,$ltag,name:$lmon
            sleep 0.01
            mmsg dispatch tagcrossmon,$ACTIVETAG,name:$ACTIVEMON client,$lclient
            echo "moved $lclient to $TARGETMON:$TARGETTAG"
        fi
    fi

done <<< "$LIST"
