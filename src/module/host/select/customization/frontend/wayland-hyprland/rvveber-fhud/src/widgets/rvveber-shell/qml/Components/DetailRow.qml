import QtQuick
import "../Theme"

Item {
    id: root

    property string label: ""
    property string value: ""
    property color valueColor: Appearance.foregroundStrong
    property real valueWidth: 0

    implicitWidth: labelText.implicitWidth + Appearance.spaceRoomy + Math.max(valueText.implicitWidth, valueWidth)
    implicitHeight: Math.max(labelText.implicitHeight, valueText.implicitHeight)

    HudText {
        id: labelText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: Appearance.muted
        font.bold: true
        font.letterSpacing: 1
        font.pixelSize: Appearance.textLabel
        text: root.label
    }

    HudText {
        id: valueText
        anchors.left: labelText.right
        anchors.leftMargin: Appearance.spaceRoomy
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: root.valueColor
        elide: Text.ElideRight
        text: root.value
    }
}
