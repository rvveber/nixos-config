import QtQuick
import "../Theme"

Rectangle {
    id: root
    property bool focal: false
    property real reveal: 1

    color: Appearance.alpha(Appearance.surface, Appearance.opacitySurface)
    radius: Appearance.radius
    border.width: Appearance.vectorLineWidth
    border.color: Appearance.alpha(Appearance.accent, focal ? Appearance.opacityFocus : Appearance.opacityBorder)

    Behavior on color {
        ColorAnimation {
            duration: Appearance.motionQuick
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: Appearance.motionQuick
        }
    }

    Repeater {
        model: 2

        Item {
            required property int index
            readonly property real length: Math.min(Appearance.vectorLength, root.width / 4, root.height / 4) * root.reveal
            x: index === 0 ? 0 : root.width - width
            y: index === 0 ? 0 : root.height - height
            width: length
            height: length
            rotation: index * 180
            opacity: root.focal ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.motionQuick
                }
            }

            Rectangle {
                width: parent.width
                height: Appearance.vectorLineWidth
                color: Appearance.accent
            }

            Rectangle {
                width: Appearance.vectorLineWidth
                height: parent.height
                color: Appearance.accent
            }
        }
    }
}
