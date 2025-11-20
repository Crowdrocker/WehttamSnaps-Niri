import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Services.Keyboard

// MangoService integrates with MangoWC compositor using mmsg IPC commands
// for real-time window management, workspace control, and state monitoring
Item {
  id: root

  // Facade interface properties
  property ListModel workspaces: ListModel {}
  property var windows: []
  property int focusedWindowIndex: -1

  // Facade interface signals
  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged
  signal displayScalesChanged

  // MangoWC-specific state
  property bool initialized: false
  property bool overviewActive: false
  property var workspaceCache: ({}) // Cache for workspace data to detect changes
  property var windowCache: ({}) // Cache for window data to detect changes
  property var monitorCache: ({}) // Cache for monitor/scale data
  property string currentLayout: "" // Current layout name
  property string currentLayoutSymbol: "" // Current layout symbol (e.g., 'S' for scroller)
  property string currentKeyboardLayout: "" // Current keyboard layout name
  property string selectedMonitor: "" // Currently selected/focused monitor

  // mmsg command templates for MangoWC IPC (mmsg is the MangoWC message interface)
  readonly property var mmsgCommands: ({
                                         "query": {
                                           "workspaces": ["mmsg", "-g", "-t"],
                                           "windows": ["mmsg", "-g", "-c"],
                                           "layout": ["mmsg", "-g", "-l"],
                                           "keyboard": ["mmsg", "-g", "-k"],
                                           "outputs": ["mmsg", "-g", "-A"],
                                           "monitors": ["mmsg", "-g", "-o"],
                                           "eventStream": ["mmsg", "-w"]
                                         },
                                         "action": {
                                           "view": ["mmsg", "-s", "-d", "view"],
                                           "tag": ["mmsg", "-s", "-t"],
                                           "focusMaster": ["mmsg", "-s", "-d", "focusmaster"],
                                           "killClient": ["mmsg", "-s", "-d", "killclient"],
                                           "toggleOverview": ["mmsg", "-s", "-d", "toggleoverview"],
                                           "setLayout": ["mmsg", "-s", "-d", "setlayout"],
                                           "quit": ["mmsg", "-s", "-q"]
                                         }
                                       })

  readonly property string overviewLayoutSymbol: "󰃇" // Symbol representing overview layout
  readonly property int defaultWorkspaceId: 1 // Default workspace ID when none specified

  // Debounce timer for rapid state changes to avoid excessive updates
  Timer {
    id: updateTimer
    interval: 50
    repeat: false
    onTriggered: safeUpdate()
  }

  // Event stream process for real-time MangoWC state monitoring using mmsg -w
  // Monitors events: workspace changes, window focus/movement, layout changes, monitor selection
  Process {
    id: eventStream
    running: false
    command: mmsgCommands.query.eventStream

    stdout: SplitParser {
      onRead: function (line) {
        try {
          handleEvent(line.trim())
        } catch (e) {
          Logger.e("MangoService", "Event parsing error:", e, line)
        }
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0) {
        Logger.e("MangoService", "Event stream exited, restarting...")
        restartTimer.start()
      }
    }
  }

  // Restart timer for event stream recovery on failure
  Timer {
    id: restartTimer
    interval: 1000
    onTriggered: {
      if (initialized) {
        eventStream.running = true
      }
    }
  }

  // Process to query workspaces using mmsg -g -t
  Process {
    id: workspacesProcess
    running: false
    command: mmsgCommands.query.workspaces
    property string accumulatedOutput: ""

    stdout: SplitParser {
      onRead: function (line) {
        workspacesProcess.accumulatedOutput += line + "\n"
      }
    }

    onExited: function (exitCode) {
      if (exitCode === 0) {
        parseWorkspaces(accumulatedOutput)
      } else {
        Logger.e("MangoService", "Workspaces query failed:", exitCode)
      }
      accumulatedOutput = ""
    }
  }

  // Process to query windows using mmsg -g -c
  Process {
    id: windowsProcess
    running: false
    command: mmsgCommands.query.windows
    property string accumulatedOutput: ""
    property var currentWindow: ({})

    onRunningChanged: {
      if (running) {
        windowsProcess.currentWindow = {}
      }
    }

    stdout: SplitParser {
      onRead: function (line) {
        const trimmed = line.trim()
        if (!trimmed)
          return

        const parts = trimmed.split(' ')
        if (parts.length >= 3) {
          const outputName = parts[0]
          const property = parts[1]
          const value = parts.slice(2).join(' ')

          if (!windowsProcess.currentWindow[outputName]) {
            windowsProcess.currentWindow[outputName] = {
              "id": outputName,
              "output": outputName
            }
          }

          switch (property) {
          case "title":
            windowsProcess.currentWindow[outputName].title = value
            break
          case "appid":
            windowsProcess.currentWindow[outputName].appId = value
            windowsProcess.currentWindow[outputName].class = value
            break
          case "fullscreen":
            windowsProcess.currentWindow[outputName].fullscreen = (value === "1")
            break
          case "floating":
            windowsProcess.currentWindow[outputName].floating = (value === "1")
            break
          case "x":
            windowsProcess.currentWindow[outputName].x = parseInt(value)
            break
          case "y":
            windowsProcess.currentWindow[outputName].y = parseInt(value)
            break
          case "width":
            windowsProcess.currentWindow[outputName].width = parseInt(value)
            break
          case "height":
            windowsProcess.currentWindow[outputName].height = parseInt(value)
            break
          }
        }
      }
    }

    onExited: function (exitCode) {
      if (exitCode === 0) {
        parseWindows(windowsProcess.currentWindow)
      } else {
        Logger.e("MangoService", "Windows query failed:", exitCode)
      }
      accumulatedOutput = ""
      windowsProcess.currentWindow = {}
    }
  }

  // Process to query current layout using mmsg -g -l
  Process {
    id: layoutProcess
    running: false
    command: mmsgCommands.query.layout

    stdout: SplitParser {
      onRead: function (line) {
        try {
          const parts = line.trim().split(/\s+/)
          if (parts.length >= 2) {
            const layoutSymbol = parts.slice(1).join(' ')
            handleLayoutChange(layoutSymbol)
          }
        } catch (e) {
          Logger.e("MangoService", "Layout parsing error:", e, line)
        }
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0) {
        Logger.e("MangoService", "Layout query failed:", exitCode)
      }
    }
  }

  // Process to query keyboard layout using mmsg -g -k
  Process {
    id: keyboardProcess
    running: false
    command: mmsgCommands.query.keyboard

    stdout: SplitParser {
      onRead: function (line) {
        try {
          const parts = line.trim().split(/\s+/)
          if (parts.length >= 2 && parts[1] === "kb_layout") {
            const layoutName = parts.slice(2).join(' ')
            if (layoutName && layoutName !== currentKeyboardLayout) {
              currentKeyboardLayout = layoutName
              KeyboardLayoutService.setCurrentLayout(layoutName)
            }
          }
        } catch (e) {
          Logger.e("MangoService", "Keyboard layout parsing error:", e, line)
        }
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0) {
        Logger.e("MangoService", "Keyboard query failed:", exitCode)
      }
    }
  }

  // Process to query output scales using mmsg -g -A
  Process {
    id: outputsProcess
    running: false
    command: mmsgCommands.query.outputs

    stdout: SplitParser {
      onRead: function (line) {
        try {
          const parts = line.trim().split(/\s+/)
          if (parts.length >= 3 && parts[1] === "scale_factor") {
            const outputName = parts[0]
            const scaleFactor = parseFloat(parts[2])

            if (!monitorCache[outputName]) {
              monitorCache[outputName] = {}
            }

            monitorCache[outputName].scale = scaleFactor
            monitorCache[outputName].name = outputName
          }
        } catch (e) {
          Logger.e("MangoService", "Output parsing error:", e, line)
        }
      }
    }

    onExited: function (exitCode) {
      if (exitCode === 0) {
        updateDisplayScales()
      } else {
        Logger.e("MangoService", "Outputs query failed:", exitCode)
      }
    }
  }

  // Process to query monitor states using mmsg -g -o
  Process {
    id: monitorStateProcess
    running: false
    command: mmsgCommands.query.monitors

    stdout: SplitParser {
      onRead: function (line) {
        try {
          const parts = line.trim().split(/\s+/)
          if (parts.length >= 3 && parts[1] === "selmon") {
            const outputName = parts[0]
            const isSelected = parts[2] === "1"
            if (isSelected) {
              selectedMonitor = outputName
              Logger.d("MangoService", `Initial selected monitor: ${outputName}`)
            }
          }
        } catch (e) {
          Logger.e("MangoService", "Monitor state parsing error:", e, line)
        }
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0) {
        Logger.e("MangoService", "Monitor state query failed:", exitCode)
      }
    }
  }

  // Process to enumerate available outputs using mmsg -g -O
  Process {
    id: outputEnumProcess
    running: false
    command: ["mmsg", "-g", "-O"]

    stdout: SplitParser {
      onRead: function (line) {
        try {
          const trimmed = line.trim()

          const outputName = trimmed.replace(/^\+\s*/, '')
          if (outputName && !monitorCache[outputName]) {
            monitorCache[outputName] = {
              "name": outputName,
              "scale": 1.0,
              "active": false,
              "focused": false
            }
          }
        } catch (e) {
          Logger.e("MangoService", "Output enumeration error:", e, line)
        }
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0) {
        Logger.e("MangoService", "Output enumeration failed:", exitCode)
      }
    }
  }

  // Initialize MangoService and establish connection to MangoWC
  function initialize() {
    if (initialized) {
      Logger.w("MangoService", "Already initialized")
      return
    }

    try {
      Logger.i("MangoService", "Service started")

      queryOutputEnum()
      queryMonitorState()
      eventStream.running = true
      queryWorkspaces()
      queryWindows()
      queryLayout()
      queryKeyboard()
      queryOutputs()

      initialized = true
      Logger.i("MangoService", "Service initialized successfully")
    } catch (e) {
      Logger.e("MangoService", "Initialization failed:", e)
      eventStream.running = true
    }
  }

  // Switch to a specific workspace/tag
  function switchToWorkspace(workspace) {
    try {
      const tagId = workspace.idx || workspace.id || defaultWorkspaceId
      const outputName = workspace.output || selectedMonitor || ""
      let command = mmsgCommands.action.tag.slice()

      // Only add -o parameter for multi-monitor setups
      if (outputName && Object.keys(monitorCache).length > 1) {
        command.push("-o", outputName)
      }
      command.push(tagId.toString())

      Quickshell.execDetached(command)
    } catch (e) {
      Logger.e("MangoService", "Failed to switch workspace:", e)
    }
  }

  // Focus a specific window on its workspace
  function focusWindow(window) {
    try {
      if (window && window.output) {
        let command = mmsgCommands.action.view.slice()
        const isMultiMonitor = Object.keys(monitorCache).length > 1

        if (isMultiMonitor) {
          command.push("-o", window.output)
        }
        command.push(window.workspaceId.toString())
        Quickshell.execDetached(command)

        Qt.callLater(() => {
                       let focusCommand = mmsgCommands.action.focusMaster.slice()
                       if (isMultiMonitor) {
                         focusCommand.push("-o", window.output)
                       }
                       Quickshell.execDetached(focusCommand)
                     })
      }
    } catch (e) {
      Logger.e("MangoService", "Failed to focus window:", e)
    }
  }

  function closeWindow(window) {
    try {
      const command = mmsgCommands.action.killClient.slice()
      if (selectedMonitor && Object.keys(monitorCache).length > 1) {
        command.push("-o", selectedMonitor)
      }
      Quickshell.execDetached(command)
    } catch (e) {
      Logger.e("MangoService", "Failed to close window:", e)
    }
  }

  function toggleOverview() {
    try {
      const command = mmsgCommands.action.toggleOverview.slice()
      if (selectedMonitor && Object.keys(monitorCache).length > 1) {
        command.push("-o", selectedMonitor)
      }
      Quickshell.execDetached(command)
    } catch (e) {
      Logger.e("MangoService", "Failed to toggle overview:", e)
    }
  }

  function setLayout(layoutName) {
    try {
      const command = mmsgCommands.action.setLayout.slice()
      command.push(layoutName)
      Quickshell.execDetached(command)
    } catch (e) {
      Logger.e("MangoService", "Failed to set layout:", e)
    }
  }

  function logout() {
    try {
      Quickshell.execDetached(mmsgCommands.action.quit)
    } catch (e) {
      Logger.e("MangoService", "Failed to logout:", e)
    }
  }

  // Parse workspace data from mmsg -g -t output
  // Handles formats: tag details, tag masks, and binary states
  // State bits: bit 0 = active/selected, bit 1 = urgent
  function parseWorkspaces(output) {
    const lines = output.trim().split('\n')
    const workspacesList = []
    const newWorkspaceCache = {}
    let outputClients = {}

    for (const line of lines) {
      const trimmed = line.trim()
      if (!trimmed)
        continue

      const tagMatch = trimmed.match(/^(\S+)\s+tag\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/)
      if (tagMatch) {
        const outputName = tagMatch[1]
        const tagNum = tagMatch[2]
        const state = tagMatch[3]
        const clients = tagMatch[4]
        const focused = tagMatch[5]
        const tagId = parseInt(tagNum)

        const isActive = (parseInt(state) & 1) !== 0
        const isUrgent = (parseInt(state) & 2) !== 0
        const isOccupied = parseInt(clients) > 0
        const isFocused = isActive && parseInt(focused) === 1

        if (!outputClients[outputName]) {
          outputClients[outputName] = 0
        }

        const workspaceData = {
          "id": tagId,
          "idx": tagId,
          "name": tagId.toString(),
          "output": outputName,
          "isActive": isActive,
          "isFocused": isFocused || (isActive && (outputName === selectedMonitor)),
          "isUrgent": isUrgent,
          "isOccupied": isOccupied,
          "clients": parseInt(clients)
        }

        newWorkspaceCache[`${outputName}-${tagId}`] = workspaceData
        workspacesList.push(workspaceData)
      }

      const clientsMatch = trimmed.match(/^(\S+)\s+clients\s+(\d+)$/)
      if (clientsMatch) {
        const outputName = clientsMatch[1]
        const clientCount = clientsMatch[2]
        outputClients[outputName] = parseInt(clientCount)
      }

      const tagsMatch = trimmed.match(/^(\S+)\s+tags\s+(\d+)\s+(\d+)\s+(\d+)$/)
      if (tagsMatch) {
        const outputName = tagsMatch[1]
        const occ = tagsMatch[2]
        const seltags = tagsMatch[3]
        const urg = tagsMatch[4]

        const occBits = occ.padStart(9, '0')
        const selBits = seltags.padStart(9, '0')
        const urgBits = urg.padStart(9, '0')

        for (var i = 0; i < 9; i++) {
          const tagId = i + 1
          const isActive = selBits[8 - i] === '1'
          const isUrgent = urgBits[8 - i] === '1'
          const isOccupied = occBits[8 - i] === '1'

          const workspaceData = {
            "id": tagId,
            "idx": tagId,
            "name": tagId.toString(),
            "output": outputName,
            "isActive": isActive,
            "isFocused": false,
            "isUrgent"// Will be determined by selected monitor
            : isUrgent,
            "isOccupied": isOccupied,
            "clients": 0 // Will be updated by tag-specific data
          }

          const key = `${outputName}-${tagId}`
          if (!newWorkspaceCache[key]) {
            newWorkspaceCache[key] = workspaceData
            workspacesList.push(workspaceData)
          }
        }
      }

      const layoutMatch = trimmed.match(/^(\S+)\s+layout\s+(\S+)$/)
      if (layoutMatch) {
        const layoutSymbol = layoutMatch[2]
        handleLayoutChange(layoutSymbol)
      }
    }

    if (JSON.stringify(newWorkspaceCache) !== JSON.stringify(workspaceCache)) {
      workspaceCache = newWorkspaceCache

      workspacesList.sort((a, b) => {
                            if (a.id !== b.id)
                            return a.id - b.id
                            return a.output.localeCompare(b.output)
                          })

      workspaces.clear()
      for (var i = 0; i < workspacesList.length; i++) {
        workspaces.append(workspacesList[i])
      }

      workspaceChanged()
    }
  }

  // Parse window data from mmsg -g -c output into window list
  function parseWindows(windowData) {
    const windowsList = []
    const newWindowCache = {}
    let newFocusedIndex = -1

    const windowEntries = Object.entries(windowData)
    for (var i = 0; i < windowEntries.length; i++) {
      const outputName = windowEntries[i][0]
      const data = windowEntries[i][1]
      if (data.title || data.appId) {

        const isFocused = (outputName === selectedMonitor)

        let activeTagId = defaultWorkspaceId
        const workspaceEntries = Object.entries(workspaceCache)
        for (var j = 0; j < workspaceEntries.length; j++) {
          const key = workspaceEntries[j][0]
          const tagData = workspaceEntries[j][1]
          if (tagData.output === outputName && tagData.isActive) {
            activeTagId = tagData.id
            break
          }
        }

        const windowInfo = {
          "id": `${outputName}-${data.appId || 'unknown'}`,
          "title": data.title || "",
          "appId": data.appId || "",
          "class": data.appId || "",
          "workspaceId": activeTagId,
          "isFocused": isFocused,
          "output": outputName,
          "fullscreen": data.fullscreen || false,
          "floating": data.floating || false,
          "x": data.x || 0,
          "y": data.y || 0,
          "width": data.width || 0,
          "height": data.height || 0,
          "geometry": {
            "x": data.x || 0,
            "y": data.y || 0,
            "width": data.width || 0,
            "height": data.height || 0
          }
        }

        windowsList.push(windowInfo)
        newWindowCache[windowInfo.id] = windowInfo

        if (isFocused) {
          newFocusedIndex = windowsList.length - 1
          Logger.d("MangoService", `Focused window detected: ${data.title} on ${outputName}`)
        }
      }
    }

    if (JSON.stringify(newWindowCache) !== JSON.stringify(windowCache)) {
      windowCache = newWindowCache
      windows = windowsList

      if (newFocusedIndex !== focusedWindowIndex) {
        focusedWindowIndex = newFocusedIndex
        activeWindowChanged()
      }

      windowListChanged()
    }
  }

  // Handle layout change events and update overview state
  function handleLayoutChange(layoutSymbol) {
    const wasOverview = overviewActive
    const isOverview = (layoutSymbol === overviewLayoutSymbol)

    if (wasOverview !== isOverview) {
      overviewActive = isOverview
      Logger.d("MangoService", `Overview mode: ${overviewActive}`)
    }

    if (layoutSymbol !== currentLayoutSymbol) {
      currentLayoutSymbol = layoutSymbol
      currentLayout = layoutSymbol
    }
  }

  // Update display scales and notify CompositorService
  function updateDisplayScales() {
    const scales = {}
    const monitorEntries = Object.entries(monitorCache)
    for (var i = 0; i < monitorEntries.length; i++) {
      const outputName = monitorEntries[i][0]
      const data = monitorEntries[i][1]
      scales[outputName] = {
        "name": data.name || outputName,
        "scale": data.scale || 1.0,
        "width": data.width || 0,
        "height": data.height || 0,
        "refresh_rate": data.refresh_rate || 0,
        "x": data.x || 0,
        "y": data.y || 0,
        "active": data.active || false,
        "focused": data.focused || false
      }
    }

    if (CompositorService && CompositorService.onDisplayScalesUpdated) {
      CompositorService.onDisplayScalesUpdated(scales)
    }
    displayScalesChanged()
  }

  // Handle real-time events from mmsg -w event stream and trigger updates
  function handleEvent(eventLine) {
    const parts = eventLine.trim().split(/\s+/)
    if (parts.length < 2)
      return

    const eventType = parts[1]

    switch (eventType) {
    case "selmon":
      if (parts.length >= 3) {
        const monitorName = parts[0]
        const isSelected = parts[2] === "1"
        if (isSelected) {
          selectedMonitor = monitorName
          Logger.d("MangoService", `Selected monitor changed to: ${monitorName}`)
        }
      }
      updateTimer.restart()
      break
    case "tag":
    case "title":
    case "appid":
    case "fullscreen":
    case "floating":
    case "layout":
    case "kb_layout":
    case "scale_factor":
    case "toggle":
    case "last_layer":
    case "keymode":
    case "clients":
    case "tags":
      updateTimer.restart()
      break
    }
  }

  // Start workspace query process
  function queryWorkspaces() {
    workspacesProcess.running = true
  }

  // Start window query process
  function queryWindows() {
    windowsProcess.running = true
  }

  // Start layout query process
  function queryLayout() {
    layoutProcess.running = true
  }

  // Start keyboard layout query process
  function queryKeyboard() {
    keyboardProcess.running = true
  }

  // Start output scales query process
  function queryOutputs() {
    outputsProcess.running = true
  }

  // Query display scales (alias for queryOutputs)
  function queryDisplayScales() {
    queryOutputs()
  }

  // Start output enumeration process
  function queryOutputEnum() {
    outputEnumProcess.running = true
  }

  // Start monitor state query process
  function queryMonitorState() {
    monitorStateProcess.running = true
  }

  // Safely update all state by querying workspaces, windows, and monitor state
  function safeUpdate() {
    try {
      queryWorkspaces()
      queryWindows()
      queryMonitorState()
    } catch (e) {
      Logger.e("MangoService", "Safe update failed:", e)
    }
  }

  // Get the ID of the currently active workspace/tag
  function getCurrentActiveTagId() {
    const workspaceEntries1 = Object.entries(workspaceCache)
    for (var i = 0; i < workspaceEntries1.length; i++) {
      const key = workspaceEntries1[i][0]
      const tagData = workspaceEntries1[i][1]
      if (tagData.isActive && tagData.output === selectedMonitor) {
        return tagData.id
      }
    }

    const workspaceEntries2 = Object.entries(workspaceCache)
    for (var i = 0; i < workspaceEntries2.length; i++) {
      const key = workspaceEntries2[i][0]
      const tagData = workspaceEntries2[i][1]
      if (tagData.isActive) {
        return tagData.id
      }
    }
    return defaultWorkspaceId
  }
}
