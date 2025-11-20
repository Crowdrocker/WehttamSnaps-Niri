import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    // Provided by the dialog loader
    property var widgetData
    property var widgetMetadata

    // Local state – initialize from widgetData with metadata fallback
    property string textValue: widgetData?.text !== undefined ? widgetData.text : (widgetMetadata?.text || "Hello")

    NText {
        text: "HelloWorld Text"
        font.pointSize: Style.fontSizeM * scaling
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
    }

    NTextInput {
        Layout.fillWidth: true
        placeholderText: "Enter text to display..."
        text: textValue
        onTextChanged: textValue = text
    }

    // Called by the dialog's Apply button
    function saveSettings() {
        // Return a new settings object; preserve other keys
        var updated = Object.assign({}, widgetData)
        updated.text = textValue
        return updated
    }
}
