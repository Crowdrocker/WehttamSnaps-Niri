import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects as GE
import Quickshell

// Reusable glass/acrylic background component
// For correct blur positioning, parent must set screenX/screenY to component's screen position
Rectangle {
    id: root
    
    property color fallbackColor: Appearance.colors.colLayer1
    property color inirColor: Appearance.inir.colLayer1
    property real auroraTransparency: Appearance.aurora.popupTransparentize
    
    // Screen-relative position for blur alignment (set by parent)
    property real screenX: 0
    property real screenY: 0
    property real screenWidth: Quickshell.screens[0]?.width ?? 1920
    property real screenHeight: Quickshell.screens[0]?.height ?? 1080
    
    readonly property bool auroraEverywhere: Appearance.auroraEverywhere
    readonly property bool inirEverywhere: Appearance.inirEverywhere
    readonly property string wallpaperUrl: Wallpapers.effectiveWallpaperUrl
    
    color: auroraEverywhere ? "transparent"
        : inirEverywhere ? inirColor
        : fallbackColor
    
    clip: true
    
    layer.enabled: auroraEverywhere && !inirEverywhere
    layer.effect: GE.OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }
    
    Image {
        id: blurredWallpaper
        x: -root.screenX
        y: -root.screenY
        width: root.screenWidth
        height: root.screenHeight
        visible: root.auroraEverywhere && !root.inirEverywhere
        source: root.wallpaperUrl
        fillMode: Image.PreserveAspectCrop
        cache: true
        asynchronous: true

        layer.enabled: Appearance.effectsEnabled
        layer.effect: StyledBlurEffect {
            source: blurredWallpaper
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.auroraEverywhere && !root.inirEverywhere
        color: ColorUtils.transparentize(Appearance.colors.colLayer0Base, root.auroraTransparency)
    }
}
