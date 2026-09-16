import QtQuick
import "../Theme"

Item {
    id: root

    property string label: ""
    property string value: ""
    property string unit: ""
    property string status: ""
    property string freshness: ""
    property string health: "normal"
    property string life: "ready"
    property bool detail: false
    property bool interactive: false
    property bool active: false
    property real reservedValueWidth: 0
    property real reservedStatusWidth: 0
    property string overviewStatus: health === "normal" ? "" : health.toUpperCase()
    property real overviewWidth: Appearance.readoutWideValueWidth
    property real level: -1
    property real rangeMaximum: 1
    signal clicked

    readonly property color healthColor: {
        switch (health) {
        case "caution": return Appearance.healthCaution;
        case "critical": return Appearance.healthCritical;
        case "stale": return Appearance.healthStale;
        case "unknown": return Appearance.healthUnknown;
        default: return Appearance.healthNormal;
        }
    }
    readonly property bool emphasized: active || pointer.containsMouse || activeFocus

    implicitWidth: detail ? readoutRow.implicitWidth + Appearance.spaceRegular : overviewWidth + Appearance.spaceRoomy
    implicitHeight: detail ? detailColumn.implicitHeight + Appearance.spaceCompact : Math.max(readoutRow.implicitHeight, Appearance.barSurfaceHeight - Appearance.spaceCompact)
    activeFocusOnTab: interactive
    Accessible.role: interactive ? Accessible.Button : Accessible.StaticText
    Accessible.name: [label, value + unit, status].filter(part => part.length > 0).join(" ")
    Accessible.description: freshness
    Accessible.onPressAction: {
        if (root.interactive)
            root.clicked();
    }

    Keys.onReturnPressed: event => {
        if (!interactive)
            return;
        root.clicked();
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        if (!interactive)
            return;
        root.clicked();
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius
        color: root.emphasized ? Appearance.alpha(root.healthColor, Appearance.opacityHover) : "transparent"
        border.width: Appearance.vectorLineWidth
        border.color: root.emphasized ? Appearance.alpha(root.healthColor, Appearance.opacityFocus) : "transparent"

        Behavior on color {
            ColorAnimation { duration: Appearance.motionQuick }
        }

        Behavior on border.color {
            ColorAnimation { duration: Appearance.motionQuick }
        }
    }

    Column {
        id: detailColumn
        visible: root.detail
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: Appearance.spaceTight

        HudText {
            visible: root.detail
            text: root.label
            color: Appearance.muted
            font.bold: true
            font.letterSpacing: 1
            font.pixelSize: Appearance.textLabel
        }

        Row {
            id: readoutRow
            spacing: Appearance.spaceCompact

            HudText {
                visible: !root.detail
                anchors.verticalCenter: parent.verticalCenter
                text: root.label
                color: root.emphasized ? root.healthColor : Appearance.muted
                font.bold: true
                font.letterSpacing: 1
                font.pixelSize: Appearance.textLabel
            }

            HudText {
                id: valueText
                width: root.reservedValueWidth > 0 && !root.detail ? root.reservedValueWidth : Math.max(implicitWidth, root.reservedValueWidth)
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: root.value
                color: root.health === "normal" ? Appearance.foregroundStrong : root.healthColor
                elide: Text.ElideRight
                font.pixelSize: root.detail ? Appearance.textHeading : Appearance.textTelemetry
            }

            HudText {
                visible: root.unit.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: root.unit
                color: Appearance.muted
                font.pixelSize: Appearance.textLabel
            }

            HudText {
                id: statusText
                visible: root.status.length > 0
                width: root.reservedStatusWidth > 0 && !root.detail ? root.reservedStatusWidth : Math.max(implicitWidth, root.reservedStatusWidth)
                anchors.verticalCenter: parent.verticalCenter
                text: root.status
                color: root.health === "normal" ? Appearance.muted : root.healthColor
                elide: Text.ElideRight
                font.bold: root.health !== "normal"
                font.pixelSize: Appearance.textLabel
            }
        }

        HudText {
            visible: root.detail && root.freshness.length > 0
            text: root.freshness
            color: root.health === "stale" ? root.healthColor : Appearance.muted
            font.bold: root.health === "stale"
            font.pixelSize: Appearance.textLabel
        }
    }

    Column {
        visible: !root.detail
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Appearance.spaceCompact
        anchors.rightMargin: Appearance.spaceCompact
        spacing: Appearance.spaceTight

        Item {
            width: parent.width
            height: caption.implicitHeight

            HudText {
                id: caption
                text: root.label
                color: root.emphasized ? root.healthColor : Appearance.foreground
                font.pixelSize: Appearance.textLabel
                font.letterSpacing: 1
            }

            HudText {
                anchors.left: caption.right
                anchors.leftMargin: Appearance.spaceCompact
                anchors.right: parent.right
                horizontalAlignment: Text.AlignRight
                text: root.overviewStatus
                elide: Text.ElideRight
                color: root.health === "normal" ? Appearance.foreground : root.healthColor
                font.pixelSize: Appearance.textLabel
            }
        }

        Row {
            width: parent.width
            spacing: Appearance.spaceTight

            HudText {
                id: overviewValue
                width: Math.min(implicitWidth, parent.width - (overviewUnit.visible ? overviewUnit.implicitWidth + parent.spacing : 0))
                text: root.value
                elide: Text.ElideRight
                color: root.health === "normal" ? Appearance.foregroundStrong : root.healthColor
                font.pixelSize: Appearance.textTelemetry
            }

            HudText {
                id: overviewUnit
                visible: root.unit.length > 0
                anchors.baseline: overviewValue.baseline
                text: root.unit
                color: Appearance.foreground
                font.pixelSize: Appearance.textLabel
            }
        }
    }

    Row {
        visible: !root.detail && root.level >= 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Appearance.spaceCompact
        anchors.bottomMargin: Appearance.spaceTight
        spacing: Appearance.vectorLineWidth

        Repeater {
            model: 10

            Rectangle {
                required property int index
                width: (parent.width - parent.spacing * 9) / 10
                height: Appearance.vectorLineWidth
                color: Appearance.alpha(root.healthColor, root.level >= (index + 1) / 10 ? Appearance.opacityTrack : Appearance.opacityQuiet)
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Appearance.vectorLineWidth
        visible: root.active
        color: root.healthColor
    }

    Activity {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        life: root.life
        health: root.health
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: root.forceActiveFocus()
        onClicked: root.clicked()
    }
}
