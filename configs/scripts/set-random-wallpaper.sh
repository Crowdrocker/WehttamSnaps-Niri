#!/bin/env bash
# set wallpaper to a random image in a specified directory using swaybg

imageDir=$HOME/Pictures/wallpapers/active

imageName=$(find $imageDir -type f | sort -R | head -1)
killall -9 swaybg 2>/dev/null
swaybg --mode fill --image $imageName &
