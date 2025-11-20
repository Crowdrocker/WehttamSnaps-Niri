import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services.Compositor
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property bool isVerticalBar: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"
  readonly property string density: Settings.data.bar.density
  readonly property real itemSize: (density === "compact") ? Style.capsuleHeight * 0.9 : Style.capsuleHeight * 0.8
  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId]
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0) {
      var widgets = Settings.data.bar.widgets[section]
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex]
      }
    }
    return {}
  }
  readonly property bool hideUnoccupied: (widgetSettings.hideUnoccupied !== undefined) ? widgetSettings.hideUnoccupied : false
  readonly property bool showWorkspaceNumbers: (widgetSettings.showWorkspaceNumbers !== undefined) ? widgetSettings.showWorkspaceNumbers : true
  readonly property bool showNumbersOnlyWhenOccupied: (widgetSettings.showNumbersOnlyWhenOccupied !== undefined) ? widgetSettings.showNumbersOnlyWhenOccupied : true
  property ListModel localWorkspaces: ListModel {}
  property real masterProgress: 0.0
  property bool effectsActive: false
  property color effectColor: Color.mPrimary

  function refreshWorkspaces() {
    localWorkspaces.clear()
    if (!screen)
      return

    const screenName = screen.name.toLowerCase()

    for (var i = 0; i < CompositorService.workspaces.count; i++) {
      const ws = CompositorService.workspaces.get(i)

      if (ws.output.toLowerCase() !== screenName)
        continue
      if (hideUnoccupied && !ws.isOccupied && !ws.isFocused)
        continue

      // Copy all properties from ws and add windows
      var workspaceData = Object.assign({}, ws)
      workspaceData.windows = CompositorService.getWindowsForWorkspace(ws.id)

      localWorkspaces.append(workspaceData)
    }
    updateWorkspaceFocus()
  }

  function triggerUnifiedWave() {
    effectColor = Color.mPrimary
    masterAnimation.restart()
  }

  function updateWorkspaceFocus() {
    for (var i = 0; i < localWorkspaces.count; i++) {
      const ws = localWorkspaces.get(i)
      if (ws.isFocused === true) {
        root.triggerUnifiedWave()
        break
      }
    }
  }

  Component.onCompleted: {
    refreshWorkspaces()
  }

  onScreenChanged: refreshWorkspaces()

  implicitWidth: isVerticalBar ? taskbarGrid.implicitWidth + Style.marginM * 2 : Math.round(taskbarGrid.implicitWidth + Style.marginM * 2)
  implicitHeight: isVerticalBar ? Math.round(taskbarGrid.implicitHeight + Style.marginM * 2) : Style.barHeight

  Connections {
    target: CompositorService

    function onWorkspacesChanged() {
      refreshWorkspaces()
    }

    function onWindowListChanged() {
      refreshWorkspaces()
    }
  }

  SequentialAnimation {
    id: masterAnimation
    PropertyAction {
      target: root
      property: "effectsActive"
      value: true
    }
    NumberAnimation {
      target: root
      property: "masterProgress"
      from: 0.0
      to: 1.0
      duration: Style.animationSlow * 2
      easing.type: Easing.OutQuint
    }
    PropertyAction {
      target: root
      property: "effectsActive"
      value: false
    }
    PropertyAction {
      target: root
      property: "masterProgress"
      value: 0.0
    }
  }

  Component {
    id: workspaceRepeaterDelegate

    Rectangle {
      id: container

      required property var model
      property var workspaceModel: model
      property bool hasWindows: workspaceModel.windows.count > 0

      radius: Style.radiusS
      border.color: workspaceModel.isFocused ? Color.mPrimary : Color.mOutline
      border.width: 1
      width: (hasWindows ? iconsFlow.implicitWidth : root.itemSize * 0.8) + (root.isVerticalBar ? Style.marginXS : Style.marginL)
      height: (hasWindows ? iconsFlow.implicitHeight : root.itemSize * 0.8) + (root.isVerticalBar ? Style.marginL : Style.marginXS)
      color: Settings.data.bar.showCapsule ? Color.mSurfaceVariant : Color.transparent

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        enabled: !hasWindows
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
          CompositorService.switchToWorkspace(workspaceModel)
        }
      }

      Flow {
        id: iconsFlow

        anchors.centerIn: parent
        spacing: 4
        flow: root.isVerticalBar ? Flow.TopToBottom : Flow.LeftToRight

        Repeater {
          model: workspaceModel.windows

          delegate: Item {
            id: taskbarItem

            property bool itemHovered: false

            width: root.itemSize * 0.8
            height: root.itemSize * 0.8

            // Smooth scale animation on hover
            scale: itemHovered ? 1.1 : 1.0

            Behavior on scale {
              NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutBack
              }
            }

            IconImage {
              id: appIcon

              width: parent.width
              height: parent.height
              source: ThemeIcons.iconForAppId(model.appId)
              smooth: true
              asynchronous: true
              opacity: model.isFocused ? Style.opacityFull : 0.6
              layer.enabled: widgetSettings.colorizeIcons === true

              Behavior on opacity {
                NumberAnimation {
                  duration: Style.animationNormal
                  easing.type: Easing.InOutCubic
                }
              }

              Rectangle {
                id: focusIndicator
                anchors.bottomMargin: -2
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: model.isFocused ? 4 : 0
                height: model.isFocused ? 4 : 0
                color: model.isFocused ? Color.mPrimary : Color.transparent
                radius: width * 0.5
              }

              layer.effect: ShaderEffect {
                property color targetColor: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mSurfaceVariant
                property real colorizeMode: 0
                fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onPressed: function (mouse) {
                if (!model) {
                  return
                }

                if (mouse.button === Qt.LeftButton) {
                  CompositorService.focusWindow(model)
                } else if (mouse.button === Qt.RightButton) {
                  CompositorService.closeWindow(model)
                }
              }
              onEntered: {
                taskbarItem.itemHovered = true
                TooltipService.show(Screen, taskbarItem, model.title || model.appId || "Unknown app.", BarService.getTooltipDirection())
              }
              onExited: {
                taskbarItem.itemHovered = false
                TooltipService.hide()
              }
            }
          }
        }
      }

      Item {
        id: workspaceNumberContainer

        visible: root.showWorkspaceNumbers && (!root.showNumbersOnlyWhenOccupied || container.hasWindows)

        anchors {
          left: parent.left
          top: parent.top
          leftMargin: -Style.fontSizeXS * 0.5
          topMargin: -Style.fontSizeXS * 0.5
        }

        width: Math.max(workspaceNumber.implicitWidth + Style.marginXS, Style.fontSizeXXS * 2)
        height: Math.max(workspaceNumber.implicitHeight + Style.marginXS, Style.fontSizeXXS * 2)

        Rectangle {
          id: workspaceNumberBackground

          anchors.fill: parent
          radius: width * 0.5

          color: {
            if (workspaceModel.isFocused)
              return Color.mPrimary
            if (workspaceModel.isUrgent)
              return Color.mError
            if (hasWindows)
              return Color.mSecondary

            return Qt.alpha(Color.mOutline, 0.3)
          }

          scale: workspaceModel.isActive ? 1.0 : 0.9

          Behavior on scale {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutBack
            }
          }

          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
              easing.type: Easing.InOutCubic
            }
          }
        }

        // Burst effect overlay for focused workspace number (smaller outline)
        Rectangle {
          id: workspaceNumberBurst
          anchors.centerIn: workspaceNumberContainer
          width: workspaceNumberContainer.width + 12 * root.masterProgress
          height: workspaceNumberContainer.height + 12 * root.masterProgress
          radius: width / 2
          color: Color.transparent
          border.color: root.effectColor
          border.width: Math.max(1, Math.round((2 + 4 * (1.0 - root.masterProgress))))
          opacity: root.effectsActive && workspaceModel.isFocused ? (1.0 - root.masterProgress) * 0.7 : 0
          visible: root.effectsActive && workspaceModel.isFocused
          z: 1
        }

        NText {
          id: workspaceNumber

          anchors.centerIn: parent

          text: workspaceModel.idx.toString()

          family: Settings.data.ui.fontFixed
          font {
            pointSize: Style.fontSizeXXS
            weight: Style.fontWeightBold
            capitalization: Font.AllUppercase
          }
          applyUiScale: false

          color: {
            if (workspaceModel.isFocused)
              return Color.mOnPrimary
            if (workspaceModel.isUrgent)
              return Color.mOnError
            if (hasWindows)
              return Color.mOnSecondary

            return Color.mOnSurface
          }

          opacity: {
            if (workspaceModel.isFocused)
              return 1.0
            if (workspaceModel.isUrgent)
              return 0.9
            if (hasWindows)
              return 0.8

            return 0.6
          }

          Behavior on opacity {
            NumberAnimation {
              duration: Style.animationFast
              easing.type: Easing.InOutCubic
            }
          }
        }

        Behavior on opacity {
          NumberAnimation {
            duration: Style.animationFast
            easing.type: Easing.InOutCubic
          }
        }
      }
    }
  }

  Flow {
    id: taskbarGrid

    anchors.verticalCenter: isVerticalBar ? undefined : parent.verticalCenter
    anchors.left: isVerticalBar ? undefined : parent.left
    anchors.leftMargin: isVerticalBar ? 0 : Style.marginM
    anchors.horizontalCenter: isVerticalBar ? parent.horizontalCenter : undefined
    anchors.top: isVerticalBar ? parent.top : undefined
    anchors.topMargin: isVerticalBar ? Style.marginM : 0

    spacing: Style.marginS
    flow: isVerticalBar ? Flow.TopToBottom : Flow.LeftToRight

    Repeater {
      model: localWorkspaces
      delegate: workspaceRepeaterDelegate
    }
  }
}
