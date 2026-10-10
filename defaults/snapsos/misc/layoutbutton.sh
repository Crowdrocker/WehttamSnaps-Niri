#!/bin/bash


ACTIVEMON=$(mmsg get all-monitors | jq '.monitors[] | select(.active == true) | .name' -r)

echo $ACTIVEMON

LAYOUT=$(mmsg get monitor $ACTIVEMON | jq '.tags[] | select(.is_active == true) | .layout' -r)

echo "$LAYOUT"

case $LAYOUT in
    T)
        echo "Left Master"
        mmsg dispatch zoom
        ;;
    S)
        echo "Horizontal Scroller"
        mmsg dispatch switch_proportion_preset
        ;;
    G)
        echo "Horizontal Grid"
        mmsg dispatch toggle_render_border
        mmsg dispatch togglegaps
        ;;
    M)
        echo "Monocle"
        ;;
    K)
        echo "Horizontal Deck"
        mmsg dispatch zoom
        ;;
    CT)
        echo "Center Master"
        mmsg dispatch zoom
        ;;
    RT)
        echo "Right Master"
        mmsg dispatch zoom
        ;;
    VS)
        echo "Vertical Scroller"
        mmsg dispatch switch_proportion_preset
        ;;
    VT)
        echo "Top Master"
        mmsg dispatch zoom
        ;;
    VG)
        echo "Vertical Grid"
        mmsg dispatch toggle_render_border
        mmsg dispatch togglegaps
        
        ;;
    VK)
        echo "Vertical Deck"
        mmsg dispatch zoom
        ;;
    DW)
        echo "Dwindle"
        mmsg dispatch togglemaximizescreen
        ;;
    F)
        echo "Fair"
        mmsg dispatch toggle_render_border
        mmsg dispatch togglegaps
        ;;
    VF)
        echo "Vertical Fair"
        mmsg dispatch toggle_render_border
        mmsg dispatch togglegaps
        ;;
    *)
        notify-send "Unhandled Layout Detected"
        ;;
esac
