import QtQuick
import "../Theme"

QtObject {
    id: root

    property bool active: false
    property real progress: 1
    property real exposure: 1
    readonly property bool running: sequence.running

    function replay(): void {
        sequence.stop();
        progress = 1;
        exposure = 1;
        if (active && !Appearance.reducedMotion) {
            progress = 0;
            exposure = Appearance.opacitySubtle;
            sequence.start();
        }
    }

    onActiveChanged: replay()
    Component.onCompleted: replay()

    property Connections motionPreference: Connections {
        target: Appearance
        function onReducedMotionChanged() {
            root.replay();
        }
    }

    property ParallelAnimation sequence: ParallelAnimation {
        id: sequence

        NumberAnimation {
            target: root
            property: "progress"
            to: 1
            duration: Appearance.motionScene
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            NumberAnimation {
                target: root
                property: "exposure"
                to: 1
                duration: Appearance.motionQuick / 2
            }
            NumberAnimation {
                target: root
                property: "exposure"
                to: Appearance.opacityEntryEcho
                duration: Appearance.motionQuick / 2
            }
            NumberAnimation {
                target: root
                property: "exposure"
                to: 1
                duration: Appearance.motionMove
                easing.type: Easing.OutCubic
            }
        }
    }
}
