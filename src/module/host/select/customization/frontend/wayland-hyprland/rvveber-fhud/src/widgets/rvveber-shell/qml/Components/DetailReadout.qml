import QtQuick
import "../Theme"

Item {
    id: root
    required property var overview
    readonly property bool radial: overview.level >= 0 || overview.life === "working"

    width: parent.width
    implicitHeight: Math.max(Appearance.ringDiameter, radial ? identity.implicitHeight : readout.implicitHeight)

    Readout {
        id: readout
        visible: !root.radial
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        label: root.overview.label
        value: root.overview.value
        unit: root.overview.unit
        status: root.overview.status
        freshness: root.overview.freshness
        health: root.overview.health
        life: root.overview.life
        detail: true
        reservedValueWidth: root.overview.reservedValueWidth
        reservedStatusWidth: root.overview.reservedStatusWidth
    }

    SegmentedRing {
        id: ring
        visible: root.radial
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        level: root.overview.level
        working: root.overview.life === "working"
        tone: readout.healthColor
        label: root.overview.label
        value: root.overview.level >= 0 ? root.overview.value + root.overview.unit : ""
        range: root.overview.level >= 0 ? "0–" + Math.round(root.overview.rangeMaximum * 100) + root.overview.unit : ""
    }

    Column {
        id: identity
        visible: root.radial
        anchors.left: ring.right
        anchors.leftMargin: Appearance.spaceRoomy
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spaceCompact

        HudText {
            text: root.overview.label
            color: Appearance.foregroundStrong
            font.pixelSize: Appearance.textHeading
            font.letterSpacing: 1
        }

        HudText {
            visible: root.overview.level < 0
            width: parent.width
            text: root.overview.value + root.overview.unit
            wrapMode: Text.Wrap
            color: Appearance.foregroundStrong
        }

        HudText {
            width: parent.width
            text: root.overview.status
            wrapMode: Text.Wrap
            color: root.overview.health === "normal" ? Appearance.foreground : readout.healthColor
            font.pixelSize: Appearance.textLabel
        }

        HudText {
            visible: text.length > 0
            width: parent.width
            text: root.overview.freshness
            wrapMode: Text.Wrap
            color: Appearance.foreground
            font.pixelSize: Appearance.textLabel
        }
    }
}
