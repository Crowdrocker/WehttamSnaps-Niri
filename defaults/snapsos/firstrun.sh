#!/bin/bash

if [ ! -f ~/.config/firstrun.state ]; then

    sleep 5
    dms ipc call wallpaper set ~/.config/snapsos/wallpapers/default/wallpaper.png
    dms ipc call settings set showWorkspaceIndex true
    dms ipc call settings set dwlShowAllTags true
    dms ipc call settings set gtkThemingEnabled true
    dms ipc call settings set qtThemingEnabled true
    dms ipc call settings set runDmsMatugenTemplates true
    dms ipc call settings set matugenTemplateGtk true
    dms ipc call settings set matugenTemplatePywalfox true
    dms ipc call settings set matugenTemplateFirefox true
    dms ipc call settings set matugenTemplateQt6ct true
    dms ipc call settings set matugenTemplateGhostty true
    dms ipc call settings set showDock false
    dms ipc call settings set dockAutoHide false
    dms ipc call settings set currentTheme dynamic
    dms ipc call settings set currentThemeCategory dynamic
    dms ipc call settings set runUserMatugenTemplates true
    dms ipc call settings set matugenScheme scheme-tonal-spot
    dms ipc call settings set currentThemeName dynamic
    dms ipc call settings set currentThemeCategory dynamic
    
    dms ipc call settings open
    dms ipc call keybinds openWithPath mangowc ~/.config/mango/binds.conf
    touch ~/.config/firstrun.state
fi
exit 0
