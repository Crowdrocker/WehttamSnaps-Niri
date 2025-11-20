import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

PopupWindow {
  id: root
  property var trayItem: null
  property var anchorItem: null
  property real anchorX
  property real anchorY
  property bool isSubMenu: false
  property bool isHovered: rootMouseArea.containsMouse
  property ShellScreen screen
  property string widgetSection: ""
  property int widgetIndex: -1

  // Derive menu from trayItem (only used for non-submenus)
  readonly property QsMenuHandle menu: isSubMenu ? null : (trayItem ? trayItem.menu : null)

  // Compute if current tray item is pinned
  readonly property bool isPinned: {
    if (!trayItem || widgetSection === "" || widgetIndex < 0)
      return false
    var widgets = Settings.data.bar.widgets[widgetSection]
    if (!widgets || widgetIndex >= widgets.length)
      return false
    var widgetSettings = widgets[widgetIndex]
    if (!widgetSettings || widgetSettings.id !== "Tray")
      return false
    var pinnedList = widgetSettings.pinned || []
    const itemName = trayItem.tooltipTitle || trayItem.name || trayItem.id || ""
    for (var i = 0; i < pinnedList.length; i++) {
      if (pinnedList[i] === itemName)
        return true
    }
    return false
  }

  readonly property int menuWidth: 180

  implicitWidth: menuWidth

  // Use the content height of the Flickable for implicit height
  implicitHeight: Math.min(screen ? screen.height * 0.9 : Screen.height * 0.9, flickable.contentHeight + (Style.marginS * 2))
  visible: false
  color: Color.transparent
  anchor.item: anchorItem
  anchor.rect.x: anchorX
  anchor.rect.y: anchorY - (isSubMenu ? 0 : 4)

  function showAt(item, x, y) {
    if (!item) {
      Logger.warn("TrayMenu", "anchorItem is undefined, won't show menu.")
      return
    }

    if (!opener.children || opener.children.values.length === 0) {
      //Logger.warn("TrayMenu", "Menu not ready, delaying show")
      Qt.callLater(() => showAt(item, x, y))
      return
    }

    anchorItem = item
    anchorX = x
    anchorY = y

    visible = true
    forceActiveFocus()

    // Force update after showing.
    Qt.callLater(() => {
                   root.anchor.updateAnchor()
                 })
  }

  function hideMenu() {
    visible = false

    // Clean up all submenus recursively
    for (var i = 0; i < columnLayout.children.length; i++) {
      const child = columnLayout.children[i]
      if (child?.subMenu) {
        child.subMenu.hideMenu()
        child.subMenu.destroy()
        child.subMenu = null
      }
    }
  }

  // Full-sized, transparent MouseArea to track the mouse.
  MouseArea {
    id: rootMouseArea
    anchors.fill: parent
    hoverEnabled: true
  }

  Item {
    anchors.fill: parent
    Keys.onEscapePressed: root.hideMenu()
  }

  QsMenuOpener {
    id: opener
    menu: root.menu
  }

  Rectangle {
    anchors.fill: parent
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: Math.max(1, Style.borderS)
    radius: Style.radiusM
  }

  Flickable {
    id: flickable
    anchors.fill: parent
    anchors.margins: Style.marginS
    contentHeight: columnLayout.implicitHeight
    interactive: true

    // Use a ColumnLayout to handle menu item arrangement
    ColumnLayout {
      id: columnLayout
      width: flickable.width
      spacing: 0

      Repeater {
        model: opener.children ? [...opener.children.values] : []

        delegate: Rectangle {
          id: entry
          required property var modelData

          Layout.preferredWidth: parent.width
          Layout.preferredHeight: {
            if (modelData?.isSeparator) {
              return 8
            } else {
              // Calculate based on text content
              const textHeight = text.contentHeight || (Style.fontSizeS * 1.2)
              return Math.max(28, textHeight + (Style.marginS * 2))
            }
          }

          color: Color.transparent
          property var subMenu: null

          NDivider {
            anchors.centerIn: parent
            width: parent.width - (Style.marginM * 2)
            visible: modelData?.isSeparator ?? false
          }

          Rectangle {
            anchors.fill: parent
            color: mouseArea.containsMouse ? Color.mTertiary : Color.transparent
            radius: Style.radiusS
            visible: !(modelData?.isSeparator ?? false)

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Style.marginM
              anchors.rightMargin: Style.marginM
              spacing: Style.marginS

              NText {
                id: text
                Layout.fillWidth: true
                color: (modelData?.enabled ?? true) ? (mouseArea.containsMouse ? Color.mOnTertiary : Color.mOnSurface) : Color.mOnSurfaceVariant
                text: modelData?.text !== "" ? modelData?.text.replace(/[\n\r]+/g, ' ') : "..."
                pointSize: Style.fontSizeS
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
              }

              Image {
                Layout.preferredWidth: Style.marginL
                Layout.preferredHeight: Style.marginL
                source: modelData?.icon ?? ""
                visible: (modelData?.icon ?? "") !== ""
                fillMode: Image.PreserveAspectFit
              }

              NIcon {
                icon: modelData?.hasChildren ? "menu" : ""
                pointSize: Style.fontSizeS
                applyUiScale: false
                verticalAlignment: Text.AlignVCenter
                visible: modelData?.hasChildren ?? false
                color: (mouseArea.containsMouse ? Color.mOnTertiary : Color.mOnSurface)
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              enabled: (modelData?.enabled ?? true) && !(modelData?.isSeparator ?? false) && root.visible

              onClicked: {
                if (modelData && !modelData.isSeparator && !modelData.hasChildren) {
                  modelData.triggered()
                  root.hideMenu()

                  // Close the drawer if it's open
                  if (screen) {
                    const panel = PanelService.getPanel("trayDrawerPanel", screen)
                    if (panel && panel.visible) {
                      panel.close()
                    }
                  }
                }
              }

              onEntered: {
                if (!root.visible)
                  return

                // Close all sibling submenus
                for (var i = 0; i < columnLayout.children.length; i++) {
                  const sibling = columnLayout.children[i]
                  if (sibling !== entry && sibling?.subMenu) {
                    sibling.subMenu.hideMenu()
                    sibling.subMenu.destroy()
                    sibling.subMenu = null
                  }
                }

                // Create submenu if needed
                if (modelData?.hasChildren) {
                  if (entry.subMenu) {
                    entry.subMenu.hideMenu()
                    entry.subMenu.destroy()
                  }

                  // Need a slight overlap so that menu don't close when moving the mouse to a submenu
                  const submenuWidth = menuWidth // Assuming a similar width as the parent
                  const overlap = 4 // A small overlap to bridge the mouse path

                  // Determine submenu opening direction based on bar position and available space
                  let openLeft = false

                  // Check bar position first
                  const barPosition = Settings.data.bar.position
                  const globalPos = entry.mapToItem(null, 0, 0)

                  if (barPosition === "right") {
                    // Bar is on the right, prefer opening submenus to the left
                    openLeft = true
                  } else if (barPosition === "left") {
                    // Bar is on the left, prefer opening submenus to the right
                    openLeft = false
                  } else {
                    // Bar is horizontal (top/bottom) or undefined, use space-based logic
                    openLeft = (globalPos.x + entry.width + submenuWidth > screen.width)

                    // Secondary check: ensure we don't open off-screen
                    if (openLeft && globalPos.x - submenuWidth < 0) {
                      // Would open off the left edge, force right opening
                      openLeft = false
                    } else if (!openLeft && globalPos.x + entry.width + submenuWidth > screen.width) {
                      // Would open off the right edge, force left opening
                      openLeft = true
                    }
                  }

                  // Position with overlap
                  const anchorX = openLeft ? -submenuWidth + overlap : entry.width - overlap

                  // Create submenu
                  entry.subMenu = Qt.createComponent("TrayMenu.qml").createObject(root, {
                                                                                    "menu": modelData,
                                                                                    "anchorItem": entry,
                                                                                    "anchorX": anchorX,
                                                                                    "anchorY": 0,
                                                                                    "isSubMenu": true,
                                                                                    "screen": screen
                                                                                  })

                  if (entry.subMenu) {
                    entry.subMenu.showAt(entry, anchorX, 0)
                  }
                }
              }

              onExited: {
                Qt.callLater(() => {
                               if (entry.subMenu && !entry.subMenu.isHovered) {
                                 entry.subMenu.hideMenu()
                                 entry.subMenu.destroy()
                                 entry.subMenu = null
                               }
                             })
              }
            }
          }

          Component.onDestruction: {
            if (subMenu) {
              subMenu.destroy()
              subMenu = null
            }
          }
        }
      }

      // PIN / UNPIN
      Rectangle {
        Layout.preferredWidth: parent.width
        Layout.preferredHeight: 28
        color: pinUnpinMouseArea.containsMouse ? Qt.alpha(Color.mPrimary, 0.2) : Qt.alpha(Color.mPrimary, 0.08)
        radius: Style.radiusS
        border.color: Qt.alpha(Color.mPrimary, pinUnpinMouseArea.containsMouse ? 0.4 : 0.2)
        border.width: Style.borderS

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Style.marginM
          anchors.rightMargin: Style.marginM
          spacing: Style.marginS

          NIcon {
            icon: root.isPinned ? "unpin" : "pin"
            pointSize: Style.fontSizeS
            applyUiScale: false
            verticalAlignment: Text.AlignVCenter
            color: Color.mPrimary
          }

          NText {
            Layout.fillWidth: true
            color: Color.mPrimary
            text: root.isPinned ? I18n.tr("settings.bar.tray.unpin-application") : I18n.tr("settings.bar.tray.pin-application")
            pointSize: Style.fontSizeS
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }
        }

        MouseArea {
          id: pinUnpinMouseArea
          anchors.fill: parent
          hoverEnabled: true

          onClicked: {
            if (root.isPinned) {
              root.removeFromPinned()
            } else {
              root.addToPinned()
            }
          }
        }
      }
    }
  }

  function addToPinned() {
    if (!trayItem || widgetSection === "" || widgetIndex < 0) {
      Logger.w("TrayMenu", "Cannot pin: missing tray item or widget info")
      return
    }
    const itemName = trayItem.tooltipTitle || trayItem.name || trayItem.id || ""
    if (!itemName) {
      Logger.w("TrayMenu", "Cannot pin: tray item has no name")
      return
    }
    var widgets = Settings.data.bar.widgets[widgetSection]
    if (!widgets || widgetIndex >= widgets.length) {
      Logger.w("TrayMenu", "Cannot pin: invalid widget index")
      return
    }
    var widgetSettings = widgets[widgetIndex]
    if (!widgetSettings || widgetSettings.id !== "Tray") {
      Logger.w("TrayMenu", "Cannot pin: widget is not a Tray widget")
      return
    }
    var pinnedList = widgetSettings.pinned || []
    var newPinned = pinnedList.slice()
    newPinned.push(itemName)
    var newSettings = Object.assign({}, widgetSettings)
    newSettings.pinned = newPinned
    widgets[widgetIndex] = newSettings
    Settings.data.bar.widgets[widgetSection] = widgets
    Settings.saveImmediate()

    // Close drawer when pinning (drawer needs to resize)
    if (screen) {
      const panel = PanelService.getPanel("trayDrawerPanel", screen)
      if (panel)
        panel.close()
    }
  }

  function removeFromPinned() {
    if (!trayItem || widgetSection === "" || widgetIndex < 0) {
      Logger.w("TrayMenu", "Cannot unpin: missing tray item or widget info")
      return
    }
    const itemName = trayItem.tooltipTitle || trayItem.name || trayItem.id || ""
    if (!itemName) {
      Logger.w("TrayMenu", "Cannot unpin: tray item has no name")
      return
    }
    var widgets = Settings.data.bar.widgets[widgetSection]
    if (!widgets || widgetIndex >= widgets.length) {
      Logger.w("TrayMenu", "Cannot unpin: invalid widget index")
      return
    }
    var widgetSettings = widgets[widgetIndex]
    if (!widgetSettings || widgetSettings.id !== "Tray") {
      Logger.w("TrayMenu", "Cannot unpin: widget is not a Tray widget")
      return
    }
    var pinnedList = widgetSettings.pinned || []
    var newPinned = []
    for (var i = 0; i < pinnedList.length; i++) {
      if (pinnedList[i] !== itemName) {
        newPinned.push(pinnedList[i])
      }
    }
    var newSettings = Object.assign({}, widgetSettings)
    newSettings.pinned = newPinned
    widgets[widgetIndex] = newSettings
    Settings.data.bar.widgets[widgetSection] = widgets
    Settings.saveImmediate()
  }
}
