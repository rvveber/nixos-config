import QtQuick
import "../Theme"

Item {
    id: root

    property string life: "ready"
    property string health: "normal"

    readonly property bool working: life === "working"
    readonly property bool failed: life === "failed"
    readonly property bool presented: visible && Window.window !== null && Window.window.visible
    readonly property color healthColor: {
        switch (health) {
        case "caution":
            return Appearance.healthCaution;
        case "critical":
            return Appearance.healthCritical;
        case "stale":
            return Appearance.healthStale;
        case "unknown":
            return Appearance.healthUnknown;
        default:
            return Appearance.healthNormal;
        }
    }

    implicitWidth: visible ? Appearance.vectorLength : 0
    implicitHeight: Appearance.vectorLineWidth + Appearance.spaceTight
    visible: working || failed

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Appearance.vectorLineWidth
        color: Appearance.alpha(root.healthColor, Appearance.opacityBorder)

        Rectangle {
            id: trace
            anchors.verticalCenter: parent.verticalCenter
            width: root.working && !Appearance.reducedMotion ? parent.width / 2 : parent.width
            height: parent.height
            color: root.failed ? Appearance.healthCritical : root.healthColor

            SequentialAnimation on x {
                running: root.working && root.presented && !Appearance.reducedMotion
                loops: Animation.Infinite
                NumberAnimation {
                    from: 0
                    to: trace.parent.width / 2
                    duration: Appearance.motionScene
                }
                NumberAnimation {
                    from: trace.parent.width / 2
                    to: 0
                    duration: Appearance.motionScene
                }
            }
        }
    }
}
