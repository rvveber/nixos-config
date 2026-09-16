pragma ComponentBehavior: Bound
//@ pragma ShellId rvveber-fhud

import Quickshell
import QtQuick
import "Services"
import "TopBar"
import "Hud"

ShellRoot {
    id: root

    property QtObject shellState: shellStateService
    property QtObject systemState: systemStateService
    property QtObject audioState: audioStateService
    property QtObject batteryState: batteryStateService
    property QtObject notificationState: notificationStateService

    ShellState {
        id: shellStateService
    }
    SystemState {
        id: systemStateService
    }
    AudioState {
        id: audioStateService
    }
    BatteryState {
        id: batteryStateService
    }
    NotificationState {
        id: notificationStateService
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            TopBar {
                required property var modelData
                screen: modelData
                shellState: root.shellState
                systemState: root.systemState
                audioState: root.audioState
                batteryState: root.batteryState
                notificationState: root.notificationState
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            HudWindow {
                required property var modelData
                screen: modelData
                shellState: root.shellState
            }
        }
    }
}
