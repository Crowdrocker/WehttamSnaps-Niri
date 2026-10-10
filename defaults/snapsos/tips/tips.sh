#!/bin/bash

if [ ! -e ~/.config/tips.state ]; then
    echo "standard" > ~/.config/tips.state
fi

SETTING=$(cat ~/.config/tips.state)

INPUT="$1"

case $INPUT in
    "")
        case $SETTING in 
            standard)
                echo "$(shuf -n 1 ~/.config/snapsos/tips/tips.list)"
                ;;
            cow)
                cowsay -r "$(shuf -n 1 ~/.config/snapsos/tips/tips.list)" | lolcat
                ;;
        esac
        ;;
    toggle)
        case $SETTING in
            standard)
                echo "cow" > ~/.config/tips.state
                ;;
            cow)
                echo "standard" > ~/.config/tips.state
                ;;
        esac
        ;;
    standard)
        echo "standard" > ~/.config/tips.state
        shuf -n 1 ~/.config/snapsos/tips/tips.list
        ;;

    cow)
        echo "cow" > ~/.config/tips.state
        cowsay -r $(shuf -n 1 ~/.config/snapsos/tips/tips.list) | lolcat
        ;;
esac
