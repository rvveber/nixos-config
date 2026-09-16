import QtQuick
import "../../Theme"
import "../../Components"

Readout {
    id: root

    required property QtObject barState
    required property QtObject systemState

    label: "BT"
    overviewStatus: status
    value: systemState.bluetoothState.toUpperCase()
    status: !systemState.bluetoothReady ? "WAIT" : health === "stale" ? "STALE" : systemState.bluetoothDiscovering ? "SCAN" : systemState.bluetoothPowered ? "ON" : "OFF"
    freshness: systemState.bluetoothFreshness
    health: systemState.bluetoothHealth
    life: systemState.bluetoothWorking ? "working" : "ready"
    active: barState.openSection === "bluetooth"
    interactive: true
    reservedValueWidth: Appearance.readoutWideValueWidth
    reservedStatusWidth: Appearance.readoutStatusWidth
    onClicked: barState.toggle("bluetooth")

    Flyout {
        anchorItem: root
        controller: root.barState
        section: "bluetooth"
        minimumWidth: Appearance.flyoutWideWidth

        DetailReadout {
            overview: root
        }

        Row {
            spacing: Appearance.spaceCompact

            FhudButton {
                text: root.systemState.bluetoothPowered ? "TURN POWER OFF" : "TURN POWER ON"
                active: root.systemState.bluetoothPowered
                life: root.systemState.bluetoothChanging ? "working" : "ready"
                onClicked: root.systemState.setBluetoothPowered(!root.systemState.bluetoothPowered)
            }

            FhudButton {
                text: root.systemState.bluetoothDiscovering ? "STOP SCAN" : "SCAN"
                active: root.systemState.bluetoothDiscovering
                life: root.systemState.bluetoothWorking ? "working" : "ready"
                onClicked: root.systemState.scanBluetooth()
            }
        }

        HudText {
            text: "DEVICES"
            color: Appearance.muted
            font.bold: true
            font.pixelSize: Appearance.textLabel
        }

        HudText {
            visible: root.systemState.bluetoothDevices.length === 0
            text: root.systemState.bluetoothDiscovering ? "Searching…" : "No known devices"
            color: Appearance.muted
        }

        ListView {
            width: parent.width
            height: Math.min(Appearance.flyoutListHeight, contentHeight)
            spacing: Appearance.spaceCompact
            clip: true
            model: root.systemState.bluetoothDevices

            delegate: Row {
                id: deviceRow

                required property var modelData
                width: ListView.view.width
                spacing: Appearance.spaceCompact

                FhudButton {
                    width: Math.max(0, deviceRow.width - forgetButton.width - deviceRow.spacing)
                    text: (deviceRow.modelData.connected ? "◆ " : "◇ ") + deviceRow.modelData.name
                    active: deviceRow.modelData.connected
                    onClicked: root.systemState.toggleBluetoothDevice(deviceRow.modelData)
                }

                FhudButton {
                    id: forgetButton
                    text: "FORGET"
                    onClicked: root.systemState.forgetBluetoothDevice(deviceRow.modelData)
                }
            }
        }
    }
}
