import QtQuick
import "../../Theme"
import "../../Components"

Readout {
    id: root

    required property QtObject barState
    required property QtObject notificationState

    label: "MSG"
    value: notificationState.count.toString()
    status: notificationState.doNotDisturb ? "FOCUS" : "READY"
    overviewStatus: notificationState.doNotDisturb ? "FOCUS" : ""
    active: barState.openSection === "notifications"
    interactive: true
    reservedValueWidth: Appearance.readoutValueWidth
    reservedStatusWidth: Appearance.readoutStatusWidth
    onClicked: barState.toggle("notifications")

    Flyout {
        anchorItem: root
        controller: root.barState
        section: "notifications"
        minimumWidth: Appearance.flyoutWideWidth

        DetailReadout {
            overview: root
        }

        Row {
            spacing: Appearance.spaceCompact

            FhudButton {
                text: root.notificationState.doNotDisturb ? "DISABLE FOCUS" : "ENABLE FOCUS"
                active: root.notificationState.doNotDisturb
                onClicked: root.notificationState.doNotDisturb = !root.notificationState.doNotDisturb
            }

            FhudButton {
                text: "CLEAR"
                onClicked: root.notificationState.dismissAll()
            }
        }

        HudText {
            visible: root.notificationState.count === 0
            text: "No notifications"
            color: Appearance.muted
        }

        ListView {
            width: parent.width
            height: Math.min(Appearance.flyoutListHeight, contentHeight)
            spacing: Appearance.spaceCompact
            clip: true
            model: root.notificationState.notifications

            delegate: Surface {
                id: notificationCard

                required property var modelData
                width: ListView.view.width
                height: notificationContent.implicitHeight + Appearance.spaceRoomy
                color: Appearance.alpha(Appearance.background, Appearance.opacityList)

                Column {
                    id: notificationContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.spaceCompact
                    spacing: Appearance.spaceTight

                    HudText {
                        width: parent.width
                        text: notificationCard.modelData.appName || "System"
                        color: Appearance.accent
                        font.bold: true
                        font.pixelSize: Appearance.textLabel
                        textFormat: Text.PlainText
                    }

                    HudText {
                        width: parent.width
                        text: notificationCard.modelData.summary || "Notification"
                        font.bold: true
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    HudText {
                        width: parent.width
                        visible: text.length > 0
                        text: notificationCard.modelData.body || ""
                        color: Appearance.muted
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Row {
                        spacing: Appearance.spaceCompact

                        FhudButton {
                            visible: notificationCard.modelData.actions.length > 0
                            text: "OPEN"
                            onClicked: root.notificationState.invokeDefault(notificationCard.modelData)
                        }

                        FhudButton {
                            text: "DISMISS"
                            onClicked: notificationCard.modelData.dismiss()
                        }
                    }
                }
            }
        }
    }
}
