import Quickshell.Io
import QtQuick
import "../Theme"
import "../Components"

Item {
    id: root

    required property var entry

    property bool active: true
    readonly property bool isBinary: active && entry.binary === true
    readonly property bool isImage: active && entry.image === true

    property string thumbnailPath: ""

    implicitHeight: isImage ? 80 : 46

    onEntryChanged: {
        thumbnailPath = "";
        if (isImage && !thumbnail.running)
            thumbnail.running = true;
    }
    onIsImageChanged: {
        if (isImage && thumbnailPath.length === 0 && !thumbnail.running)
            thumbnail.running = true;
    }

    Component.onCompleted: {
        if (isImage)
            thumbnail.running = true;
    }

    Process {
        id: thumbnail
        command: ["rvveber-fhud-clipboard", "thumbnail", root.entry.id]
        stdout: StdioCollector {
            onStreamFinished: root.thumbnailPath = text.trim()
        }
    }

    Image {
        visible: root.isImage && root.thumbnailPath.length > 0
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 128
        height: 80
        source: visible ? "file://" + root.thumbnailPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Surface {
        visible: root.isImage && root.thumbnailPath.length === 0
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 128
        height: 80
        color: Appearance.alpha(Appearance.surfaceActive, 0.7)

        Row {
            anchors.centerIn: parent
            spacing: Appearance.spaceCompact

            SegmentedRing {
                width: Appearance.controlHeight
                height: width
                working: thumbnail.running
                compact: true
                label: "Image preview"
            }

            HudText {
                anchors.verticalCenter: parent.verticalCenter
                text: thumbnail.running ? "LOADING" : "IMAGE"
                color: Appearance.foreground
                font.pixelSize: Appearance.textLabel
            }
        }
    }

    HudText {
        visible: root.isBinary && !root.isImage
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        text: root.entry.preview || "Binary data"
        color: Appearance.muted
        font.pixelSize: 12
        font.letterSpacing: 1
        maximumLineCount: 2
        elide: Text.ElideRight
        wrapMode: Text.Wrap
    }

    HudText {
        visible: root.active && !root.isBinary
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        text: root.entry.preview || "Empty text"
        font.pixelSize: 14
        maximumLineCount: 3
        elide: Text.ElideRight
        wrapMode: Text.Wrap
    }
}
