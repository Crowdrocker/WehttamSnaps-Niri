import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.Commons
import qs.Services.UI
import qs.Widgets
import qs.Modules.MainScreen

// A compact grid panel listing all tray items, opened from the Tray widget
SmartPanel {
  id: root

  // Do not give exclusive focus to the TrayDrawer or it will prevent the dropdown menu to request it.
  exclusiveKeyboard: false

  // Widget info for menu functionality
  property string widgetSection: ""
  property int widgetIndex: -1

  // Trigger refresh when settings change
  property int settingsVersion: 0

  // Read widget settings for reactivity
  readonly property var widgetSettings: {
    // Reference settingsVersion to force recalculation when it changes
    var _ = root.settingsVersion
    if (widgetSection === "" || widgetIndex < 0)
      return {}
    var widgets = Settings.data.bar.widgets[widgetSection]
    if (!widgets || widgetIndex >= widgets.length)
      return {}
    var settings = widgets[widgetIndex]
    if (!settings || settings.id !== "Tray")
      return {}
    return settings
  }

  // Read pinned list directly from settings for reactivity
  readonly property var pinnedList: widgetSettings.pinned || []

  function wildCardMatch(str, rule) {
    if (!str || !rule)
      return false
    let escaped = rule.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    let pattern = '^' + escaped.replace(/\\\*/g, '.*') + '$'
    try {
      return new RegExp(pattern, 'i').test(str)
    } catch (e) {
      return false
    }
  }

  function isPinned(item) {
    if (!pinnedList || pinnedList.length === 0)
      return false
    const title = item?.tooltipTitle || item?.name || item?.id || ""
    for (var i = 0; i < pinnedList.length; i++) {
      if (wildCardMatch(title, pinnedList[i]))
        return true
    }
    return false
  }

  // Dynamic sizing based on item count
  // Show items that are NOT pinned (unpinned items go to drawer)
  readonly property var trayValuesAll: (SystemTray.items && SystemTray.items.values) ? SystemTray.items.values : []
  readonly property var trayValues: trayValuesAll.filter(function (it) {
    return !root.isPinned(it)
  })
  readonly property int itemCount: trayValues.length
  readonly property int maxColumns: 8
  readonly property real cellSize: Math.round(Style.capsuleHeight * 0.65)
  readonly property real outerPadding: Style.marginM
  readonly property real innerSpacing: Style.marginM
  readonly property int columns: Math.max(1, Math.min(maxColumns, itemCount))
  readonly property int rows: Math.max(1, Math.ceil(itemCount / Math.max(1, columns)))

  // Static fallback sizes
  preferredWidth: (columns * cellSize) + ((columns - 1) * innerSpacing) + (2 * outerPadding)
  preferredHeight: (rows * cellSize) + ((rows - 1) * innerSpacing) + (2 * outerPadding)

  // Positioning is handled automatically by SmartPanel when toggle(buttonItem) is called

  // Watch for settings changes to refresh the dropdown
  Connections {
    target: Settings
    function onSettingsSaved() {
      // Force refresh by incrementing settingsVersion, which triggers recalculation of pinnedList
      root.settingsVersion++
    }
  }

  // Auto-close drawer when all items are pinned (drawer becomes empty)
  onTrayValuesChanged: {
    if (visible && trayValues.length === 0) {
      close()
    }
  }

  // Trigger re-evaluation when window is registered
  property int trayMenuUpdateTrigger: 0

  // Get the trayMenu window and loader from PanelService (reactive to trigger changes)
  readonly property var trayMenuWindow: {
    // Reference trigger to force re-evaluation
    var _ = trayMenuUpdateTrigger
    return PanelService.getTrayMenuWindow(screen)
  }

  readonly property var trayMenu: trayMenuWindow ? trayMenuWindow.trayMenuLoader : null

  Connections {
    target: PanelService
    function onTrayMenuWindowRegistered(registeredScreen) {
      if (registeredScreen === screen) {
        root.trayMenuUpdateTrigger++
      }
    }
  }

  panelContent: Item {
    id: content

    // Dynamic content sizing that SmartPanel will watch for changes
    property real contentPreferredWidth: (root.columns * root.cellSize) + ((root.columns - 1) * root.innerSpacing) + (2 * root.outerPadding)
    property real contentPreferredHeight: (root.rows * root.cellSize) + ((root.rows - 1) * root.innerSpacing) + (2 * root.outerPadding)

    Grid {
      id: grid
      anchors.fill: parent
      anchors.margins: outerPadding
      spacing: innerSpacing
      columns: root.columns
      rowSpacing: innerSpacing
      columnSpacing: innerSpacing

      Repeater {
        id: repeater
        model: root.trayValues

        delegate: Item {
          width: root.cellSize
          height: root.cellSize

          IconImage {
            id: trayIcon
            anchors.fill: parent
            asynchronous: true
            backer.fillMode: Image.PreserveAspectFit
            source: {
              let icon = modelData?.icon || ""
              if (!icon)
                return ""
              if (icon.includes("?path=")) {
                const chunks = icon.split("?path=")
                const name = chunks[0]
                const path = chunks[1]
                const fileName = name.substring(name.lastIndexOf("/") + 1)
                return `file://${path}/${fileName}`
              }
              return icon
            }

            layer.enabled: root.widgetSettings.colorizeIcons !== false
            layer.effect: ShaderEffect {
              property color targetColor: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mSurfaceVariant
              property real colorizeMode: 1.0
              fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

              onClicked: mouse => {
                           if (!modelData)
                           return

                           if (mouse.button === Qt.LeftButton) {
                             // Left click: activate tray item
                             if (!modelData.onlyMenu) {
                               modelData.activate()
                             }
                           } else if (mouse.button === Qt.MiddleButton) {
                             // Middle click: activate with middle button
                             modelData.activate(1)
                           } else if (mouse.button === Qt.RightButton) {
                             // Right click: open context menu
                             TooltipService.hideImmediately()

                             // Close menu if already visible
                             if (trayMenuWindow && trayMenuWindow.visible) {
                               trayMenuWindow.close()
                               return
                             }

                             if (modelData.hasMenu && modelData.menu && trayMenuWindow && trayMenu && trayMenu.item) {
                               trayMenuWindow.open()

                               // Position menu at the tray icon
                               const barPosition = Settings.data.bar.position
                               let menuX, menuY

                               if (barPosition === "left") {
                                 menuX = trayIcon.width + Style.marginM
                                 menuY = 0
                               } else if (barPosition === "right") {
                                 menuX = -trayMenu.item.width - Style.marginM
                                 menuY = 0
                               } else {
                                 // Horizontal bars
                                 menuX = (trayIcon.width / 2) - (trayMenu.item.width / 2)
                                 menuY = trayIcon.height + Style.marginS
                               }

                               trayMenu.item.trayItem = modelData
                               trayMenu.item.widgetSection = root.widgetSection
                               trayMenu.item.widgetIndex = root.widgetIndex
                               trayMenu.item.showAt(trayIcon, menuX, menuY)
                             }
                           }
                         }

              onWheel: wheel => {
                         if (wheel.angleDelta.y > 0)
                         modelData?.scrollUp()
                         else if (wheel.angleDelta.y < 0)
                         modelData?.scrollDown()
                       }

              onEntered: {
                if (trayMenuWindow) {
                  trayMenuWindow.close()
                }
                TooltipService.show(Screen, trayIcon, modelData.tooltipTitle || modelData.name || modelData.id || "Tray Item", BarService.getTooltipDirection())
              }
              onExited: TooltipService.hide()
            }
          }
        }
      }
    }
  }
}
