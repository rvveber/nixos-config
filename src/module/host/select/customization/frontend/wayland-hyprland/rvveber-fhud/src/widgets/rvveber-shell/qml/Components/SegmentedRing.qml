import QtQuick
import QtQuick.Shapes
import "../Theme"

Item {
    id: root

    property real level: -1
    property bool working: false
    property bool compact: false
    property color tone: Appearance.accent
    property string label: ""
    property string value: ""
    property string range: ""
    readonly property bool presented: visible && Window.window !== null && Window.window.visible
    readonly property real amount: Number.isFinite(level) ? Math.max(0, Math.min(1, level)) : 0
    readonly property bool rotating: presented && working && !Appearance.reducedMotion

    implicitWidth: Appearance.ringDiameter
    implicitHeight: implicitWidth
    Accessible.role: Accessible.Indicator
    Accessible.name: [label, value, range, working ? "Working" : ""].filter(part => part.length > 0).join(" ")

    EntryMotion {
        id: entry
        active: root.presented
    }

    Repeater {
        model: Appearance.ringSegments

        Shape {
            id: segment
            required property int index
            anchors.fill: parent
            opacity: entry.progress >= index / Appearance.ringSegments ? 1 : Appearance.opacityQuiet

            ShapePath {
                fillColor: "transparent"
                strokeWidth: Appearance.ringStroke
                strokeColor: Appearance.alpha(root.tone, root.level >= 0 && root.amount * Appearance.ringSegments > segment.index ? Appearance.opacityTrack : Appearance.opacityQuiet)
                capStyle: ShapePath.FlatCap

                Behavior on strokeColor {
                    enabled: root.presented
                    ColorAnimation {
                        duration: Appearance.motionMove
                    }
                }

                PathAngleArc {
                    centerX: root.width / 2
                    centerY: root.height / 2
                    radiusX: Math.max(0, root.width / 2 - Appearance.spaceCompact)
                    radiusY: Math.max(0, root.height / 2 - Appearance.spaceCompact)
                    startAngle: 90 + (360 - Appearance.ringSweep) / 2 + segment.index * Appearance.ringSweep / Appearance.ringSegments
                    sweepAngle: Appearance.ringSweep / Appearance.ringSegments - Appearance.ringGap
                }
            }
        }
    }

    Item {
        id: rotor
        objectName: "workContour"
        anchors.fill: parent
        opacity: root.working ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.motionMove
            }
        }

        NumberAnimation on rotation {
            running: root.rotating
            from: 0
            to: 360
            duration: Appearance.motionOrbit
            loops: Animation.Infinite
        }

        Repeater {
            model: 3

            Shape {
                id: arc
                required property int index
                anchors.fill: parent

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: root.tone
                    strokeWidth: Appearance.vectorLineWidth
                    capStyle: ShapePath.FlatCap

                    PathAngleArc {
                        centerX: root.width / 2
                        centerY: root.height / 2
                        radiusX: Math.max(0, root.width / 2 - Appearance.vectorLineWidth)
                        radiusY: Math.max(0, root.height / 2 - Appearance.vectorLineWidth)
                        startAngle: arc.index * 120
                        sweepAngle: Appearance.ringSweep / 12
                    }
                }
            }
        }
    }

    Column {
        visible: !root.compact
        anchors.centerIn: parent
        spacing: Appearance.spaceTight

        HudText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.value
            color: root.tone
            font.pixelSize: Appearance.textHeading
        }

        HudText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.working ? "WORKING" : root.range
            color: Appearance.foreground
            font.pixelSize: Appearance.textLabel
        }
    }
}
