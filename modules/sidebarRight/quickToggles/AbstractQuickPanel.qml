import QtQuick
import qs.modules.common
import qs.modules.common.functions

Rectangle {
    id: root

    property bool editMode: false
    readonly property bool cardStyle: Config.options?.sidebar?.cardStyle ?? false

    radius: Appearance.inirEverywhere ? Appearance.inir.roundingNormal : Appearance.rounding.normal
    color: cardStyle 
        ? (Appearance.inirEverywhere ? Appearance.inir.colLayer1
            : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
            : Appearance.colors.colLayer1)
        : "transparent"
    border.width: 0
    border.color: "transparent"

    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openNightLightDialog()
    signal openWifiDialog()
}
