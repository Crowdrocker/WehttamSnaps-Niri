import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root
    property bool vertical: false
    property string dockPosition: "bottom"

    Layout.fillHeight: !vertical
    Layout.fillWidth: vertical

    implicitWidth: vertical ? (implicitHeight - topInset - bottomInset) : (implicitHeight - topInset - bottomInset)
    implicitHeight: 50
    buttonRadius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.normal

    // Hover colors for dock (Layer0 context)
    colBackgroundHover: Appearance.inirEverywhere ? Appearance.inir.colLayer1Hover
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
        : Appearance.colors.colLayer0Hover
    colRipple: Appearance.inirEverywhere ? Appearance.inir.colLayer1Active
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive
        : Appearance.colors.colLayer0Active

    background.implicitHeight: 50
    background.implicitWidth: 50
}
