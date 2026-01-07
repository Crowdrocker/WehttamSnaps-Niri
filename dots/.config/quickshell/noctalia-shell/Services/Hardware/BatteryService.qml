pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  // Choose icon based on charge and charging state
  function getIcon(percent, charging, isReady) {
    if (!isReady) {
      return "battery-exclamation";
    }

    if (charging) {
      return "battery-charging";
    } else {
      if (percent >= 90)
        return "battery-4";
      if (percent >= 50)
        return "battery-3";
      if (percent >= 25)
        return "battery-2";
      if (percent >= 0)
        return "battery-1";
      return "battery";
    }
  }
}
