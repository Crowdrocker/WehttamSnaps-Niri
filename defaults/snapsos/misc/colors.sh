#!/bin/bash

file="$HOME/.local/state/quickshell/user/generated/colors.json"

jq -r 'to_entries[] | "\(.key) \(.value)"' "$file" |
while read -r name hex; do
    hex="${hex#\#}"

    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))

    printf "%-30s " "$name"
    printf "\e[48;2;%d;%d;%dm        \e[0m " "$r" "$g" "$b"
    printf "%s\n" "#$hex"
done
read -n 1