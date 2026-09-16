import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../Theme"
import "../Components"

PanelWindow {
    id: root

    required property QtObject shellState

    property var monitor: Hyprland.monitorFor(screen)
    property string query: ""
    property int selectedIndex: 0
    property var clipboardEntries: []
    property var applications: DesktopEntries.applications.values
    property var filteredApplications: applications.filter(app => {
        const needle = query.trim().toLowerCase();
        return needle.length === 0 || (app.name + " " + app.comment + " " + app.keywords.join(" ")).toLowerCase().indexOf(needle) >= 0;
    }).sort((a, b) => a.name.localeCompare(b.name)).slice(0, 12)
    property var filteredClipboard: clipboardEntries.filter(entry => query.trim().length === 0 || entry.preview.toLowerCase().indexOf(query.trim().toLowerCase()) >= 0).slice(0, 12)
    property var visibleModel: shellState.hudMode === "clipboard" ? filteredClipboard : filteredApplications

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0
    // Keep the layer surface alive on every output. Recreating a PopupWindow
    // when Hyprland focus changes races Quickshell 0.3's Wayland reparenting.
    visible: true
    property bool hudActive: shellState.hudVisible && monitor && monitor.focused
    color: hudActive ? Appearance.alpha(Appearance.background, Appearance.opacitySurface) : "transparent"
    mask: Region {
        width: root.hudActive ? root.width : 0
        height: root.hudActive ? root.height : 0
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: hudActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: {
        if (hudActive)
            prepareMode();
    }

    onHudActiveChanged: {
        if (hudActive)
            Qt.callLater(prepareMode);
    }

    function prepareMode(): void {
        search.text = "";
        selectedIndex = 0;
        search.forceActiveFocus();
        if (shellState.hudMode === "clipboard" && !clipboard.running)
            clipboard.running = true;
    }

    Connections {
        target: root.shellState

        function onHudModeChanged(): void {
            if (root.hudActive) {
                Qt.callLater(root.prepareMode);
                entry.replay();
            }
        }

        function onHudVisibleChanged(): void {
            if (root.hudActive)
                Qt.callLater(root.prepareMode);
        }
    }

    Process {
        id: clipboard
        command: ["rvveber-fhud-clipboard", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.clipboardEntries = text.trim().split("\n").map(line => {
                    const separator = line.indexOf("\t");
                    const preview = separator < 0 ? line : line.substring(separator + 1).replace(/\\n/g, "\n");
                    const normalized = preview.toLowerCase();
                    const binary = normalized.indexOf("binary data") >= 0 || normalized.indexOf("ftypavif") >= 0 || /[\u0000-\u0008\u000b\u000c\u000e-\u001f\ufffd]/u.test(preview);
                    return {
                        id: separator < 0 ? "" : line.substring(0, separator),
                        preview: preview,
                        binary: binary,
                        image: normalized.indexOf("ftypavif") >= 0 || (binary && /\b(?:avif|bmp|gif|heic|jpe?g|png|tiff?|webp)\b/u.test(normalized))
                    };
                }).filter(entry => entry.id.length > 0);
            }
        }
    }

    function activate(item): void {
        if (!item)
            return;
        shellState.hudVisible = false;
        if (shellState.hudMode === "clipboard") {
            const command = ["rvveber-fhud-clipboard", "paste", item.id];
            if (shellState.returnTarget)
                command.push(shellState.returnTarget);
            Quickshell.execDetached(command);
        } else {
            item.execute();
        }
    }

    function removeClipboard(item): void {
        if (!item)
            return;
        Quickshell.execDetached(["rvveber-fhud-clipboard", "delete", item.id]);
        clipboardEntries = clipboardEntries.filter(entry => entry.id !== item.id);
        selectedIndex = Math.min(selectedIndex, Math.max(0, visibleModel.length - 1));
    }

    Loader {
        anchors.fill: parent
        anchors.margins: Appearance.spaceRoomy * 2
        active: root.hudActive && shellState.hudMode === "demo"
        sourceComponent: Component {
            FutureHudDemo {}
        }
    }

    EntryMotion {
        id: entry
        active: root.hudActive && root.shellState.hudMode !== "demo"
    }

    Column {
        id: content
        visible: root.hudActive && shellState.hudMode !== "demo"
        width: Math.min(Appearance.flyoutMaximumWidth, parent.width - Appearance.spaceRoomy * 4)
        spacing: Appearance.spaceRoomy
        anchors.centerIn: parent
        opacity: entry.exposure
        transform: Translate {
            y: (1 - entry.progress) * Appearance.spaceRoomy
        }

        Item {
            width: parent.width
            height: title.implicitHeight

            HudText {
                id: title
                text: root.shellState.hudMode === "clipboard" ? "CLIPBOARD" : "APPLICATIONS"
                font.pixelSize: Appearance.textHeading
                font.letterSpacing: 2
                color: Appearance.foregroundStrong
            }

            HudText {
                anchors.right: parent.right
                anchors.baseline: title.baseline
                text: clipboard.running ? "READING HISTORY" : root.visibleModel.length + " SHOWN"
                font.pixelSize: Appearance.textLabel
                color: Appearance.foreground
            }

            Activity {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                life: clipboard.running ? "working" : "ready"
            }
        }

        Surface {
            width: parent.width
            height: Appearance.controlHeight + Appearance.spaceRoomy
            focal: search.activeFocus
            reveal: entry.progress

            TextInput {
                id: search
                anchors.fill: parent
                anchors.margins: Appearance.spaceRegular
                color: Appearance.foregroundStrong
                selectionColor: Appearance.accent
                selectedTextColor: Appearance.background
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.textHeading
                clip: true
                onTextChanged: {
                    root.query = text;
                    root.selectedIndex = 0;
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.shellState.hudVisible = false;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        root.selectedIndex = root.visibleModel.length > 0 ? Math.min(root.visibleModel.length - 1, root.selectedIndex + 1) : 0;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.activate(root.visibleModel[root.selectedIndex]);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Delete && root.shellState.hudMode === "clipboard") {
                        root.removeClipboard(root.visibleModel[root.selectedIndex]);
                        event.accepted = true;
                    }
                }

                Text {
                    anchors.fill: parent
                    visible: search.text.length === 0
                    text: root.shellState.hudMode === "clipboard" ? "Search clipboard history…" : "Search applications…"
                    color: Appearance.muted
                    font: search.font
                }
            }
        }

        ListView {
            id: resultList
            width: parent.width
            height: Math.min(Appearance.flyoutListHeight, Math.max(0, root.height - Appearance.controlHeight - title.height - content.spacing * 2 - Appearance.spaceRoomy * 5))
            spacing: Appearance.spaceCompact
            clip: true
            model: root.visibleModel
            currentIndex: root.selectedIndex

            delegate: Surface {
                id: result
                required property var modelData
                required property int index

                width: ListView.view.width
                height: root.shellState.hudMode === "clipboard" ? (result.modelData.image ? 100 : 66) : 62
                focal: index === root.selectedIndex
                color: Appearance.alpha(focal ? Appearance.accent : Appearance.surface, focal ? Appearance.opacityListActive : Appearance.opacityTrack)

                Row {
                    anchors.fill: parent
                    anchors.margins: Appearance.spaceRegular
                    spacing: Appearance.spaceCompact * 2

                    IconImage {
                        visible: root.shellState.hudMode === "apps"
                        width: 40
                        height: 40
                        source: visible ? Quickshell.iconPath(result.modelData.icon) : ""
                    }

                    ClipboardPreview {
                        visible: root.shellState.hudMode === "clipboard"
                        active: visible
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        entry: result.modelData
                    }

                    Column {
                        visible: root.shellState.hudMode === "apps"
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 52
                        spacing: Appearance.spaceTight

                        HudText {
                            width: parent.width
                            text: result.modelData.name || ""
                            font.bold: true
                            font.pixelSize: Appearance.textBody
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                        }
                        HudText {
                            width: parent.width
                            text: result.modelData.comment || result.modelData.genericName || result.modelData.execString || ""
                            color: Appearance.muted
                            font.pixelSize: Appearance.textLabel
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selectedIndex = result.index
                    onClicked: root.activate(result.modelData)
                }
            }
        }
    }
}
