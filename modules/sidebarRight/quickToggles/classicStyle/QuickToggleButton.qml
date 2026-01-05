import qs.modules.common
import qs.modules.common.widgets
import QtQuick

GroupButton {
    id: button
    property string buttonIcon
    baseWidth: 40
    baseHeight: 40
    clickedWidth: baseWidth + 20
    toggled: false
    buttonRadius: Appearance.inirEverywhere 
        ? Appearance.inir.roundingSmall 
        : ((altAction && toggled) ? Appearance?.rounding.normal : Math.min(baseHeight, baseWidth) / 2)
    buttonRadiusPressed: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance?.rounding?.small
    colBackground: Appearance.inirEverywhere ? Appearance.inir.colLayer2 
        : Appearance.auroraEverywhere ? "transparent" : Appearance.colors.colLayer2
    colBackgroundHover: Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover 
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface : Appearance.colors.colLayer2Hover
    colBackgroundToggled: Appearance.inirEverywhere ? Appearance.inir.colPrimaryContainer : Appearance.colors.colPrimary
    colBackgroundToggledHover: Appearance.inirEverywhere ? Appearance.inir.colPrimaryContainerHover : Appearance.colors.colPrimaryHover

    contentItem: Item {
        // Item fills the button area, icon is centered inside
        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 22
            fill: button.toggled ? 1 : 0
            color: Appearance.inirEverywhere 
                ? (button.toggled ? Appearance.inir.colOnPrimaryContainer : Appearance.inir.colText)
                : (button.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: button.buttonIcon

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}
