pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.Commons


/**
 * SystemTrayService
 * This service ensures that Quickshell's SystemTray service is initialized
 * early in the shell startup to avoid programs that should stay in tray, not having access to one (let's hope this works).
 */
Singleton {
  id: root

  property bool initialized: false

  Component.onCompleted: {
    if (SystemTray && SystemTray.items) {
      Logger.i("SystemTrayService", "SystemTray service initialized")
      initialized = true

      // Monitor for tray items to confirm it's working
      if (SystemTray.items.valuesChanged) {
        Logger.d("SystemTrayService", "SystemTray is ready and monitoring for items")
      }
    } else {
      Logger.w("SystemTrayService", "SystemTray service not available")
    }
  }

  function init() {
    // Explicit initialization function
    if (!initialized && SystemTray && SystemTray.items) {
      Logger.i("SystemTrayService", "SystemTray service initialized via init()")
      initialized = true
    }
  }
}
