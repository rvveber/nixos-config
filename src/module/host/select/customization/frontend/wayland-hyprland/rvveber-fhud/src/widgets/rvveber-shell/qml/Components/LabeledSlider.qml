import QtQuick
import "../Theme"

Column {
    id: root

    property string label
    property real value
    property real maximum: 1
    property real step: 0.05
    signal moved(real value)

    spacing: Appearance.spaceCompact
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: label
    Accessible.description: Math.round(value / maximum * 100) + "%"

    Keys.onLeftPressed: event => {
        root.moved(Math.max(0, root.value - root.step));
        event.accepted = true;
    }
    Keys.onRightPressed: event => {
        root.moved(Math.min(root.maximum, root.value + root.step));
        event.accepted = true;
    }

    Row {
        width: parent.width

        HudText {
            text: root.label
        }
        Item {
            width: parent.width - parent.children[0].implicitWidth - valueLabel.implicitWidth
            height: Appearance.vectorLineWidth
        }
        HudText {
            id: valueLabel
            text: Math.round(root.value * 100) + "%"
            color: Appearance.muted
        }
    }

    Rectangle {
        id: track
        width: parent.width
        height: Appearance.spaceCompact + Appearance.gap
        radius: Appearance.radius
        color: Appearance.alpha(Appearance.background, Appearance.opacityTrack)
        border.width: Appearance.vectorLineWidth
        border.color: root.activeFocus ? Appearance.accent : Appearance.alpha(Appearance.foreground, Appearance.opacityBorder)

        Behavior on border.color {
            ColorAnimation { duration: Appearance.motionQuick }
        }

        Rectangle {
            width: Math.max(0, Math.min(parent.width, parent.width * root.value / root.maximum))
            height: parent.height
            radius: Appearance.radius
            color: Appearance.accent

            Behavior on width {
                enabled: !sliderMouse.pressed
                NumberAnimation { duration: Appearance.motionQuick }
            }
        }

        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => {
                root.forceActiveFocus();
                root.moved(Math.max(0, Math.min(root.maximum, mouse.x / width * root.maximum)));
            }
            onPositionChanged: mouse => {
                if (pressed)
                    root.moved(Math.max(0, Math.min(root.maximum, mouse.x / width * root.maximum)));
            }
        }
    }
}
