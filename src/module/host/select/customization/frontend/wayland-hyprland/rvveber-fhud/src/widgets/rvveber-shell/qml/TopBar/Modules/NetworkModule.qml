import QtQuick
import "../../Theme"
import "../../Components"

Readout {
    id: root

    required property QtObject barState
    required property QtObject systemState

    label: "NET"
    overviewWidth: Appearance.readoutWideValueWidth * 2
    overviewStatus: status
    value: systemState.networkName.toUpperCase()
    status: !systemState.networkReady ? "WAIT" : health === "stale" ? "STALE" : systemState.networkState.toUpperCase()
    freshness: systemState.networkFreshness
    health: systemState.networkHealth
    life: systemState.wifiWorking ? "working" : "ready"
    active: barState.openSection === "network"
    interactive: true
    reservedValueWidth: Appearance.readoutWideValueWidth
    reservedStatusWidth: Appearance.readoutWideStatusWidth
    onClicked: barState.toggle("network")

    Flyout {
        anchorItem: root
        controller: root.barState
        section: "network"
        minimumWidth: Appearance.flyoutWideWidth

        DetailReadout {
            overview: root
        }

        Row {
            spacing: Appearance.spaceCompact

            FhudButton {
                text: root.systemState.wifiEnabled ? "TURN WI-FI OFF" : "TURN WI-FI ON"
                active: root.systemState.wifiEnabled
                life: root.systemState.wifiChanging ? "working" : "ready"
                onClicked: root.systemState.setWifiEnabled(!root.systemState.wifiEnabled)
            }

            FhudButton {
                text: root.systemState.wifiScanning ? "SCANNING" : "RESCAN"
                life: root.systemState.wifiScanning ? "working" : "ready"
                onClicked: root.systemState.rescanWifi()
            }
        }

        HudText {
            text: "ACCESS POINTS"
            color: Appearance.muted
            font.bold: true
            font.pixelSize: Appearance.textLabel
        }

        HudText {
            visible: root.systemState.wifiNetworks.length === 0
            text: root.systemState.wifiScanning ? "Searching…" : root.systemState.wifiEnabled ? "No access points" : "Wi-Fi is off"
            color: Appearance.muted
        }

        ListView {
            width: parent.width
            height: Math.min(Appearance.flyoutListHeight, contentHeight)
            spacing: Appearance.spaceCompact
            clip: true
            model: root.systemState.wifiNetworks

            delegate: Surface {
                id: networkEntry

                required property var modelData
                width: ListView.view.width
                height: Appearance.rowHeight
                color: Appearance.alpha(modelData.active ? Appearance.accent : Appearance.background, modelData.active ? Appearance.opacityListActive : Appearance.opacityList)

                Row {
                    anchors.fill: parent
                    anchors.margins: Appearance.spaceCompact
                    spacing: Appearance.spaceCompact

                    HudText {
                        width: Appearance.readoutWideValueWidth * 3
                        anchors.verticalCenter: parent.verticalCenter
                        text: (networkEntry.modelData.active ? "◆ " : "◇ ") + networkEntry.modelData.ssid
                        elide: Text.ElideRight
                    }

                    HudText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: networkEntry.modelData.strength + "%"
                        color: Appearance.accent
                    }

                    HudText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: networkEntry.modelData.frequency
                        color: Appearance.muted
                        font.pixelSize: Appearance.textLabel
                    }

                    HudText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: networkEntry.modelData.security
                        color: Appearance.muted
                        font.pixelSize: Appearance.textLabel
                    }
                }
            }
        }

        DetailRow {
            width: parent.width
            label: "ETHERNET"
            value: root.systemState.wiredName
        }

        DetailRow {
            width: parent.width
            label: "VPN"
            value: root.systemState.vpnName
            valueColor: root.systemState.vpnName === "Disconnected" ? Appearance.muted : Appearance.success
        }
    }
}
