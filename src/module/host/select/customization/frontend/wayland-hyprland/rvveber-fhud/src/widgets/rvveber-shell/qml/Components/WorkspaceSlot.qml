import QtQuick
import "../Theme"

Item {
    id: root

    property int number: 1
    property int windows: 0
    property bool current: false
    property bool urgent: false
    property string description: ""
    signal activated

    implicitWidth: Appearance.workspaceSlotWidth
    implicitHeight: Appearance.workspaceLaneHeight
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: "Workspace " + number + ", " + windows + " windows" + (urgent ? ", urgent" : "")
    Accessible.description: description
    Accessible.onPressAction: root.activated()

    Keys.onReturnPressed: root.activated()
    Keys.onSpacePressed: root.activated()

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius
        color: root.current || pointer.containsMouse || root.activeFocus ? Appearance.alpha(Appearance.accent, Appearance.opacityActive) : "transparent"
        border.width: Appearance.vectorLineWidth
        border.color: root.urgent ? Appearance.warning : root.current || root.activeFocus ? Appearance.accent : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: Appearance.motionQuick
            }
        }
    }

    HudText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        text: root.number + (root.urgent ? "!" : "")
        font.pixelSize: Appearance.textLabel
        color: root.urgent ? Appearance.warning : root.current || root.windows > 0 ? Appearance.foregroundStrong : Appearance.foreground
        opacity: root.current || root.windows > 0 || root.urgent ? 1 : Appearance.opacitySubtle
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.spaceTight
        spacing: Appearance.vectorLineWidth

        Repeater {
            model: Math.min(root.windows, 3)
            Rectangle {
                width: Appearance.spaceTight
                height: Appearance.vectorLineWidth
                color: root.urgent ? Appearance.warning : Appearance.foreground
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
