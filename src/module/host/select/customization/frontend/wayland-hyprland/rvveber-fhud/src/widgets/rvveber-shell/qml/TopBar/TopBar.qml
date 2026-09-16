import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../Theme"
import "../Components"

PanelWindow {
    id: root

    required property QtObject shellState
    required property QtObject systemState
    required property QtObject audioState
    required property QtObject batteryState
    required property QtObject notificationState

    readonly property var hyprMonitor: Hyprland.monitorFor(screen)
    readonly property string monitorSelector: (Quickshell.env("RVVEBER_FHUD_MAIN_MONITOR") || "").trim()
    readonly property bool configuredMonitorAvailable: Hyprland.monitors.values.some(monitor => root.matchesMonitor(monitor))
    readonly property bool isConfiguredMonitor: root.matchesMonitor(hyprMonitor)
    readonly property bool isFallbackMonitor: !configuredMonitorAvailable && Quickshell.screens.values.length > 0 && screen === Quickshell.screens.values[0]

    function matchesMonitor(monitor): bool {
        if (!monitor || root.monitorSelector.length === 0)
            return false;

        if (root.monitorSelector.startsWith("desc:")) {
            const descriptionPrefix = root.monitorSelector.slice(5).trim();
            return descriptionPrefix.length > 0 && (monitor.description || "").startsWith(descriptionPrefix);
        }

        return monitor.name === root.monitorSelector || monitor.description === root.monitorSelector;
    }

    anchors {
        top: true
        left: true
        right: true
    }
    readonly property bool stacked: width < leftPanel.width + status.implicitWidth + Appearance.spaceRoomy * 3
    implicitHeight: stacked ? leftPanel.height + statusPanel.height + Appearance.spaceCompact * 3 : Math.max(leftPanel.height, statusPanel.height) + Appearance.spaceCompact * 2
    exclusiveZone: visible ? implicitHeight : 0
    color: "transparent"
    visible: root.isConfiguredMonitor || root.isFallbackMonitor
    WlrLayershell.layer: WlrLayer.Top

    onVisibleChanged: {
        if (!visible)
            barController.dismiss();
    }

    BarState {
        id: barController
    }

    Item {
        anchors.fill: parent
        anchors.margins: Appearance.spaceCompact

        Surface {
            id: leftPanel
            border.width: Appearance.vectorLineWidth
            anchors.left: parent.left
            anchors.top: parent.top
            width: leftContent.implicitWidth + Appearance.spaceRoomy
            height: Math.max(Appearance.barSurfaceHeight, leftContent.implicitHeight + Appearance.spaceCompact)

            Row {
                id: leftContent
                anchors.centerIn: parent
                spacing: Appearance.spaceRoomy

                WorkspaceGrid {
                    id: workspace
                    anchors.verticalCenter: parent.verticalCenter
                }

                Clock {
                    id: clock
                    anchors.verticalCenter: parent.verticalCenter
                    barState: barController
                }
            }
        }

        Surface {
            id: statusPanel
            border.width: Appearance.vectorLineWidth
            anchors.right: parent.right
            anchors.top: root.stacked ? leftPanel.bottom : parent.top
            anchors.topMargin: root.stacked ? Appearance.spaceCompact : 0
            width: Math.min(parent.width, status.implicitWidth + Appearance.spaceRoomy)
            height: Math.max(Appearance.barSurfaceHeight, status.implicitHeight + Appearance.spaceCompact)

            StatusArea {
                id: status
                width: parent.width - Appearance.spaceRoomy
                anchors.centerIn: parent
                systemState: root.systemState
                shellState: root.shellState
                audioState: root.audioState
                batteryState: root.batteryState
                notificationState: root.notificationState
                barState: barController
            }
        }
    }
}
