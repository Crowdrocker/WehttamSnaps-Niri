#!/bin/bash

if wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -qi "MUTED"; then
    printf "\uf026\n"
else
    printf "\uf028\n"
fi
