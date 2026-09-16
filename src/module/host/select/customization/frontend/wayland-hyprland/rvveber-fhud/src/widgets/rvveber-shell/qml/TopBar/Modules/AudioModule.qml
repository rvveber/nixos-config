import QtQuick
import "../../Theme"
import "../../Components"

Readout {
    id: root

    required property QtObject barState
    required property QtObject audioState

    label: "VOL"
    value: Math.round(audioState.volume * 100).toString()
    unit: "%"
    status: audioState.muted ? "MUTED" : "ACTIVE"
    health: audioState.health
    overviewStatus: audioState.muted ? "MUTE" : health === "normal" ? "" : health.toUpperCase()
    rangeMaximum: 1.5
    level: health === "unknown" ? -1 : audioState.volume / rangeMaximum
    active: barState.openSection === "audio"
    interactive: true
    reservedValueWidth: Appearance.readoutValueWidth
    reservedStatusWidth: Appearance.readoutStatusWidth
    onClicked: barState.toggle("audio")

    Flyout {
        anchorItem: root
        controller: root.barState
        section: "audio"
        minimumWidth: Appearance.flyoutWideWidth

        DetailReadout {
            overview: root
        }

        LabeledSlider {
            width: parent.width
            label: "Output"
            value: root.audioState.volume
            maximum: root.rangeMaximum
            onMoved: value => root.audioState.setVolume(value)
        }

        DetailRow {
            width: parent.width
            label: "OUTPUT"
            value: root.audioState.outputName
        }

        DetailRow {
            width: parent.width
            label: "INPUT"
            value: root.audioState.inputName
        }

        FhudButton {
            width: parent.width
            text: root.audioState.muted ? "UNMUTE" : "MUTE"
            active: root.audioState.muted
            onClicked: root.audioState.toggleMute()
        }

        HudText {
            text: "OUTPUTS"
            color: Appearance.muted
            font.bold: true
            font.pixelSize: Appearance.textLabel
        }

        Repeater {
            model: root.audioState.outputs

            FhudButton {
                required property var modelData
                width: parent.width
                text: (modelData === root.audioState.sink ? "◆ " : "◇ ") + (modelData.description || modelData.nickname || modelData.name)
                active: modelData === root.audioState.sink
                onClicked: root.audioState.selectOutput(modelData)
            }
        }

        HudText {
            text: "INPUTS"
            color: Appearance.muted
            font.bold: true
            font.pixelSize: Appearance.textLabel
        }

        Repeater {
            model: root.audioState.inputs

            FhudButton {
                required property var modelData
                width: parent.width
                text: (modelData === root.audioState.source ? "◆ " : "◇ ") + (modelData.description || modelData.nickname || modelData.name)
                active: modelData === root.audioState.source
                onClicked: root.audioState.selectInput(modelData)
            }
        }
    }
}
