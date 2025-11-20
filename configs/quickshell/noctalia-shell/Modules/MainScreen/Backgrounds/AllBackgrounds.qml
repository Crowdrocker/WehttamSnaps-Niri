import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Widgets


/**
 * AllBackgrounds - Unified Shape container for all bar and panel backgrounds
 *
 * Unified shadow system. This component contains a single Shape
 * with multiple ShapePath children (one for bar, one for each panel type).
 *
 * Benefits:
 * - Single GPU-accelerated rendering pass for all backgrounds
 * - Unified shadow system (one MultiEffect for everything)
 */
Item {
  id: root

  // Reference Bar
  required property var bar

  // Reference to MainScreen (for panel access)
  required property var windowRoot

  anchors.fill: parent

  // Wrapper with layer caching for better shadow performance
  Item {
    anchors.fill: parent

    // Enable layer caching to prevent continuous re-rendering
    // This caches the Shape to a GPU texture, reducing GPU tessellation overhead
    layer.enabled: true

    // The unified Shape container
    Shape {
      id: backgroundsShape
      anchors.fill: parent

      // Use curve renderer for smooth corners (GPU-accelerated)
      preferredRendererType: Shape.CurveRenderer

      enabled: false // Disable mouse input on the Shape itself

      Component.onCompleted: {
        Logger.d("AllBackgrounds", "AllBackgrounds initialized")
        Logger.d("AllBackgrounds", "  bar:", root.bar)
        Logger.d("AllBackgrounds", "  windowRoot:", root.windowRoot)
      }


      /**
     *  Bar
     */
      BarBackground {
        bar: root.bar
        shapeContainer: backgroundsShape
        windowRoot: root.windowRoot
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.bar.backgroundOpacity)
      }


      /**
     *  Panels
     */

      // Audio
      PanelBackground {
        panel: root.windowRoot.audioPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // Battery
      PanelBackground {
        panel: root.windowRoot.batteryPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // Bluetooth
      PanelBackground {
        panel: root.windowRoot.bluetoothPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // Calendar
      PanelBackground {
        panel: root.windowRoot.calendarPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // Control Center
      PanelBackground {
        panel: root.windowRoot.controlCenterPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // Launcher
      PanelBackground {
        panel: root.windowRoot.launcherPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // Notification History
      PanelBackground {
        panel: root.windowRoot.notificationHistoryPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // Session Menu
      PanelBackground {
        panel: root.windowRoot.sessionMenuPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // Settings
      PanelBackground {
        panel: root.windowRoot.settingsPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // Setup Wizard
      PanelBackground {
        panel: root.windowRoot.setupWizardPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // TrayDrawer
      PanelBackground {
        panel: root.windowRoot.trayDrawerPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // Wallpaper
      PanelBackground {
        panel: root.windowRoot.wallpaperPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }

      // WiFi
      PanelBackground {
        panel: root.windowRoot.wifiPanelPlaceholder
        shapeContainer: backgroundsShape
        backgroundColor: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
      }
    }

    // Apply shadow to the cached layer
    NDropShadows {
      anchors.fill: parent
      source: backgroundsShape
    }
  }
}
