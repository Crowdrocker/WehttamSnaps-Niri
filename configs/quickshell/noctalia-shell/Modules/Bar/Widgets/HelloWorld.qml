import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services

Rectangle {
    id: root

    // Provided by Bar.qml via NWidgetLoader
    property var screen
    property real scaling: 1.0
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    // Access your metadata and per-instance settings
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

    implicitHeight: Math.round(Style.capsuleHeight * scaling)
    implicitWidth: Math.round(120 * scaling)
    radius: Math.round(Style.radiusS * scaling)
    color: Color.mSurfaceVariant
    border.width: Math.max(1, Style.borderS * scaling)
    border.color: Color.mOutline

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Style.marginXS * scaling
        spacing: Style.marginXS * scaling

        NText {
            text: widgetSettings.text !== undefined ? widgetSettings.text : (widgetMetadata?.text || "Hello")
            font.pointSize: Style.fontSizeXS * scaling
            font.weight: Style.fontWeightBold
            color: Color.mPrimary
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        }
    }
}
