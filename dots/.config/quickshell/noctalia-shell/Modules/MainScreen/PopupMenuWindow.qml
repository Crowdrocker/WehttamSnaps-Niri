import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.UI

// Generic full-screen popup window for menus and context menus
// This is a top-level PanelWindow (sibling to MainScreen, not nested inside it)
// Provides click-outside-to-close functionality for any popup content
// Loads TrayMenu by default but can show context menus via showContextMenu()
PanelWindow {
  id: root

  required property ShellScreen screen
  property string windowType: "popupmenu"  // Used for namespace and registration

  // Content item to display (set by the popup that uses this window)
  property var contentItem: null

  // Expose the trayMenu Loader directly (for backward compatibility)
  readonly property alias trayMenuLoader: trayMenuLoader

  anchors.top: true
  anchors.left: true
  anchors.right: true
  anchors.bottom: true
  visible: false
  color: Color.transparent

  // Use Top layer (same as MainScreen) for proper event handling
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: hasDialog ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  WlrLayershell.namespace: "noctalia-" + windowType + "-" + (screen?.name || "unknown")
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  // Track if a dialog is currently open (needed for keyboard focus)
  property bool hasDialog: false

  // Register with PanelService so widgets can find this window
  Component.onCompleted: {
    objectName = "popupMenuWindow-" + (screen?.name || "unknown");
    PanelService.registerPopupMenuWindow(screen, root);
  }

  // Load TrayMenu as the default content
  Loader {
    id: trayMenuLoader
    source: Quickshell.shellDir + "/Modules/Bar/Extras/TrayMenu.qml"
    onLoaded: {
      if (item) {
        item.screen = root.screen;
        // Set the loaded item as default content
        root.contentItem = item;
      }
    }
  }

  function open() {
    visible = true;
  }

  // Show a context menu (temporarily replaces TrayMenu as content)
  function showContextMenu(menu) {
    if (menu) {
      contentItem = menu;
      open();
    }
  }

  function close() {
    visible = false;
    // Call close/hide method on current content
    if (contentItem) {
      if (typeof contentItem.hideMenu === "function") {
        contentItem.hideMenu();
      } else if (typeof contentItem.close === "function") {
        contentItem.close();
      }
    }
    // Restore TrayMenu as default content
    if (trayMenuLoader.item) {
      contentItem = trayMenuLoader.item;
    }
  }

  // Full-screen click catcher - click anywhere outside content closes the window
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: root.close()
  }

  // Container for dialogs that need a full-screen Item parent (e.g., Qt Popup)
  Item {
    id: dialogContainer
    anchors.fill: parent
  }

  // Expose the dialog container for external use
  readonly property alias dialogParent: dialogContainer
}
