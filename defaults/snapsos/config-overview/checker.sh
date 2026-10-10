#!/bin/bash

STRING="$1"

KEY=$(echo "$STRING" | cut -d '=' -f1 )

if [ "$KEY" == "bind" ]; then
    KEY=$(echo "$STRING" | cut -d ',' -f 1,2,3 | sed 's/bindl/bind/' | sed 's/binds/bind/' | sed 's/bindr/bind/' | sed 's/binds/bind/' | sed 's/bindp/bind/' | sed 's|=.*,.*,|=MOD,KEY,|g' | sed 's/ //g' )
fi

EXAMPLE=$(cat ~/.config/snapsos/config-overview/options.list | grep " $KEY " | head -1 | cut -d '|' -f2)
EXPLAINER=$(cat ~/.config/snapsos/config-overview/options.list | grep " $KEY " | head -1 | cut -d '|' -f3)
LINK=$(cat ~/.config/snapsos/config-overview/options.list | grep " $KEY "  | head -1 | cut -d '|' -f4)
EXTRA=$(cat ~/.config/snapsos/config-overview/options.list | grep " $KEY " | head -1 | cut -d '|' -f5 | sed 's/ //g')
echo "## Mango Config Key Explainer"
echo ""
if [ "$STRING" == "" ];then
    echo "nothing selected"
else
echo "key: $KEY"
echo ""
echo "example:$EXAMPLE"
echo "description:$EXPLAINER"
echo "link to documentation:$LINK"
echo ""
echo "Extra Information:"
case $EXTRA in
    bind)
        echo "for binds, you can add the following to modify the type of bind:"
        echo "bindl: allows use while on the lock screen"
        echo "binds: binds using keysym"
        echo "bindr: binds on key release"
        echo "bindp: this makes the bind transparent, meaning that it won't prevent your bind from also triggering a bind in your programs"
        ;;
    monitor)
        echo "for monitor rules, you have two types of parameters: selectors and modifiers"
        echo ""
        echo "selectors:"
        echo "name:<MONITORNAME> - selects all monitors of this name"
        echo "make:<MANUFACTURER> - selects all monitors of this manufacturer"
        echo "make:<MODEL> - selects all monitors of this model (as reported by EDID) "
        echo "serial:<SERIALNR> - selects the monitors matching this serial number (as reported by EDID)"
        echo ""
        echo "you can use multiple selectors, this will require monitors to match *all* selectors"
        echo ""
        echo "modifiers:"
        echo "width:<pixels> - sets the width in pixels for that monitor, ensure this resolution is supported"
        echo "height:<pixels> - sets the height in pixels for that monitor, ensure this resolution is supported"
        echo "refresh:<hz> - sets the refresh rate for the monitor, ensure it is supported for your set resolution"
        echo "x:<offset in px> - offsets the monitor compared to other monitors by this amount of pixels horizontally, useful for multi-monitor layouts"
        echo "y:<offset in px> - offsets the monitor compared to other monitors by this amount of pixels vertically, useful for multi-monitor layouts"
        echo "scale:<number> - sets the display scaling"
        echo "vrr:<1/0> - turns variable refresh rate on/off for this monitor"
        echo "rr:<0-7> - rotates and flips the display. 0 = upright, 1=90deg, 2=180deg, 3=270deg, 4=0deg,flip, 5=90deg, flip, 6=180deg, flip, 7=270, flip"
        echo "custom:<1/0> - enables custom mode for this display"
        echo ""
        echo "you can use multiple modifiers"
        echo ""
        echo "generally, the recommended setup is to filter down and configure each monitor separately with *one* rule per monitor"
        ;;
    dwindle)
        echo "dwindle is a \"binary tree\" based layout"
        echo "this means that when you spawn a new window, it will split the focused window in half in the longer direction"
        echo "so from 1 window to 2, it'll always result in 2 windows side-by-side"
        echo "then, if you split the left window again, it'll split vertically since it is taller than it is wide"

        ;;
    master)
        echo "both master and tiled layouts are \"primary/secondaries\" layouts"
        echo "one window (location depending on the layout) is the \"master window\""
        echo "the other windows will be tiled up outside of the master window area"
        echo "this means the mater window area size will not change"
        echo "you can exchange windows either by super+dragging any window to the master area"
        echo "or using keybinds to exchange windows, there is also a specific keybind dispatcher for setting the focused area as master"
        ;;
    scroller)
        echo "scroller layouts are an infinite strip of windows either vertically or horizontally"
        echo "you can scroll through these windows using SUPER+arrows or by moving the mouse"
        echo "within one \"section\", you can stack tiles in the other direction, horizontal scroll = vertical stacking"
        echo "scroller will allow non-focused windows to peek into your window, which allows you to easily navigate with the mouse"

        ;;
    tearing)
        echo "tearing needs to be set globally, and can then be enabled for specific apps using window rules"
        echo "window rule example: windowrule=force_tearing:1,title:vkcube"
        echo "this will completely turn off system VSYNC for the application"
        ;;
    env)
        echo "these set environment variables that are not just available to mango, but any application that runs under mango will also have these variables"
        echo "this recursively continues, so since mango spawns DankMaterial Shell, all applications spawned using DankMaterial Shell will *also* have these variables"
        ;;
    animations)
        echo "Animations in mangoWM provide smooth transitions for windows, layers, and layout changes."
        echo "They are particularly useful for improving visual feedback during window management."
        echo ""
        echo "To customize animations, you can adjust the following aspects:"
        echo "  - **Animation types**: Choose between sliding, zooming, fading, or disabling animations entirely."
        echo "  - **Durations**: Control how long animations take (e.g., faster for snappy feedback, slower for smoother transitions)."
        echo "  - **Bezier curves**: Define the 'feel' of animations (e.g., linear, bouncy, or easing effects)."
        echo ""
        echo "For a cohesive experience, ensure that animation durations and curves are balanced."
        echo "For example, a fast zoom animation with a bouncy curve might feel jarring, while a smooth fade with a linear curve feels natural."
        echo ""
        echo "If animations feel laggy, try reducing their duration or disabling them for specific actions (e.g., focus changes)."
        echo ""
        echo "You can test and refine animations in real-time by reloading mangoWM after making changes."
        ;;
    bezier)
        echo "Bezier curves define the acceleration and deceleration of animations, giving them a distinct 'feel.'"
        echo "They are represented by four values: x1, y1, x2, y2, which plot a curve on a graph from (0,0) to (1,1)."
        echo ""
        echo "Here’s how to interpret and create bezier curves:"
        echo "  - **x1, y1**: The first control point. A higher y1 value creates a sharp initial acceleration."
        echo "  - **x2, y2**: The second control point. A lower y2 value creates a sharp deceleration at the end."
        echo ""
        echo "Common curve types:"
        echo "  - **Linear (0.0,0.0,1.0,1.0)**: Constant speed, no easing."
        echo "  - **Ease-in (e.g., 0.42,0.0,1.0,1.0)**: Starts slow, accelerates quickly."
        echo "  - **Ease-out (e.g., 0.0,0.0,0.58,1.0)**: Starts fast, decelerates smoothly."
        echo "  - **Ease-in-out (e.g., 0.42,0.0,0.58,1.0)**: Smooth acceleration and deceleration."
        echo "  - **Bouncy (e.g., 0.28,0.84,0.42,1.0)**: Creates a spring-like effect."
        echo ""
        echo "To create custom curves, use tools like:"
        echo "  - cssportal.com/bezier-curve-generator"
        echo "  - easings.net"
        echo ""
        echo "Copy the generated values (e.g., 0.46,1.0,0.29,0.99) and apply them to your animation settings."
        echo "Experiment with different curves to achieve the desired 'feel' for your setup."
        ;;
    windowrules)
        echo "Window rules customize behavior for specific windows based on filters."
        echo ""
        echo "Filters:"
        echo "appid:<regex> - Match by application ID."
        echo "title:<regex> - Match by window title."
        echo ""
        echo "State & Behavior Modifiers:"
        echo "isfloating: 0/1 - Force floating state."
        echo "isfullscreen: 0/1 - Force fullscreen state."
        echo "isfakefullscreen: 0/1 - Force fake fullscreen (constrained)."
        echo "isglobal: 0/1 - Open as sticky across tags."
        echo "isoverlay: 0/1 - Always on top layer."
        echo "isopensilent: 0/1 - Open without focus."
        echo "istagsilent: 0/1 - Don't focus if not on current tag."
        echo "force_fakemaximize: 0/1 - Force fake maximize."
        echo "ignore_maximize: 0/1 - Ignore maximize requests."
        echo "ignore_minimize: 0/1 - Ignore minimize requests."
        echo "force_tiled_state: 0/1 - Force tiled state."
        echo "noopenmaximized: 0/1 - Prevent opening maximized."
        echo "single_scratchpad: 0/1 - Show one scratchpad at a time."
        echo "allow_shortcuts_inhibit: 0/1 - Allow shortcut inhibition."
        echo "idleinhibit_when_focus: 0/1 - Inhibit idle when focused."
        echo ""
        echo "Geometry & Position Modifiers:"
        echo "width: 0-9999 - Window width (pixels or % if <1)."
        echo "height: 0-9999 - Window height (pixels or % if <1)."
        echo "offsetx: -999-999 - X offset from center (% of screen)."
        echo "offsety: -999-999 - Y offset from center (% of screen)."
        echo "monitor: <name> - Assign to specific monitor."
        echo "tags: 1-9 - Assign to specific tag."
        echo "no_force_center: 0/1 - Disable forced centering."
        echo "isnosizehint: 0/1 - Ignore size hints."
        echo ""
        echo "Visuals & Decoration Modifiers:"
        echo "noblur: 0/1 - Disable blur effect."
        echo "isnoborder: 0/1 - Remove window border."
        echo "isnoshadow: 0/1 - Disable shadow."
        echo "isnoradius: 0/1 - Disable corner radius."
        echo "isnoanimation: 0/1 - Disable animations."
        echo "focused_opacity: 0-1 - Focused window opacity."
        echo "unfocused_opacity: 0-1 - Unfocused window opacity."
        echo "allow_csd: 0/1 - Allow client-side decorations."
        echo ""
        echo "Layout & Scroller Modifiers:"
        echo "scroller_proportion: 0.1-1.0 - Scroller proportion."
        echo "scroller_proportion_single: 0.1-1.0 - Single-window scroller proportion."
        echo ""
        echo "Animation Modifiers:"
        echo "animation_type_open: zoom/slide/fade/none - Open animation."
        echo "animation_type_close: zoom/slide/fade/none - Close animation."
        echo "nofadein: 0/1 - Disable fade-in."
        echo "nofadeout: 0/1 - Disable fade-out."
        echo ""
        echo "Terminal & Swallowing Modifiers:"
        echo "isterm: 0/1 - Replace terminal window."
        echo "noswallow: 0/1 - Prevent window swallowing."
        echo ""
        echo "Global & Special Windows Modifiers:"
        echo "globalkeybinding: <mod+key> - Global keybinding."
        echo "isunglobal: 0/1 - Open as unmanaged global window."
        echo "isnamedscratchpad: 0/1 - Named scratchpad."
        echo ""
        echo "Performance & Tearing Modifiers:"
        echo "force_tearing: 0/1 - Enable tearing."
        ;;
    tagrules)
        echo "Tag rules customize behavior for specific tags."
        echo ""
        echo "Filters:"
        echo "id: 0-9 - Match by tag ID (0 for ~0 tag)."
        echo "monitor_name: <name> - Match by monitor name."
        echo "monitor_make: <make> - Match by monitor manufacturer."
        echo "monitor_model: <model> - Match by monitor model."
        echo "monitor_serial: <serial> - Match by monitor serial."
        echo ""
        echo "Modifiers:"
        echo "layout_name: <name> - Set layout (e.g., 'scroller')."
        echo "no_render_border: 0/1 - Disable border rendering."
        echo "open_as_floating: 0/1 - Open windows as floating."
        echo "no_hide: 0/1 - Keep tag visible even if empty."
        echo "nmaster: 0-99 - Number of master windows."
        echo "mfact: 0.1-0.9 - Master area factor."
        ;;
    layerrules)
        echo "Layer rules customize behavior for layer shell surfaces."
        echo ""
        echo "Filters:"
        echo "layer_name: <name> - Match by layer name (supports regex)."
        echo ""
        echo "Modifiers:"
        echo "animation_type_open: slide/zoom/fade/none - Open animation."
        echo "animation_type_close: slide/zoom/fade/none - Close animation."
        echo "noblur: 0/1 - Disable blur."
        echo "noanim: 0/1 - Disable animations."
        echo "noshadow: 0/1 - Disable shadow."
        ;;
    scratchpad)
        echo "the scratchpad is a hidden storage space you can minimize applications to"
        echo "these scratchpads are monitor-bound, but work across tags, windows inside the scratchpad are effectively untagged."
        echo "there are seperate binds for moving the current focused window to the scratchpad, toggling the scratchpad and moving windows back out"
        echo "the scratchpad will only show one window at a time, you can toggle through them using the same bind"
        echo "you can also make and bind named scratchpads that use a specific program. these can only contain that program with that title."
        echo "a named scratchpad also spawns the window if no window exists. though you'll have to use the bind a second time to put that window in the scratchpad"
        ;;
    overview)
        echo "Overview mode displays all windows on the current monitor in a grid layout."
        echo ""
        echo "You can interact with windows using the mouse:"
        echo "Left-click to focus a window."
        echo "Right-click to close a window."
        echo ""
        echo "Overview can be triggered by moving the mouse to a hot corner."
        echo "The hot corner is configurable and can be disabled if needed."
        echo ""
        echo "Overview temporarily shows all windows from all tags on the current monitor."
        echo "This allows you to quickly switch to any window, regardless of its tag."
        ;;
    autostart)
        echo "exec-once and exec are used to launch programs automatically when mangoWM starts."
        echo ""
        echo "Applications run in the order they appear in the config."
        echo ""
        echo "For delayed starts, use a script with 'sleep' or put 'sleep 15 &&' in front of the command in your exec-once= or exec= setting."
        echo ""
        echo "Common uses are things like status bars, daemons, or applications you want to start in the background like steam or discord"
        ;;
    *)
        echo "no extra info for this item."
        ;;
esac
fi
