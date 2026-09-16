import QtQuick
import "../../Theme"
import "../../Components"

Readout {
    id: root

    required property QtObject barState
    required property QtObject batteryState

    visible: batteryState.available
    label: "BAT"
    value: batteryState.percentage.toString()
    unit: "%"
    status: batteryState.profileName.toUpperCase()
    health: batteryState.health
    overviewWidth: Appearance.readoutWideStatusWidth
    overviewStatus: health === "normal" ? batteryState.state === "Charging" ? "CHG" : "" : health.toUpperCase()
    level: health === "unknown" ? -1 : batteryState.percentage / 100
    active: barState.openSection === "battery"
    interactive: true
    reservedValueWidth: Appearance.readoutValueWidth
    reservedStatusWidth: Appearance.readoutWideStatusWidth
    onClicked: barState.toggle("battery")

    Flyout {
        anchorItem: root
        controller: root.barState
        section: "battery"
        minimumWidth: Appearance.flyoutWideWidth

        DetailReadout {
            overview: root
        }

        DetailRow {
            width: parent.width
            label: "STATUS"
            value: root.batteryState.state
        }

        DetailRow {
            width: parent.width
            label: "POWER"
            value: root.batteryState.stateDetail
        }

        DetailRow {
            width: parent.width
            label: "BATTERY FLOW"
            value: root.batteryState.rateText
            valueColor: root.batteryState.state === "Charging" ? Appearance.success : root.batteryState.state === "Discharging" ? Appearance.warning : Appearance.foregroundStrong
        }

        DetailRow {
            visible: root.batteryState.energy > 0
            width: parent.width
            label: "STORED ENERGY"
            value: root.batteryState.storedEnergyText
        }

        DetailRow {
            visible: root.batteryState.healthAvailable
            width: parent.width
            label: "BATTERY HEALTH"
            value: root.batteryState.batteryHealthText
        }

        DetailRow {
            width: parent.width
            label: "TIME"
            value: root.batteryState.remaining
        }

        DetailRow {
            visible: root.batteryState.finite(root.batteryState.gpu.busyPercent)
            width: parent.width
            label: "AMD GPU"
            value: root.batteryState.finite(root.batteryState.gpu.busyPercent) ? root.batteryState.gpu.busyPercent.toFixed(0) + "% busy" : "Unavailable"
        }

        DetailRow {
            visible: root.batteryState.rate.kind === "system_draw"
            width: parent.width
            label: root.batteryState.batterySupplementingExternalPower ? "POWER DEFICIT" : "DRAW"
            value: root.batteryState.changeRate.toFixed(1) + " W from battery · " + root.batteryState.anomalyLabel
            valueColor: root.batteryState.anomalyLevel === "high" ? Appearance.error : root.batteryState.anomalyLevel === "elevated" ? Appearance.warning : Appearance.foregroundStrong
        }

        HudText {
            visible: root.batteryState.rate.kind === "system_draw"
            width: parent.width
            text: root.batteryState.drawDetail
            color: Appearance.muted
            font.pixelSize: Appearance.textLabel
            wrapMode: Text.WordWrap
        }

        DetailRow {
            width: parent.width
            label: root.batteryState.summaryLabel
            value: root.batteryState.summaryText
        }

        HudText {
            width: parent.width
            text: root.batteryState.impactLabel
            color: Appearance.muted
            font.bold: true
            font.letterSpacing: 1
            font.pixelSize: Appearance.textLabel
        }

        Column {
            width: parent.width
            spacing: Appearance.spaceCompact

            Repeater {
                model: root.batteryState.impactProcesses

                delegate: Item {
                    required property var modelData
                    width: parent.width
                    implicitHeight: Math.max(processName.implicitHeight, impactBar.implicitHeight, impactValue.implicitHeight)

                    HudText {
                        id: processName
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 150
                        text: modelData.name
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        id: impactBar
                        anchors.left: processName.right
                        anchors.leftMargin: Appearance.spaceCompact
                        anchors.verticalCenter: parent.verticalCenter
                        width: 100
                        implicitHeight: Appearance.vectorLineWidth * 5
                        color: Appearance.alpha(Appearance.muted, Appearance.opacityQuiet)

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(100, modelData.share)) / 100
                            height: parent.height
                            color: modelData.level === "High" ? Appearance.warning : Appearance.accent
                        }
                    }

                    HudText {
                        id: impactValue
                        anchors.left: impactBar.right
                        anchors.leftMargin: Appearance.spaceCompact
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.share.toFixed(0) + "%  " + modelData.level
                        color: modelData.level === "High" ? Appearance.warning : Appearance.foregroundStrong
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Appearance.textLabel
                    }
                }
            }

            HudText {
                visible: root.batteryState.impactProcesses.length === 0
                width: parent.width
                text: "Collecting process activity…"
                color: Appearance.muted
            }
        }

        HudText {
            width: parent.width
            text: root.batteryState.impactSource
            color: Appearance.muted
            font.pixelSize: Appearance.textLabel
            wrapMode: Text.WordWrap
        }

        HudText {
            visible: root.batteryState.telemetryError.length > 0
            width: parent.width
            text: root.batteryState.telemetryError
            color: Appearance.warning
            font.pixelSize: Appearance.textLabel
            wrapMode: Text.WordWrap
        }

        DetailRow {
            width: parent.width
            label: "PROFILE"
            value: root.batteryState.profileDetail
        }

        Row {
            spacing: Appearance.spaceCompact

            FhudButton {
                text: "SAVER"
                active: root.batteryState.profileName === "Power Saver"
                onClicked: root.batteryState.setProfile("power-saver")
            }

            FhudButton {
                text: "BALANCED"
                active: root.batteryState.profileName === "Balanced"
                onClicked: root.batteryState.setProfile("balanced")
            }

            FhudButton {
                text: "PERFORMANCE"
                active: root.batteryState.profileName === "Performance"
                onClicked: root.batteryState.setProfile("performance")
            }
        }

        Column {
            visible: root.batteryState.debugEnabled
            width: parent.width
            spacing: Appearance.spaceCompact

            HudText {
                text: "POWER DEBUG"
                color: Appearance.warning
                font.bold: true
                font.letterSpacing: 1
                font.pixelSize: Appearance.textLabel
            }

            HudText {
                width: parent.width
                text: root.batteryState.debugText
                color: Appearance.muted
                font.pixelSize: Appearance.textLabel
            }

            HudText {
                width: parent.width
                text: "Rate source    " + root.batteryState.powerSource + "\nTime source    " + root.batteryState.timeSource + "\nGPU source     " + (root.batteryState.gpu.source || "Unavailable")
                color: Appearance.muted
                font.pixelSize: Appearance.textLabel
                wrapMode: Text.WrapAnywhere
            }

            HudText {
                width: parent.width
                text: root.batteryState.debugProcessText
                color: Appearance.muted
                font.pixelSize: Appearance.textLabel
                wrapMode: Text.WrapAnywhere
            }
        }
    }
}
