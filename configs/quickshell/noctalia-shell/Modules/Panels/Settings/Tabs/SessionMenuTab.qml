import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root

  spacing: Style.marginL

  property list<var> entriesModel: []
  property list<var> entriesDefault: [{
      "id": "lock",
      "text": I18n.tr("session-menu.lock"),
      "enabled": true,
      "required": false
    }, {
      "id": "suspend",
      "text": I18n.tr("session-menu.suspend"),
      "enabled": true,
      "required": false
    }, {
      "id": "reboot",
      "text": I18n.tr("session-menu.reboot"),
      "enabled": true,
      "required": false
    }, {
      "id": "logout",
      "text": I18n.tr("session-menu.logout"),
      "enabled": true,
      "required": false
    }, {
      "id": "shutdown",
      "text": I18n.tr("session-menu.shutdown"),
      "enabled": true,
      "required": false
    }]

  // Handler for drag start - disables panel background clicks
  function handleDragStart() {
    var currentScreen = Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    if (currentScreen) {
      var panel = PanelService.getPanel("settingsPanel", currentScreen)
      if (panel && panel.disableBackgroundClick) {
        panel.disableBackgroundClick()
      }
    }
  }

  // Handler for drag end - re-enables panel background clicks
  function handleDragEnd() {
    var currentScreen = Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    if (currentScreen) {
      var panel = PanelService.getPanel("settingsPanel", currentScreen)
      if (panel && panel.enableBackgroundClick) {
        panel.enableBackgroundClick()
      }
    }
  }

  function saveEntries() {
    var toSave = []
    for (var i = 0; i < entriesModel.length; i++) {
      toSave.push({
                    "action": entriesModel[i].id,
                    "enabled": entriesModel[i].enabled
                  })
    }
    Settings.data.sessionMenu.powerOptions = toSave
  }

  Component.onCompleted: {
    entriesModel = []

    // Add the entries available in settings
    for (var i = 0; i < Settings.data.sessionMenu.powerOptions.length; i++) {
      const settingEntry = Settings.data.sessionMenu.powerOptions[i]

      for (var j = 0; j < entriesDefault.length; j++) {
        if (settingEntry.action === entriesDefault[j].id) {
          var entry = entriesDefault[j]
          entry.enabled = settingEntry.enabled
          entriesModel.push(entry)
        }
      }
    }

    // Add any missing entries from default
    for (var i = 0; i < entriesDefault.length; i++) {
      var found = false
      for (var j = 0; j < entriesModel.length; j++) {
        if (entriesModel[j].id === entriesDefault[i].id) {
          found = true
          break
        }
      }

      if (!found) {
        var entry = entriesDefault[i]
        entriesModel.push(entry)
      }
    }

    saveEntries()
  }

  NHeader {
    label: I18n.tr("settings.session-menu.general.section.label")
    description: I18n.tr("settings.session-menu.general.section.description")
  }

  NComboBox {
    label: I18n.tr("settings.session-menu.position.label")
    description: I18n.tr("settings.session-menu.position.description")
    Layout.fillWidth: true
    model: [{
        "key": "center",
        "name": I18n.tr("options.control-center.position.center")
      }, {
        "key": "top_center",
        "name": I18n.tr("options.control-center.position.top_center")
      }, {
        "key": "top_left",
        "name": I18n.tr("options.control-center.position.top_left")
      }, {
        "key": "top_right",
        "name": I18n.tr("options.control-center.position.top_right")
      }, {
        "key": "bottom_center",
        "name": I18n.tr("options.control-center.position.bottom_center")
      }, {
        "key": "bottom_left",
        "name": I18n.tr("options.control-center.position.bottom_left")
      }, {
        "key": "bottom_right",
        "name": I18n.tr("options.control-center.position.bottom_right")
      }]
    currentKey: Settings.data.sessionMenu.position
    onSelected: function (key) {
      Settings.data.sessionMenu.position = key
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("settings.session-menu.show-header.label")
    description: I18n.tr("settings.session-menu.show-header.description")
    checked: Settings.data.sessionMenu.showHeader
    onToggled: checked => Settings.data.sessionMenu.showHeader = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("settings.session-menu.enable-countdown.label")
    description: I18n.tr("settings.session-menu.enable-countdown.description")
    checked: Settings.data.sessionMenu.enableCountdown
    onToggled: checked => Settings.data.sessionMenu.enableCountdown = checked
  }

  ColumnLayout {
    visible: Settings.data.sessionMenu.enableCountdown
    spacing: Style.marginXXS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("settings.session-menu.countdown-duration.label")
      description: I18n.tr("settings.session-menu.countdown-duration.description")
    }

    NValueSlider {
      Layout.fillWidth: true
      from: 1000
      to: 30000
      stepSize: 1000
      value: Settings.data.sessionMenu.countdownDuration
      onMoved: value => Settings.data.sessionMenu.countdownDuration = value
      text: Math.round(Settings.data.sessionMenu.countdownDuration / 1000) + "s"
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL
  }

  // Entries Management Section
  ColumnLayout {
    spacing: Style.marginXXS
    Layout.fillWidth: true

    NHeader {
      label: I18n.tr("settings.session-menu.entries.section.label")
      description: I18n.tr("settings.session-menu.entries.section.description")
    }

    NReorderCheckboxes {
      Layout.fillWidth: true
      model: entriesModel
      disabledIds: []
      onDragPotentialStarted: {
        root.handleDragStart()
      }
      onDragPotentialEnded: {
        root.handleDragEnd()
      }
      onItemToggled: function (index, enabled) {
        var newModel = entriesModel.slice()
        newModel[index] = Object.assign({}, newModel[index], {
                                          "enabled": enabled
                                        })
        entriesModel = newModel
        saveEntries()
      }
      onItemsReordered: function (fromIndex, toIndex) {
        var newModel = entriesModel.slice()
        var item = newModel.splice(fromIndex, 1)[0]
        newModel.splice(toIndex, 0, item)
        entriesModel = newModel
        saveEntries()
      }
    }
  }
}
