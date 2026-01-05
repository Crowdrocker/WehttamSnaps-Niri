import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root
    required property ListView target

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: 10
    }

    opacity: !target.atYEnd ? 1 : 0
    scale: !target.atYEnd ? 1 : 0.7
    visible: opacity > 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on scale {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    implicitWidth: contentItem.implicitWidth + 8 * 2
    implicitHeight: contentItem.implicitHeight + 4 * 2

    colBackground: Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colSecondary
    colBackgroundHover: Appearance.inirEverywhere ? Appearance.inir.colPrimaryHover : Appearance.colors.colSecondaryHover
    colRipple: Appearance.inirEverywhere ? Appearance.inir.colPrimaryActive : Appearance.colors.colSecondaryActive
    buttonRadius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.verysmall

    downAction: () => {
        target.positionViewAtEnd()
    }

    contentItem: Row {
        id: contentItem
        spacing: 4
        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            text: "arrow_downward"
            font.pixelSize: Appearance.font.pixelSize.larger
            color: Appearance.inirEverywhere ? Appearance.inir.colOnPrimary : Appearance.colors.colOnSecondary
            verticalAlignment: Text.AlignVCenter
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr("Scroll to Bottom")
            font.pixelSize: Appearance.font.pixelSize.smallie
            color: Appearance.inirEverywhere ? Appearance.inir.colOnPrimary : Appearance.colors.colOnSecondary
            verticalAlignment: Text.AlignVCenter
        }
    }
}
