import QtQuick
import "../Theme"

Rectangle {
    id: root

    property alias text: label.text
    property bool active: false
    property string health: "normal"
    property string life: "ready"
    signal clicked

    readonly property color healthColor: {
        switch (health) {
        case "caution": return Appearance.healthCaution;
        case "critical": return Appearance.healthCritical;
        case "stale": return Appearance.healthStale;
        case "unknown": return Appearance.healthUnknown;
        default: return Appearance.healthNormal;
        }
    }

    implicitWidth: Math.max(Appearance.controlHeight, label.implicitWidth + Appearance.spaceRoomy)
    implicitHeight: Appearance.controlHeight
    radius: Appearance.radius
    color: active || mouse.containsMouse || activeFocus ? Appearance.alpha(healthColor, active ? Appearance.opacityActive : Appearance.opacityHover) : "transparent"
    border.width: Appearance.vectorLineWidth
    border.color: active || mouse.containsMouse || activeFocus ? Appearance.alpha(healthColor, Appearance.opacityFocus) : "transparent"
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label.text
    Accessible.onPressAction: root.clicked()

    Keys.onReturnPressed: event => {
        root.clicked();
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.clicked();
        event.accepted = true;
    }

    Behavior on color {
        ColorAnimation { duration: Appearance.motionQuick }
    }
    Behavior on border.color {
        ColorAnimation { duration: Appearance.motionQuick }
    }

    HudText {
        id: label
        anchors.centerIn: parent
        width: parent.width - Appearance.spaceRegular
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    Activity {
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spaceTight
        anchors.bottom: parent.bottom
        life: root.life
        health: root.health
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onPressed: root.forceActiveFocus()
    }
}
