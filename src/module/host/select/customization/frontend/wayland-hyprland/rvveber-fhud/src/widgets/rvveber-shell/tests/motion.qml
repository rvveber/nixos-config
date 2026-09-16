import Quickshell
import QtQuick
import "qml/Components"
import "qml/Theme"

ShellRoot {
    id: root
    property int stage: 0
    property real lastAngle: 0
    property real headerHeight: 0
    property bool passed: true

    function check(condition, message): void {
        if (!condition) {
            passed = false;
            console.error(message);
        }
    }

    Window {
        id: window
        visible: true
        width: 320
        height: 200

        EntryMotion {
            id: entry
            active: window.visible
        }
        SegmentedRing {
            id: ring
            level: 0.62
            value: "62%"
        }
        Readout {
            id: measurement
            visible: false
            label: "BAT"
            value: "62"
            unit: "%"
            level: 0.62
            status: "DISCHARGING"
        }
        DetailReadout {
            id: detail
            x: 100
            width: 200
            overview: measurement
        }
    }

    Timer {
        interval: Math.max(50, Appearance.motionScene + Appearance.motionMove)
        running: true
        repeat: true

        onTriggered: {
            const contour = ring.children.find(child => child.objectName === "workContour");
            root.check(contour !== undefined, "Missing work contour");
            if (!contour) {
                Qt.quit();
                return;
            }
            switch (root.stage++) {
            case 0:
                root.check(!entry.running && entry.progress === 1 && entry.exposure === 1, "Entrance must settle");
                root.check(!ring.rotating, "Ready values must rest");
                root.lastAngle = contour.rotation;
                ring.working = true;
                root.headerHeight = detail.height;
                measurement.level = -1;
                measurement.life = "working";
                break;
            case 1:
                root.check(detail.height === root.headerHeight, "Acquisition must preserve control positions");
                measurement.life = "ready";
                root.check(Appearance.reducedMotion ? contour.rotation === root.lastAngle : contour.rotation !== root.lastAngle, "Work rotation must follow motion preference");
                window.visible = false;
                root.lastAngle = contour.rotation;
                break;
            case 2:
                root.check(detail.height === root.headerHeight, "Settling must preserve control positions");
                root.check(!ring.rotating && contour.rotation === root.lastAngle, "Hidden windows must stop rotation");
                root.check(!entry.running && entry.progress === 1 && entry.exposure === 1, "Closing must cancel the entrance cleanly");
                window.visible = true;
                root.check(Appearance.reducedMotion ? !entry.running : entry.running, "Reopening must respect motion preference");
                ring.working = false;
                root.lastAngle = contour.rotation;
                break;
            case 3:
                root.check(!ring.rotating && contour.rotation === root.lastAngle, "Completed work must stop rotation");
                root.check(entry.exposure === 1 && entry.progress === 1, "Reopened content must settle");
                ring.working = true;
                ring.visible = false;
                root.lastAngle = contour.rotation;
                break;
            case 4:
                root.check(!ring.rotating && contour.rotation === root.lastAngle, "Hidden items must stop rotation");
                if (root.passed)
                    console.log("MOTION CHECKS PASSED");
                Qt.quit();
                break;
            }
        }
    }
}
