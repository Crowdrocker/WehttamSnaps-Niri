#!/bin/bash

DISTRO="$1"



SRC_DIR="$HOME/.config/snapsos/fastfetch/gen"
CONF_DIR="$HOME/.config/snapsos/fastfetch/conf"

LOGO=$(cat ~/.config/fetch.state | cut -d: -f1)
CONF=$(cat ~/.config/fetch.state | cut -d: -f2)

#echo "logo is $SRC_DIR/$LOGO, conf is $CONF_DIR/$CONF"

if [ "$DISTRO" != "" ]; then
    case $LOGO in
        distro-themed)
        fastfetch -l $DISTRO -c $CONF_DIR/$CONF --logo-color-1 magenta --logo-color-2 bright_cyan --logo-color-3 blue --logo-color-4 bright_cyan --logo-color-5 bright_cyan --logo-color-6 bright_blue --logo-color-7 bright_magenta
        exit 0
        ;;
        *)
        fastfetch -l $DISTRO -c $CONF_DIR/$CONF
        exit 0
        ;;
    esac
fi

if [ "$LOGO" == "none" ]; then
    fastfetch -l none -c $CONF_DIR/$CONF
elif [ "$LOGO" == "distro" ]; then
    fastfetch -c $CONF_DIR/$CONF
elif [ "$LOGO" == "distro-themed" ]; then
    fastfetch -c $CONF_DIR/$CONF --logo-color-1 magenta --logo-color-2 bright_cyan --logo-color-3 blue --logo-color-4 bright_cyan --logo-color-5 bright_cyan --logo-color-6 bright_blue --logo-color-7 bright_magenta
else
    fastfetch  -l $SRC_DIR/$LOGO -c $CONF_DIR/$CONF
fi
