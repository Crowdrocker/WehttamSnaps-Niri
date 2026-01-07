import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root

  property string label: ""
  property string description: ""
  property bool enableDescriptionRichText: false

  spacing: Style.marginXXS
  Layout.fillWidth: true
  Layout.bottomMargin: Style.marginM

  NText {
    text: root.label
    pointSize: Style.fontSizeXL
    font.weight: Style.fontWeightSemiBold
    color: Color.mSecondary
    visible: root.label !== ""
  }

  NText {
    text: root.description
    pointSize: Style.fontSizeM
    color: Color.mOnSurfaceVariant
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    visible: root.description !== ""
    richTextEnabled: root.enableDescriptionRichText
  }
}
