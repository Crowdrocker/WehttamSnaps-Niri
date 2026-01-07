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

  property bool valueHideUnoccupied: widgetData.hideUnoccupied !== undefined ? widgetData.hideUnoccupied : widgetMetadata.hideUnoccupied
  property string valueLabelMode: widgetData.labelMode !== undefined ? widgetData.labelMode : widgetMetadata.labelMode
  property bool valueShowLabelsOnlyWhenOccupied: widgetData.showLabelsOnlyWhenOccupied !== undefined ? widgetData.showLabelsOnlyWhenOccupied : widgetMetadata.showLabelsOnlyWhenOccupied
  property bool valueColorizeIcons: widgetData.colorizeIcons !== undefined ? widgetData.colorizeIcons : widgetMetadata.colorizeIcons

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});

    settings.hideUnoccupied = valueHideUnoccupied;
    settings.labelMode = valueLabelMode;
    settings.showLabelsOnlyWhenOccupied = valueShowLabelsOnlyWhenOccupied;
    settings.colorizeIcons = valueColorizeIcons;
    return settings;
  }

  NToggle {
    label: I18n.tr("bar.widget-settings.workspace.hide-unoccupied.label")
    description: I18n.tr("bar.widget-settings.workspace.hide-unoccupied.description")
    checked: valueHideUnoccupied
    onToggled: checked => valueHideUnoccupied = checked
  }

  NComboBox {
    id: labelModeCombo
    label: I18n.tr("bar.widget-settings.workspace.label-mode.label")
    description: I18n.tr("bar.widget-settings.workspace.label-mode.description")
    model: [
      {
        "key": "none",
        "name": I18n.tr("options.workspace-labels.none")
      },
      {
        "key": "index",
        "name": I18n.tr("options.workspace-labels.index")
      },
      {
        "key": "name",
        "name": I18n.tr("options.workspace-labels.name")
      },
      {
        "key": "index+name",
        "name": I18n.tr("options.workspace-labels.index+name")
      }
    ]
    currentKey: widgetData.labelMode
    onSelected: key => valueLabelMode = key
    minimumWidth: 200
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.taskbar-grouped.show-labels-only-when-occupied.label")
    description: I18n.tr("bar.widget-settings.taskbar-grouped.show-labels-only-when-occupied.description")
    checked: root.valueShowLabelsOnlyWhenOccupied
    onToggled: checked => root.valueShowLabelsOnlyWhenOccupied = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.active-window.colorize-icons.label")
    description: I18n.tr("bar.widget-settings.active-window.colorize-icons.description")
    checked: root.valueColorizeIcons
    onToggled: checked => root.valueColorizeIcons = checked
  }
}
