import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Networking
import qs.Widgets

NBox {
  id: root

  property string label: ""
  property var model: []
  property string passwordSsid: ""
  property string expandedSsid: ""

  signal passwordRequested(string ssid)
  signal passwordSubmitted(string ssid, string password)
  signal passwordCancelled
  signal forgetRequested(string ssid)
  signal forgetConfirmed(string ssid)
  signal forgetCancelled

  Layout.fillWidth: true
  Layout.preferredHeight: column.implicitHeight + Style.marginM * 2
  visible: root.model.length > 0

  ColumnLayout {
    id: column
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginM

    NText {
      text: root.label
      pointSize: Style.fontSizeS
      color: Color.mSecondary
      font.weight: Style.fontWeightBold
      visible: root.model.length > 0
      Layout.fillWidth: true
      Layout.leftMargin: Style.marginS
    }

    Repeater {
      model: root.model

      Rectangle {
        id: networkItem

        Layout.fillWidth: true
        Layout.leftMargin: Style.marginXS
        Layout.rightMargin: Style.marginXS
        implicitHeight: netColumn.implicitHeight + (Style.marginM * 2)
        radius: Style.radiusM
        border.width: Style.borderS
        border.color: modelData.connected ? Color.mPrimary : Color.mOutline

        opacity: (NetworkService.disconnectingFrom === modelData.ssid || NetworkService.forgettingNetwork === modelData.ssid) ? 0.6 : 1.0

        color: modelData.connected ? Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.05) : Color.mSurface

        Behavior on opacity {
          NumberAnimation {
            duration: Style.animationNormal
          }
        }

        ColumnLayout {
          id: netColumn
          width: parent.width - (Style.marginM * 2)
          x: Style.marginM
          y: Style.marginM
          spacing: Style.marginS

          // Main row
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NIcon {
              icon: NetworkService.signalIcon(modelData.signal, modelData.connected)
              pointSize: Style.fontSizeXXL
              color: modelData.connected ? Color.mPrimary : Color.mOnSurface
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              NText {
                text: modelData.ssid
                pointSize: Style.fontSizeM
                font.weight: modelData.connected ? Style.fontWeightBold : Style.fontWeightMedium
                color: Color.mOnSurface
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              RowLayout {
                spacing: Style.marginXS

                NText {
                  text: I18n.tr("system.signal-strength", {
                                  "signal": modelData.signal
                                })
                  pointSize: Style.fontSizeXXS
                  color: Color.mOnSurfaceVariant
                }

                NText {
                  text: "•"
                  pointSize: Style.fontSizeXXS
                  color: Color.mOnSurfaceVariant
                }

                NText {
                  text: NetworkService.isSecured(modelData.security) ? modelData.security : "Open"
                  pointSize: Style.fontSizeXXS
                  color: Color.mOnSurfaceVariant
                }

                Item {
                  Layout.preferredWidth: Style.marginXXS
                }

                // Status badges
                Rectangle {
                  visible: modelData.connected && NetworkService.disconnectingFrom !== modelData.ssid
                  color: Color.mPrimary
                  radius: height * 0.5
                  width: connectedText.implicitWidth + (Style.marginS * 2)
                  height: connectedText.implicitHeight + (Style.marginXXS * 2)

                  NText {
                    id: connectedText
                    anchors.centerIn: parent
                    text: I18n.tr("wifi.panel.connected")
                    pointSize: Style.fontSizeXXS
                    color: Color.mOnPrimary
                  }
                }

                Rectangle {
                  visible: NetworkService.disconnectingFrom === modelData.ssid
                  color: Color.mError
                  radius: height * 0.5
                  width: disconnectingText.implicitWidth + (Style.marginS * 2)
                  height: disconnectingText.implicitHeight + (Style.marginXXS * 2)

                  NText {
                    id: disconnectingText
                    anchors.centerIn: parent
                    text: I18n.tr("wifi.panel.disconnecting")
                    pointSize: Style.fontSizeXXS
                    color: Color.mOnPrimary
                  }
                }

                Rectangle {
                  visible: NetworkService.forgettingNetwork === modelData.ssid
                  color: Color.mError
                  radius: height * 0.5
                  width: forgettingText.implicitWidth + (Style.marginS * 2)
                  height: forgettingText.implicitHeight + (Style.marginXXS * 2)

                  NText {
                    id: forgettingText
                    anchors.centerIn: parent
                    text: I18n.tr("wifi.panel.forgetting")
                    pointSize: Style.fontSizeXXS
                    color: Color.mOnPrimary
                  }
                }

                Rectangle {
                  visible: modelData.cached && !modelData.connected && NetworkService.forgettingNetwork !== modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid
                  color: Color.transparent
                  border.color: Color.mOutline
                  border.width: Style.borderS
                  radius: height * 0.5
                  width: savedText.implicitWidth + (Style.marginS * 2)
                  height: savedText.implicitHeight + (Style.marginXXS * 2)

                  NText {
                    id: savedText
                    anchors.centerIn: parent
                    text: I18n.tr("wifi.panel.saved")
                    pointSize: Style.fontSizeXXS
                    color: Color.mOnSurfaceVariant
                  }
                }
              }
            }

            // Action area
            RowLayout {
              spacing: Style.marginS

              NBusyIndicator {
                visible: NetworkService.connectingTo === modelData.ssid || NetworkService.disconnectingFrom === modelData.ssid || NetworkService.forgettingNetwork === modelData.ssid
                running: visible
                color: Color.mPrimary
                size: Style.baseWidgetSize * 0.5
              }

              NIconButton {
                visible: (modelData.existing || modelData.cached) && !modelData.connected && NetworkService.connectingTo !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid
                icon: "trash"
                tooltipText: I18n.tr("tooltips.forget-network")
                baseSize: Style.baseWidgetSize * 0.8
                onClicked: root.forgetRequested(modelData.ssid)
              }

              NButton {
                visible: !modelData.connected && NetworkService.connectingTo !== modelData.ssid && root.passwordSsid !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid
                text: {
                  if (modelData.existing || modelData.cached)
                    return I18n.tr("wifi.panel.connect");
                  if (!NetworkService.isSecured(modelData.security))
                    return I18n.tr("wifi.panel.connect");
                  return I18n.tr("wifi.panel.password");
                }
                outlined: !hovered
                fontSize: Style.fontSizeXS
                enabled: !NetworkService.connecting
                onClicked: {
                  if (modelData.existing || modelData.cached || !NetworkService.isSecured(modelData.security)) {
                    NetworkService.connect(modelData.ssid);
                  } else {
                    root.passwordRequested(modelData.ssid);
                  }
                }
              }

              NButton {
                visible: modelData.connected && NetworkService.disconnectingFrom !== modelData.ssid
                text: I18n.tr("wifi.panel.disconnect")
                outlined: !hovered
                fontSize: Style.fontSizeXS
                backgroundColor: Color.mError
                onClicked: NetworkService.disconnect(modelData.ssid)
              }
            }
          }

          // Password input
          Rectangle {
            visible: root.passwordSsid === modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid
            Layout.fillWidth: true
            height: passwordRow.implicitHeight + Style.marginS * 2
            color: Color.mSurfaceVariant
            border.color: Color.mOutline
            border.width: Style.borderS
            radius: Style.radiusS

            RowLayout {
              id: passwordRow
              anchors.fill: parent
              anchors.margins: Style.marginS
              spacing: Style.marginM

              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.radiusXS
                color: Color.mSurface
                border.color: pwdInput.activeFocus ? Color.mSecondary : Color.mOutline
                border.width: Style.borderS

                TextInput {
                  id: pwdInput
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.margins: Style.marginS
                  font.family: Settings.data.ui.fontFixed
                  font.pointSize: Style.fontSizeS
                  color: Color.mOnSurface
                  echoMode: TextInput.Password
                  selectByMouse: true
                  focus: visible
                  passwordCharacter: "●"
                  onVisibleChanged: if (visible) {
                                      text = "";
                                      forceActiveFocus();
                                    }
                  onAccepted: {
                    if (text && !NetworkService.connecting) {
                      root.passwordSubmitted(modelData.ssid, text);
                    }
                  }

                  NText {
                    visible: parent.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("wifi.panel.enter-password")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                  }
                }
              }

              NButton {
                text: I18n.tr("wifi.panel.connect")
                fontSize: Style.fontSizeXXS
                enabled: pwdInput.text.length > 0 && !NetworkService.connecting
                outlined: true
                onClicked: root.passwordSubmitted(modelData.ssid, pwdInput.text)
              }

              NIconButton {
                icon: "close"
                baseSize: Style.baseWidgetSize * 0.8
                onClicked: root.passwordCancelled()
              }
            }
          }

          // Forget network
          Rectangle {
            visible: root.expandedSsid === modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid
            Layout.fillWidth: true
            height: forgetRow.implicitHeight + Style.marginS * 2
            color: Color.mSurfaceVariant
            radius: Style.radiusS
            border.width: Style.borderS
            border.color: Color.mOutline

            RowLayout {
              id: forgetRow
              anchors.fill: parent
              anchors.margins: Style.marginS
              spacing: Style.marginM

              RowLayout {
                NIcon {
                  icon: "trash"
                  pointSize: Style.fontSizeL
                  color: Color.mError
                }

                NText {
                  text: I18n.tr("wifi.panel.forget-network")
                  pointSize: Style.fontSizeS
                  color: Color.mError
                  Layout.fillWidth: true
                }
              }

              NButton {
                id: forgetButton
                text: I18n.tr("wifi.panel.forget")
                fontSize: Style.fontSizeXXS
                backgroundColor: Color.mError
                outlined: forgetButton.hovered ? false : true
                onClicked: root.forgetConfirmed(modelData.ssid)
              }

              NIconButton {
                icon: "close"
                baseSize: Style.baseWidgetSize * 0.8
                onClicked: root.forgetCancelled()
              }
            }
          }
        }
      }
    }
  }
}
