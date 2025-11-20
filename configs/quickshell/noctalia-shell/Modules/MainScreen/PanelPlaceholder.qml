import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI


/**
 * PanelPlaceholder - Lightweight positioning logic for panel backgrounds
 *
 * This component stays in MainScreen and provides geometry for PanelBackground rendering.
 * It contains only positioning calculations and animations, no visual content.
 * The actual panel content lives in a separate SmartPanelWindow.
 */
Item {
  id: root

  // Required properties
  required property ShellScreen screen
  required property string panelName
  // Unique identifier

  // Panel size properties
  property real preferredWidth: 700
  property real preferredHeight: 900
  property real preferredWidthRatio
  property real preferredHeightRatio
  property var buttonItem: null
  property bool forceAttachToBar: false

  // Anchoring properties
  property bool panelAnchorHorizontalCenter: false
  property bool panelAnchorVerticalCenter: false
  property bool panelAnchorTop: false
  property bool panelAnchorBottom: false
  property bool panelAnchorLeft: false
  property bool panelAnchorRight: false

  // Button position properties
  property bool useButtonPosition: false
  property point buttonPosition: Qt.point(0, 0)
  property int buttonWidth: 0
  property int buttonHeight: 0

  // Edge snapping distance
  property real edgeSnapDistance: 50

  // State tracking (controlled by SmartPanelWindow)
  property bool isPanelVisible: false
  property bool isClosing: false
  property bool opacityFadeComplete: false

  // Content size (set by SmartPanelWindow when content size changes)
  property real contentPreferredWidth: 0
  property real contentPreferredHeight: 0

  // Expose panelBackground as panelItem for AllBackgrounds
  readonly property var panelItem: panelBackground

  // Bar configuration
  readonly property string barPosition: Settings.data.bar.position
  readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"
  readonly property bool barFloating: Settings.data.bar.floating
  readonly property real barMarginH: barFloating ? Settings.data.bar.marginHorizontal * Style.marginXL : 0
  readonly property real barMarginV: barFloating ? Settings.data.bar.marginVertical * Style.marginXL : 0

  // Helper to detect if any anchor is explicitly set
  readonly property bool hasExplicitHorizontalAnchor: panelAnchorHorizontalCenter || panelAnchorLeft || panelAnchorRight
  readonly property bool hasExplicitVerticalAnchor: panelAnchorVerticalCenter || panelAnchorTop || panelAnchorBottom

  // Attachment properties
  readonly property bool allowAttach: Settings.data.ui.panelsAttachedToBar || root.forceAttachToBar
  readonly property bool allowAttachToBar: {
    if (!(Settings.data.ui.panelsAttachedToBar || root.forceAttachToBar) || Settings.data.bar.backgroundOpacity < 1.0) {
      return false
    }

    // A panel can only be attached to a bar if there is a bar on that screen
    var monitors = Settings.data.bar.monitors || []
    var result = monitors.length === 0 || monitors.includes(root.screen?.name || "")
    return result
  }

  // Effective anchor properties (depend on allowAttach)
  readonly property bool effectivePanelAnchorTop: panelAnchorTop || (useButtonPosition && barPosition === "top") || (allowAttach && !hasExplicitVerticalAnchor && barPosition === "top" && !barIsVertical)
  readonly property bool effectivePanelAnchorBottom: panelAnchorBottom || (useButtonPosition && barPosition === "bottom") || (allowAttach && !hasExplicitVerticalAnchor && barPosition === "bottom" && !barIsVertical)
  readonly property bool effectivePanelAnchorLeft: panelAnchorLeft || (useButtonPosition && barPosition === "left") || (allowAttach && !hasExplicitHorizontalAnchor && barPosition === "left" && barIsVertical)
  readonly property bool effectivePanelAnchorRight: panelAnchorRight || (useButtonPosition && barPosition === "right") || (allowAttach && !hasExplicitHorizontalAnchor && barPosition === "right" && barIsVertical)

  // Panel dimensions and visibility
  visible: isPanelVisible
  width: parent ? parent.width : 0
  height: parent ? parent.height : 0

  // Update position when UI scale changes
  Connections {
    target: Style

    function onUiScaleRatioChanged() {
      if (root.isPanelVisible) {
        root.setPosition()
      }
    }
  }

  // Public function to update content size from SmartPanelWindow
  function updateContentSize(w, h) {
    contentPreferredWidth = w
    contentPreferredHeight = h
    if (isPanelVisible) {
      setPosition()
    }
  }

  // Main positioning calculation function
  function setPosition() {
    // Don't calculate position if parent dimensions aren't available yet
    if (!root.width || !root.height) {
      Logger.d("PanelPlaceholder", "Skipping setPosition - dimensions not ready:", root.width, "x", root.height, panelName)
      Qt.callLater(setPosition)
      return
    }

    // Calculate panel dimensions first (needed for positioning)
    var w
    // Priority 1: Content-driven size (dynamic)
    if (contentPreferredWidth > 0) {
      w = contentPreferredWidth
    } // Priority 2: Ratio-based size
    else if (root.preferredWidthRatio !== undefined) {
      w = Math.round(Math.max(root.width * root.preferredWidthRatio, root.preferredWidth))
    } // Priority 3: Static preferred width
    else {
      w = root.preferredWidth
    }
    var panelWidth = Math.min(w, root.width - Style.marginL * 2)

    var h
    // Priority 1: Content-driven size (dynamic)
    if (contentPreferredHeight > 0) {
      h = contentPreferredHeight
    } // Priority 2: Ratio-based size
    else if (root.preferredHeightRatio !== undefined) {
      h = Math.round(Math.max(root.height * root.preferredHeightRatio, root.preferredHeight))
    } // Priority 3: Static preferred height
    else {
      h = root.preferredHeight
    }
    var panelHeight = Math.min(h, root.height - Style.barHeight - Style.marginL * 2)

    // Update panelBackground target size (will be animated)
    panelBackground.targetWidth = panelWidth
    panelBackground.targetHeight = panelHeight

    // Calculate position
    var calculatedX
    var calculatedY

    // ===== X POSITIONING =====
    if (root.useButtonPosition && root.width > 0 && panelWidth > 0) {
      if (root.barIsVertical) {
        // For vertical bars
        if (allowAttach) {
          // Attached panels: align with bar edge (left or right side)
          if (root.barPosition === "left") {
            var leftBarEdge = root.barMarginH + Style.barHeight
            calculatedX = leftBarEdge
          } else {
            // right
            var rightBarEdge = root.width - root.barMarginH - Style.barHeight
            calculatedX = rightBarEdge - panelWidth
          }
        } else {
          // Detached panels: center on button X position
          var panelX = root.buttonPosition.x + root.buttonWidth / 2 - panelWidth / 2
          var minX = Style.marginL
          var maxX = root.width - panelWidth - Style.marginL

          // Account for vertical bar taking up space
          if (root.barPosition === "left") {
            minX = root.barMarginH + Style.barHeight + Style.marginL
          } else if (root.barPosition === "right") {
            maxX = root.width - root.barMarginH - Style.barHeight - panelWidth - Style.marginL
          }

          panelX = Math.max(minX, Math.min(panelX, maxX))
          calculatedX = panelX
        }
      } else {
        // For horizontal bars, center panel on button X position
        var panelX = root.buttonPosition.x + root.buttonWidth / 2 - panelWidth / 2
        if (allowAttach) {
          var cornerInset = root.barFloating ? Style.radiusL * 2 : 0
          var barLeftEdge = root.barMarginH + cornerInset
          var barRightEdge = root.width - root.barMarginH - cornerInset
          panelX = Math.max(barLeftEdge, Math.min(panelX, barRightEdge - panelWidth))
        } else {
          panelX = Math.max(Style.marginL, Math.min(panelX, root.width - panelWidth - Style.marginL))
        }
        calculatedX = panelX
      }
    } else {
      // Standard anchor positioning
      if (root.panelAnchorHorizontalCenter) {
        if (root.barIsVertical) {
          if (root.barPosition === "left") {
            var availableStart = root.barMarginH + Style.barHeight
            var availableWidth = root.width - availableStart
            calculatedX = availableStart + (availableWidth - panelWidth) / 2
          } else if (root.barPosition === "right") {
            var availableWidth = root.width - root.barMarginH - Style.barHeight
            calculatedX = (availableWidth - panelWidth) / 2
          } else {
            calculatedX = (root.width - panelWidth) / 2
          }
        } else {
          calculatedX = (root.width - panelWidth) / 2
        }
      } else if (root.effectivePanelAnchorRight) {
        if (allowAttach && root.barIsVertical && root.barPosition === "right") {
          var rightBarEdge = root.width - root.barMarginH - Style.barHeight
          calculatedX = rightBarEdge - panelWidth
        } else if (allowAttach) {
          // Account for corner inset when bar is floating, horizontal, AND panel is on same edge as bar
          var panelOnSameEdgeAsBar = (root.barPosition === "top" && root.effectivePanelAnchorTop) || (root.barPosition === "bottom" && root.effectivePanelAnchorBottom)
          if (!root.barIsVertical && root.barFloating && panelOnSameEdgeAsBar) {
            var rightCornerInset = Style.radiusL * 2
            calculatedX = root.width - root.barMarginH - rightCornerInset - panelWidth
          } else {
            calculatedX = root.width - panelWidth
          }
        } else {
          calculatedX = root.width - panelWidth - Style.marginL
        }
      } else if (root.effectivePanelAnchorLeft) {
        if (allowAttach && root.barIsVertical && root.barPosition === "left") {
          var leftBarEdge = root.barMarginH + Style.barHeight
          calculatedX = leftBarEdge
        } else if (allowAttach) {
          // Account for corner inset when bar is floating, horizontal, AND panel is on same edge as bar
          var panelOnSameEdgeAsBar = (root.barPosition === "top" && root.effectivePanelAnchorTop) || (root.barPosition === "bottom" && root.effectivePanelAnchorBottom)
          if (!root.barIsVertical && root.barFloating && panelOnSameEdgeAsBar) {
            var leftCornerInset = Style.radiusL * 2
            calculatedX = root.barMarginH + leftCornerInset
          } else {
            calculatedX = 0
          }
        } else {
          calculatedX = Style.marginL
        }
      } else {
        // No explicit anchor: default to centering on bar
        if (root.barIsVertical) {
          if (root.barPosition === "left") {
            var availableStart = root.barMarginH + Style.barHeight
            var availableWidth = root.width - availableStart - Style.marginL
            calculatedX = availableStart + (availableWidth - panelWidth) / 2
          } else {
            var availableWidth = root.width - root.barMarginH - Style.barHeight - Style.marginL
            calculatedX = Style.marginL + (availableWidth - panelWidth) / 2
          }
        } else {
          if (allowAttach) {
            var cornerInset = Style.radiusL + (root.barFloating ? Style.radiusL : 0)
            var barLeftEdge = root.barMarginH + cornerInset
            var barRightEdge = root.width - root.barMarginH - cornerInset
            var centeredX = (root.width - panelWidth) / 2
            calculatedX = Math.max(barLeftEdge, Math.min(centeredX, barRightEdge - panelWidth))
          } else {
            calculatedX = (root.width - panelWidth) / 2
          }
        }
      }
    }

    // Edge snapping for X
    if (allowAttach && !root.barFloating && root.width > 0 && panelWidth > 0) {
      var leftEdgePos = root.barMarginH
      if (root.barPosition === "left") {
        leftEdgePos = root.barMarginH + Style.barHeight
      }

      var rightEdgePos = root.width - root.barMarginH - panelWidth
      if (root.barPosition === "right") {
        rightEdgePos = root.width - root.barMarginH - Style.barHeight - panelWidth
      }

      // Only snap to left edge if panel is actually meant to be at left
      var shouldSnapToLeft = root.effectivePanelAnchorLeft || (!root.hasExplicitHorizontalAnchor && root.barPosition === "left")
      // Only snap to right edge if panel is actually meant to be at right
      var shouldSnapToRight = root.effectivePanelAnchorRight || (!root.hasExplicitHorizontalAnchor && root.barPosition === "right")

      if (shouldSnapToLeft && Math.abs(calculatedX - leftEdgePos) <= root.edgeSnapDistance) {
        calculatedX = leftEdgePos
      } else if (shouldSnapToRight && Math.abs(calculatedX - rightEdgePos) <= root.edgeSnapDistance) {
        calculatedX = rightEdgePos
      }
    }

    // ===== Y POSITIONING =====
    if (root.useButtonPosition && root.height > 0 && panelHeight > 0) {
      if (root.barPosition === "top") {
        var topBarEdge = root.barMarginV + Style.barHeight
        if (allowAttach) {
          calculatedY = topBarEdge
        } else {
          calculatedY = topBarEdge + Style.marginM
        }
      } else if (root.barPosition === "bottom") {
        var bottomBarEdge = root.height - root.barMarginV - Style.barHeight
        if (allowAttach) {
          calculatedY = bottomBarEdge - panelHeight
        } else {
          calculatedY = bottomBarEdge - panelHeight - Style.marginM
        }
      } else if (root.barIsVertical) {
        var panelY = root.buttonPosition.y + root.buttonHeight / 2 - panelHeight / 2
        var extraPadding = (allowAttach && root.barFloating) ? Style.radiusL : 0
        if (allowAttach) {
          var cornerInset = extraPadding + (root.barFloating ? Style.radiusL : 0)
          var barTopEdge = root.barMarginV + cornerInset
          var barBottomEdge = root.height - root.barMarginV - cornerInset
          panelY = Math.max(barTopEdge, Math.min(panelY, barBottomEdge - panelHeight))
        } else {
          panelY = Math.max(Style.marginL + extraPadding, Math.min(panelY, root.height - panelHeight - Style.marginL - extraPadding))
        }
        calculatedY = panelY
      }
    } else {
      // Standard anchor positioning
      var barOffset = 0
      if (!allowAttach) {
        if (root.barPosition === "top") {
          barOffset = root.barMarginV + Style.barHeight + Style.marginM
        } else if (root.barPosition === "bottom") {
          barOffset = root.barMarginV + Style.barHeight + Style.marginM
        }
      } else {
        if (root.effectivePanelAnchorTop && root.barPosition === "top") {
          calculatedY = root.barMarginV + Style.barHeight
        } else if (root.effectivePanelAnchorBottom && root.barPosition === "bottom") {
          calculatedY = root.height - root.barMarginV - Style.barHeight - panelHeight
        } else if (!root.hasExplicitVerticalAnchor) {
          if (root.barPosition === "top") {
            calculatedY = root.barMarginV + Style.barHeight
          } else if (root.barPosition === "bottom") {
            calculatedY = root.height - root.barMarginV - Style.barHeight - panelHeight
          }
        }
      }

      if (calculatedY === undefined) {
        if (root.panelAnchorVerticalCenter) {
          if (!root.barIsVertical) {
            if (root.barPosition === "top") {
              var availableStart = root.barMarginV + Style.barHeight
              var availableHeight = root.height - availableStart
              calculatedY = availableStart + (availableHeight - panelHeight) / 2
            } else if (root.barPosition === "bottom") {
              var availableHeight = root.height - root.barMarginV - Style.barHeight
              calculatedY = (availableHeight - panelHeight) / 2
            } else {
              calculatedY = (root.height - panelHeight) / 2
            }
          } else {
            calculatedY = (root.height - panelHeight) / 2
          }
        } else if (root.effectivePanelAnchorTop) {
          if (allowAttach) {
            calculatedY = 0
          } else {
            var topBarOffset = (root.barPosition === "top") ? barOffset : 0
            calculatedY = topBarOffset + Style.marginL
          }
        } else if (root.effectivePanelAnchorBottom) {
          if (allowAttach) {
            calculatedY = root.height - panelHeight
          } else {
            var bottomBarOffset = (root.barPosition === "bottom") ? barOffset : 0
            calculatedY = root.height - panelHeight - bottomBarOffset - Style.marginL
          }
        } else {
          if (root.barIsVertical) {
            if (allowAttach) {
              var cornerInset = root.barFloating ? Style.radiusL * 2 : 0
              var barTopEdge = root.barMarginV + cornerInset
              var barBottomEdge = root.height - root.barMarginV - cornerInset
              var centeredY = (root.height - panelHeight) / 2
              calculatedY = Math.max(barTopEdge, Math.min(centeredY, barBottomEdge - panelHeight))
            } else {
              calculatedY = (root.height - panelHeight) / 2
            }
          } else {
            if (allowAttach && !root.barIsVertical) {
              if (root.barPosition === "top") {
                calculatedY = root.barMarginV + Style.barHeight
              } else if (root.barPosition === "bottom") {
                calculatedY = root.height - root.barMarginV - Style.barHeight - panelHeight
              }
            } else {
              if (root.barPosition === "top") {
                calculatedY = barOffset + Style.marginL
              } else if (root.barPosition === "bottom") {
                calculatedY = Style.marginL
              } else {
                calculatedY = Style.marginL
              }
            }
          }
        }
      }
    }

    // Edge snapping for Y
    if (allowAttach && !root.barFloating && root.height > 0 && panelHeight > 0) {
      var topEdgePos = root.barMarginV
      if (root.barPosition === "top") {
        topEdgePos = root.barMarginV + Style.barHeight
      }

      var bottomEdgePos = root.height - root.barMarginV - panelHeight
      if (root.barPosition === "bottom") {
        bottomEdgePos = root.height - root.barMarginV - Style.barHeight - panelHeight
      }

      // Only snap to top edge if panel is actually meant to be at top
      var shouldSnapToTop = root.effectivePanelAnchorTop || (!root.hasExplicitVerticalAnchor && root.barPosition === "top")
      // Only snap to bottom edge if panel is actually meant to be at bottom
      var shouldSnapToBottom = root.effectivePanelAnchorBottom || (!root.hasExplicitVerticalAnchor && root.barPosition === "bottom")

      if (shouldSnapToTop && Math.abs(calculatedY - topEdgePos) <= root.edgeSnapDistance) {
        calculatedY = topEdgePos
      } else if (shouldSnapToBottom && Math.abs(calculatedY - bottomEdgePos) <= root.edgeSnapDistance) {
        calculatedY = bottomEdgePos
      }
    }

    // Apply calculated positions (set targets for animation)
    panelBackground.targetX = calculatedX
    panelBackground.targetY = calculatedY

    Logger.d("PanelPlaceholder", "Position calculated:", calculatedX, calculatedY, panelName)
    Logger.d("PanelPlaceholder", "  Panel size:", panelWidth, "x", panelHeight)
  }

  // The panel background geometry item
  Item {
    id: panelBackground

    // Store target dimensions (set by setPosition())
    property real targetWidth: root.preferredWidth
    property real targetHeight: root.preferredHeight
    property real targetX: 0
    property real targetY: 0

    property var bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]

    // Edge detection
    readonly property bool touchingLeftEdge: allowAttach && panelBackground.x <= 1
    readonly property bool touchingRightEdge: allowAttach && (panelBackground.x + panelBackground.width) >= (root.width - 1)
    readonly property bool touchingTopEdge: allowAttach && panelBackground.y <= 1
    readonly property bool touchingBottomEdge: allowAttach && (panelBackground.y + panelBackground.height) >= (root.height - 1)

    // Bar edge detection
    readonly property bool touchingTopBar: allowAttachToBar && root.barPosition === "top" && !root.barIsVertical && Math.abs(panelBackground.y - (root.barMarginV + Style.barHeight)) <= 1
    readonly property bool touchingBottomBar: allowAttachToBar && root.barPosition === "bottom" && !root.barIsVertical && Math.abs((panelBackground.y + panelBackground.height) - (root.height - root.barMarginV - Style.barHeight)) <= 1
    readonly property bool touchingLeftBar: allowAttachToBar && root.barPosition === "left" && root.barIsVertical && Math.abs(panelBackground.x - (root.barMarginH + Style.barHeight)) <= 1
    readonly property bool touchingRightBar: allowAttachToBar && root.barPosition === "right" && root.barIsVertical && Math.abs((panelBackground.x + panelBackground.width) - (root.width - root.barMarginH - Style.barHeight)) <= 1

    // Animation direction determination (using target position to avoid binding loops)
    readonly property bool willTouchTopBar: {
      if (!isPanelVisible)
        return false
      if (!allowAttachToBar || root.barPosition !== "top" || root.barIsVertical)
        return false
      var targetTopBarY = root.barMarginV + Style.barHeight
      return Math.abs(panelBackground.targetY - targetTopBarY) <= 1
    }
    readonly property bool willTouchBottomBar: {
      if (!isPanelVisible)
        return false
      if (!allowAttachToBar || root.barPosition !== "bottom" || root.barIsVertical)
        return false
      var targetBottomBarY = root.height - root.barMarginV - Style.barHeight - panelBackground.targetHeight
      return Math.abs(panelBackground.targetY - targetBottomBarY) <= 1
    }
    readonly property bool willTouchLeftBar: {
      if (!isPanelVisible)
        return false
      if (!allowAttachToBar || root.barPosition !== "left" || !root.barIsVertical)
        return false
      var targetLeftBarX = root.barMarginH + Style.barHeight
      return Math.abs(panelBackground.targetX - targetLeftBarX) <= 1
    }
    readonly property bool willTouchRightBar: {
      if (!isPanelVisible)
        return false
      if (!allowAttachToBar || root.barPosition !== "right" || !root.barIsVertical)
        return false
      var targetRightBarX = root.width - root.barMarginH - Style.barHeight - panelBackground.targetWidth
      return Math.abs(panelBackground.targetX - targetRightBarX) <= 1
    }
    readonly property bool willTouchTopEdge: isPanelVisible && allowAttach && panelBackground.targetY <= 1
    readonly property bool willTouchBottomEdge: isPanelVisible && allowAttach && (panelBackground.targetY + panelBackground.targetHeight) >= (root.height - 1)
    readonly property bool willTouchLeftEdge: isPanelVisible && allowAttach && panelBackground.targetX <= 1
    readonly property bool willTouchRightEdge: isPanelVisible && allowAttach && (panelBackground.targetX + panelBackground.targetWidth) >= (root.width - 1)

    readonly property bool isActuallyAttachedToAnyEdge: {
      if (!isPanelVisible)
        return false
      return willTouchTopBar || willTouchBottomBar || willTouchLeftBar || willTouchRightBar || willTouchTopEdge || willTouchBottomEdge || willTouchLeftEdge || willTouchRightEdge
    }

    readonly property bool animateFromTop: {
      if (!isPanelVisible)
        return true
      if (willTouchTopBar)
        return true
      if (willTouchTopEdge && !willTouchTopBar && !willTouchBottomBar && !willTouchLeftBar && !willTouchRightBar)
        return true
      if (!isActuallyAttachedToAnyEdge)
        return true
      return false
    }
    readonly property bool animateFromBottom: {
      if (!isPanelVisible)
        return false
      if (willTouchBottomBar)
        return true
      if (willTouchBottomEdge && !willTouchTopBar && !willTouchBottomBar && !willTouchLeftBar && !willTouchRightBar)
        return true
      return false
    }
    readonly property bool animateFromLeft: {
      if (!isPanelVisible)
        return false
      if (willTouchTopBar || willTouchBottomBar)
        return false
      if (willTouchLeftBar)
        return true
      var touchingTopEdge = isPanelVisible && allowAttach && panelBackground.targetY <= 1
      var touchingBottomEdge = isPanelVisible && allowAttach && (panelBackground.targetY + panelBackground.targetHeight) >= (root.height - 1)
      if (touchingTopEdge || touchingBottomEdge)
        return false
      if (willTouchLeftEdge && !willTouchLeftBar && !willTouchTopBar && !willTouchBottomBar && !willTouchRightBar)
        return true
      return false
    }
    readonly property bool animateFromRight: {
      if (!isPanelVisible)
        return false
      if (willTouchTopBar || willTouchBottomBar)
        return false
      if (willTouchRightBar)
        return true
      var touchingTopEdge = isPanelVisible && allowAttach && panelBackground.targetY <= 1
      var touchingBottomEdge = isPanelVisible && allowAttach && (panelBackground.targetY + panelBackground.targetHeight) >= (root.height - 1)
      if (touchingTopEdge || touchingBottomEdge)
        return false
      if (willTouchRightEdge && !willTouchLeftBar && !willTouchTopBar && !willTouchBottomBar && !willTouchRightBar)
        return true
      return false
    }

    readonly property bool shouldAnimateWidth: !shouldAnimateHeight && (animateFromLeft || animateFromRight)
    readonly property bool shouldAnimateHeight: animateFromTop || animateFromBottom

    // Current animated width/height
    readonly property real currentWidth: {
      if (isClosing && opacityFadeComplete && shouldAnimateWidth)
        return 0
      if (isClosing || isPanelVisible)
        return targetWidth
      return 0
    }
    readonly property real currentHeight: {
      if (isClosing && opacityFadeComplete && shouldAnimateHeight)
        return 0
      if (isClosing || isPanelVisible)
        return targetHeight
      return 0
    }

    width: currentWidth
    height: currentHeight

    x: {
      if (animateFromRight) {
        if (isPanelVisible || isClosing) {
          var targetRightEdge = targetX + targetWidth
          return targetRightEdge - width
        }
      }
      return targetX
    }
    y: {
      if (animateFromBottom) {
        if (isPanelVisible || isClosing) {
          var targetBottomEdge = targetY + targetHeight
          return targetBottomEdge - height
        }
      }
      return targetY
    }

    Behavior on width {
      NumberAnimation {
        duration: {
          if (!panelBackground.shouldAnimateWidth)
            return 0
          return root.isClosing ? Style.animationFast : Style.animationNormal
        }
        easing.type: Easing.BezierSpline
        easing.bezierCurve: panelBackground.bezierCurve
      }
    }

    Behavior on height {
      NumberAnimation {
        duration: {
          if (!panelBackground.shouldAnimateHeight)
            return 0
          return root.isClosing ? Style.animationFast : Style.animationNormal
        }
        easing.type: Easing.BezierSpline
        easing.bezierCurve: panelBackground.bezierCurve
      }
    }

    // Corner states for PanelBackground to read
    property int topLeftCornerState: {
      var barInverted = allowAttachToBar && ((root.barPosition === "top" && !root.barIsVertical && root.effectivePanelAnchorTop) || (root.barPosition === "left" && root.barIsVertical && root.effectivePanelAnchorLeft))
      var barTouchInverted = touchingTopBar || touchingLeftBar
      var edgeInverted = allowAttach && (touchingLeftEdge || touchingTopEdge)
      var oppositeEdgeInverted = allowAttach && (touchingTopEdge && !root.barIsVertical && root.barPosition !== "top")

      if (barInverted || barTouchInverted || edgeInverted || oppositeEdgeInverted) {
        if (touchingLeftEdge && touchingTopEdge)
          return 0
        if (touchingLeftEdge)
          return 2
        if (touchingTopEdge)
          return 1
        return root.barIsVertical ? 2 : 1
      }
      return 0
    }

    property int topRightCornerState: {
      var barInverted = allowAttachToBar && ((root.barPosition === "top" && !root.barIsVertical && root.effectivePanelAnchorTop) || (root.barPosition === "right" && root.barIsVertical && root.effectivePanelAnchorRight))
      var barTouchInverted = touchingTopBar || touchingRightBar
      var edgeInverted = allowAttach && (touchingRightEdge || touchingTopEdge)
      var oppositeEdgeInverted = allowAttach && (touchingTopEdge && !root.barIsVertical && root.barPosition !== "top")

      if (barInverted || barTouchInverted || edgeInverted || oppositeEdgeInverted) {
        if (touchingRightEdge && touchingTopEdge)
          return 0
        if (touchingRightEdge)
          return 2
        if (touchingTopEdge)
          return 1
        return root.barIsVertical ? 2 : 1
      }
      return 0
    }

    property int bottomLeftCornerState: {
      var barInverted = allowAttachToBar && ((root.barPosition === "bottom" && !root.barIsVertical && root.effectivePanelAnchorBottom) || (root.barPosition === "left" && root.barIsVertical && root.effectivePanelAnchorLeft))
      var barTouchInverted = touchingBottomBar || touchingLeftBar
      var edgeInverted = allowAttach && (touchingLeftEdge || touchingBottomEdge)
      var oppositeEdgeInverted = allowAttach && (touchingBottomEdge && !root.barIsVertical && root.barPosition !== "bottom")

      if (barInverted || barTouchInverted || edgeInverted || oppositeEdgeInverted) {
        if (touchingLeftEdge && touchingBottomEdge)
          return 0
        if (touchingLeftEdge)
          return 2
        if (touchingBottomEdge)
          return 1
        return root.barIsVertical ? 2 : 1
      }
      return 0
    }

    property int bottomRightCornerState: {
      var barInverted = allowAttachToBar && ((root.barPosition === "bottom" && !root.barIsVertical && root.effectivePanelAnchorBottom) || (root.barPosition === "right" && root.barIsVertical && root.effectivePanelAnchorRight))
      var barTouchInverted = touchingBottomBar || touchingRightBar
      var edgeInverted = allowAttach && (touchingRightEdge || touchingBottomEdge)
      var oppositeEdgeInverted = allowAttach && (touchingBottomEdge && !root.barIsVertical && root.barPosition !== "bottom")

      if (barInverted || barTouchInverted || edgeInverted || oppositeEdgeInverted) {
        if (touchingRightEdge && touchingBottomEdge)
          return 0
        if (touchingRightEdge)
          return 2
        if (touchingBottomEdge)
          return 1
        return root.barIsVertical ? 2 : 1
      }
      return 0
    }
  }
}
