import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  // Properties to receive data from parent
  property var widgetData: null
  property var widgetMetadata: null

  property bool valueShowWorkspaceNumbers: widgetData.showWorkspaceNumbers !== undefined ? widgetData.showWorkspaceNumbers : widgetMetadata.showWorkspaceNumbers
  property bool valueShowNumbersOnlyWhenOccupied: widgetData.showNumbersOnlyWhenOccupied !== undefined ? widgetData.showNumbersOnlyWhenOccupied : widgetMetadata.showNumbersOnlyWhenOccupied

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.showWorkspaceNumbers = valueShowWorkspaceNumbers
    settings.showNumbersOnlyWhenOccupied = valueShowNumbersOnlyWhenOccupied
    return settings
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.taskbar-grouped.show-workspace-numbers.label")
    description: I18n.tr("bar.widget-settings.taskbar-grouped.show-workspace-numbers.description")
    checked: root.valueShowWorkspaceNumbers
    onToggled: checked => root.valueShowWorkspaceNumbers = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.taskbar-grouped.show-numbers-only-when-occupied.label")
    description: I18n.tr("bar.widget-settings.taskbar-grouped.show-numbers-only-when-occupied.description")
    checked: root.valueShowNumbersOnlyWhenOccupied
    onToggled: checked => root.valueShowNumbersOnlyWhenOccupied = checked
    visible: root.valueShowWorkspaceNumbers
  }
}
