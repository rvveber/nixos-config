import QtQuick
import "../../Theme"
import "../../Components"

Readout {
    id: root

    required property QtObject barState
    required property QtObject shellState
    property string armedAction: ""

    label: "SYS"
    value: armedAction.length > 0 ? "CONFIRM" : "SESSION"
    status: armedAction.length > 0 ? "CONFIRM" : "SESSION"
    health: armedAction.length > 0 ? "critical" : "normal"
    active: barState.openSection === "session"
    interactive: true
    reservedValueWidth: Appearance.readoutWideValueWidth
    reservedStatusWidth: Appearance.readoutStatusWidth
    onClicked: barState.toggle("session")

    function arm(action: string): void {
        if (root.armedAction !== action) {
            root.armedAction = action;
            disarm.restart();
            return;
        }

        disarm.stop();
        root.armedAction = "";
        root.barState.dismiss();
        if (action === "reboot")
            root.shellState.reboot();
        else
            root.shellState.powerOff();
    }

    Timer {
        id: disarm
        interval: 4000
        onTriggered: root.armedAction = ""
    }

    Flyout {
        anchorItem: root
        controller: root.barState
        section: "session"

        DetailReadout {
            overview: root
        }

        FhudButton {
            width: parent.width
            text: "OPEN HUD MODEL"
            onClicked: {
                root.barState.dismiss();
                root.shellState.openDemo();
            }
        }

        Row {
            spacing: Appearance.spaceCompact

            FhudButton {
                text: "LOCK / SLEEP"
                onClicked: root.shellState.lockAndSuspend()
            }

            FhudButton {
                text: "SUSPEND"
                onClicked: root.shellState.suspend()
            }

            FhudButton {
                text: "HIBERNATE"
                onClicked: root.shellState.hibernate()
            }
        }

        Row {
            spacing: Appearance.spaceCompact

            FhudButton {
                text: root.armedAction === "reboot" ? "CONFIRM REBOOT" : "REBOOT"
                active: root.armedAction === "reboot"
                health: root.armedAction === "reboot" ? "critical" : "normal"
                onClicked: root.arm("reboot")
            }

            FhudButton {
                text: root.armedAction === "poweroff" ? "CONFIRM SHUTDOWN" : "SHUTDOWN"
                active: root.armedAction === "poweroff"
                health: root.armedAction === "poweroff" ? "critical" : "normal"
                onClicked: root.arm("poweroff")
            }
        }
    }
}
