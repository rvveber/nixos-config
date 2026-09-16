import QtQuick
import "../../Theme"
import "../../Components"

Readout {
    id: root

    required property QtObject barState
    required property QtObject systemState

    visible: systemState.brightnessAvailable
    label: "BRT"
    value: Math.round(systemState.brightness * 100).toString()
    unit: "%"
    status: health === "stale" ? "STALE" : "DISPLAY"
    freshness: systemState.brightnessFreshness
    health: systemState.brightnessHealth
    level: health === "unknown" ? -1 : systemState.brightness
    life: systemState.brightnessChanging ? "working" : "ready"
    active: barState.openSection === "brightness"
    interactive: true
    reservedValueWidth: Appearance.readoutValueWidth
    reservedStatusWidth: Appearance.readoutStatusWidth
    onClicked: barState.toggle("brightness")

    Flyout {
        anchorItem: root
        controller: root.barState
        section: "brightness"

        DetailReadout {
            overview: root
        }

        LabeledSlider {
            width: parent.width
            label: "Brightness"
            value: root.systemState.brightness
            onMoved: value => root.systemState.setBrightness(value)
        }
    }
}
