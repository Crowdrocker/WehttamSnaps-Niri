pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.models
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: backdropWindow
        required property var modelData

        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell:iiBackdrop"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        color: "transparent"

        // Material ii backdrop config (independent)
        readonly property var iiBackdrop: Config.options?.background?.backdrop ?? {}
        
        readonly property int backdropBlurRadius: iiBackdrop.blurRadius ?? 32
        readonly property int backdropDim: iiBackdrop.dim ?? 35
        readonly property real backdropSaturation: iiBackdrop.saturation ?? 0
        readonly property real backdropContrast: iiBackdrop.contrast ?? 0
        readonly property bool vignetteEnabled: iiBackdrop.vignetteEnabled ?? false
        readonly property real vignetteIntensity: iiBackdrop.vignetteIntensity ?? 0.5
        readonly property real vignetteRadius: iiBackdrop.vignetteRadius ?? 0.7
        readonly property bool useAuroraStyle: iiBackdrop.useAuroraStyle ?? false
        readonly property real auroraOverlayOpacity: iiBackdrop.auroraOverlayOpacity ?? 0.38

        readonly property string effectiveWallpaperPath: {
            const useMain = iiBackdrop.useMainWallpaper ?? true;
            const mainPath = Config.options?.background?.wallpaperPath ?? "";
            const backdropPath = iiBackdrop.wallpaperPath || "";
            return useMain ? mainPath : (backdropPath || mainPath);
        }

        // Color quantizer for aurora-style adaptive colors
        ColorQuantizer {
            id: backdropColorQuantizer
            source: backdropWindow.effectiveWallpaperPath 
                ? (backdropWindow.effectiveWallpaperPath.startsWith("file://") 
                    ? backdropWindow.effectiveWallpaperPath 
                    : "file://" + backdropWindow.effectiveWallpaperPath)
                : ""
            depth: 0
            rescaleSize: 10
        }

        readonly property color wallpaperDominantColor: (backdropColorQuantizer?.colors?.[0] ?? Appearance.colors.colPrimary)
        readonly property QtObject blendedColors: AdaptedMaterialScheme {
            color: ColorUtils.mix(backdropWindow.wallpaperDominantColor, Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
        }

        Item {
            anchors.fill: parent

            Image {
                id: wallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: backdropWindow.effectiveWallpaperPath 
                    ? (backdropWindow.effectiveWallpaperPath.startsWith("file://") 
                        ? backdropWindow.effectiveWallpaperPath 
                        : "file://" + backdropWindow.effectiveWallpaperPath)
                    : ""
                asynchronous: true
                cache: true
                visible: !backdropWindow.useAuroraStyle

                layer.enabled: Appearance.effectsEnabled && backdropWindow.backdropBlurRadius > 0 && !backdropWindow.useAuroraStyle
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: backdropWindow.backdropBlurRadius / 100.0
                    blurMax: 64
                    saturation: backdropWindow.backdropSaturation
                    contrast: backdropWindow.backdropContrast
                }
            }

            // Aurora-style blur (same as sidebars)
            Image {
                id: auroraWallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: wallpaper.source
                asynchronous: true
                cache: true
                visible: backdropWindow.useAuroraStyle && status === Image.Ready

                layer.enabled: Appearance.effectsEnabled
                layer.effect: StyledBlurEffect {
                    source: auroraWallpaper
                }
            }

            // Aurora-style color overlay
            Rectangle {
                anchors.fill: parent
                visible: backdropWindow.useAuroraStyle
                color: ColorUtils.transparentize(
                    (backdropWindow.blendedColors?.colLayer0 ?? Appearance.colors.colLayer0Base), 
                    backdropWindow.auroraOverlayOpacity
                )
            }

            // Legacy dim overlay (non-aurora)
            Rectangle {
                anchors.fill: parent
                visible: !backdropWindow.useAuroraStyle
                color: "black"
                opacity: backdropWindow.backdropDim / 100.0
            }

            // Vignette effect at bar level
            Rectangle {
                id: barVignette
                anchors {
                    left: parent.left
                    right: parent.right
                    top: isBarAtTop ? parent.top : undefined
                    bottom: isBarAtTop ? undefined : parent.bottom
                }
                
                readonly property bool isBarAtTop: !(Config.options?.bar?.bottom ?? false)
                readonly property bool barVignetteEnabled: Config.options?.bar?.vignette?.enabled ?? false
                readonly property real barVignetteIntensity: Config.options?.bar?.vignette?.intensity ?? 0.6
                readonly property real barVignetteRadius: Config.options?.bar?.vignette?.radius ?? 0.5
                
                height: Math.max(200, backdropWindow.modelData.height * barVignetteRadius)
                visible: barVignetteEnabled
                
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    
                    GradientStop { 
                        position: 0.0
                        color: barVignette.isBarAtTop 
                            ? Qt.rgba(0, 0, 0, barVignette.barVignetteIntensity)
                            : "transparent"
                    }
                    GradientStop { 
                        position: barVignette.barVignetteRadius
                        color: "transparent"
                    }
                    GradientStop { 
                        position: 1.0
                        color: barVignette.isBarAtTop
                            ? "transparent"
                            : Qt.rgba(0, 0, 0, barVignette.barVignetteIntensity)
                    }
                }
            }
            
            // Legacy vignette effect (bottom gradient)
            Rectangle {
                anchors.fill: parent
                visible: backdropWindow.vignetteEnabled
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: backdropWindow.vignetteRadius; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, backdropWindow.vignetteIntensity) }
                }
            }
        }
    }
}
