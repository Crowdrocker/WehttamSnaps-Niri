#!/bin/env bash
# only show when there are enough updates

limit=29
pending=$(checkupdates-with-aur | wc -l)

if [[ $pending -gt $limit ]]; then
   echo "{\"text\": \"󰚰 $pending\", \"alt\": \"\", \"tooltip\": \"\", \"class\": \"waiting\"}"
else
   echo "{\"text\": \"\", \"alt\": \"\", \"tooltip\": \"\", \"class\": \"\"}"
fi
