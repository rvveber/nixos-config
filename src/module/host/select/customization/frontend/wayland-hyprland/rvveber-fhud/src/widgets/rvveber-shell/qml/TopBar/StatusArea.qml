import QtQuick
import "../Theme"
import "Modules"

Item {
    id: root

    required property QtObject barState
    required property QtObject systemState
    required property QtObject shellState
    required property QtObject audioState
    required property QtObject batteryState
    required property QtObject notificationState

    implicitWidth: controls.implicitWidth + connections.implicitWidth + system.implicitWidth + spacing * 2
    implicitHeight: groups.implicitHeight
    readonly property real spacing: Appearance.spaceRoomy

    Flow {
        id: groups
        width: root.width
        spacing: root.spacing

        Row {
            id: controls
            spacing: Appearance.spaceCompact

            AudioModule {
                barState: root.barState
                audioState: root.audioState
            }

            BrightnessModule {
                barState: root.barState
                systemState: root.systemState
            }
        }

        Row {
            id: connections
            spacing: Appearance.spaceCompact

            NetworkModule {
                barState: root.barState
                systemState: root.systemState
            }

            BluetoothModule {
                barState: root.barState
                systemState: root.systemState
            }
        }

        Row {
            id: system
            spacing: Appearance.spaceCompact

            BatteryModule {
                barState: root.barState
                batteryState: root.batteryState
            }

            NotificationModule {
                barState: root.barState
                notificationState: root.notificationState
            }

            SessionModule {
                barState: root.barState
                shellState: root.shellState
            }
        }
    }
}
