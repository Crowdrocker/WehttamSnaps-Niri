#!/bin/env bash
# dunst notification daemon notification module

msgCount=$(dunstctl count waiting)
enabled=
disabled=󰂛

if dunstctl is-paused | grep -q "false"
then 
    echo "{\"text\": \"$enabled\", \"alt\": \"\", \"tooltip\": \"\", \"class\": \"unpaused\"}"
else 
  echo "{\"text\": \"$disabled\", \"alt\": \"\", \"tooltip\": \"$msgCount\", \"class\": \"paused\"}"
fi  
