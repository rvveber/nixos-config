import Quickshell
import QtQuick
import "../Theme"
import "../Components"

Readout {
    id: root

    required property QtObject barState
    property date now: new Date()
    property int monthOffset: 0
    readonly property date shownMonth: new Date(now.getFullYear(), now.getMonth() + monthOffset, 1)
    readonly property var calendarDays: buildCalendar(shownMonth)

    label: "TIME"
    overviewStatus: Qt.formatDateTime(now, "ddd").toUpperCase()
    overviewWidth: Appearance.readoutWideStatusWidth
    value: Qt.formatDateTime(now, "HH:mm")
    status: Qt.formatDateTime(now, "ddd · yyyy-MM-dd").toUpperCase()
    health: "normal"
    life: "ready"
    interactive: true
    active: barState.openSection === "clock"
    reservedValueWidth: Appearance.readoutWideValueWidth
    reservedStatusWidth: Appearance.readoutWideStatusWidth * 2
    onClicked: barState.toggle("clock")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Flyout {
        id: calendar
        anchorItem: root
        controller: root.barState
        section: "clock"

        DetailReadout {
            overview: root
        }

        DetailRow {
            width: parent.width
            label: "DAY"
            value: Qt.formatDate(root.now, "dddd, MMMM d, yyyy")
            valueColor: Appearance.accent
        }

        Row {
            width: parent.width
            spacing: Appearance.spaceCompact

            FhudButton {
                id: previousMonth
                text: "‹"
                onClicked: root.monthOffset--
            }
            HudText {
                width: Math.max(0, parent.width - previousMonth.width - nextMonth.width - parent.spacing * 2)
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(root.shownMonth, "MMMM yyyy").toUpperCase()
                font.bold: true
                font.letterSpacing: 2
            }
            FhudButton {
                id: nextMonth
                text: "›"
                onClicked: root.monthOffset++
            }
        }

        Grid {
            width: parent.width
            columns: 7
            columnSpacing: Appearance.spaceTight
            rowSpacing: Appearance.spaceTight

            Repeater {
                model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]

                HudText {
                    required property string modelData
                    width: Appearance.calendarCellWidth
                    height: Appearance.calendarWeekdayHeight
                    text: modelData
                    color: Appearance.muted
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Appearance.textLabel
                    font.bold: true
                }
            }

            Repeater {
                model: root.calendarDays

                Rectangle {
                    required property var modelData

                    width: Appearance.calendarCellWidth
                    height: Appearance.calendarCellHeight
                    radius: Appearance.radius
                    color: modelData.today ? Appearance.alpha(Appearance.accent, Appearance.opacityActive) : "transparent"
                    border.width: modelData.today ? Appearance.vectorLineWidth : 0
                    border.color: Appearance.accent

                    HudText {
                        anchors.centerIn: parent
                        text: parent.modelData.day
                        color: parent.modelData.today ? Appearance.foregroundStrong : parent.modelData.inMonth ? Appearance.foreground : Appearance.alpha(Appearance.muted, Appearance.opacitySubtle)
                        font.bold: parent.modelData.today
                        font.pixelSize: Appearance.textBody
                    }
                }
            }
        }

        FhudButton {
            width: parent.width
            text: root.monthOffset === 0 ? "WEEK " + root.weekNumber(root.now) : "RETURN TO TODAY"
            onClicked: root.monthOffset = 0
        }
    }

    function buildCalendar(month: date): var {
        const firstWeekday = (month.getDay() + 6) % 7;
        const start = new Date(month.getFullYear(), month.getMonth(), 1 - firstWeekday);
        const todayKey = Qt.formatDate(now, "yyyy-MM-dd");
        return Array.from({
            length: 42
        }, (_, index) => {
            const date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + index);
            return {
                day: date.getDate(),
                inMonth: date.getMonth() === month.getMonth(),
                today: Qt.formatDate(date, "yyyy-MM-dd") === todayKey
            };
        });
    }

    function weekNumber(date: date): int {
        const copy = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        copy.setUTCDate(copy.getUTCDate() + 4 - (copy.getUTCDay() || 7));
        const yearStart = new Date(Date.UTC(copy.getUTCFullYear(), 0, 1));
        return Math.ceil((((copy - yearStart) / 86400000) + 1) / 7);
    }
}
