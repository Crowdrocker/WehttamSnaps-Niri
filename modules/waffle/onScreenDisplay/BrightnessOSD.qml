import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.modules.waffle.looks

OSDValue {
    id: root
    property var focusedScreen: CompositorService.isNiri 
        ? (Quickshell.screens.find(s => s.name === NiriService.currentOutput) ?? Quickshell.screens[0])
        : (Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0])
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)
    iconName: "weather-sunny"
    value: brightnessMonitor?.brightness ?? 0
    showNumber: true

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            root.timer.restart();
        }
    }
}
