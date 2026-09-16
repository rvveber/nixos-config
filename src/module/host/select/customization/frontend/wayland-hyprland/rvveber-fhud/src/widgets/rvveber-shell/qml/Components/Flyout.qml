import Quickshell
import QtQuick
import "../Theme"

PopupWindow {
    id: root

    property Item anchorItem
    property var controller: null
    property string section: ""
    property real minimumWidth: Appearance.flyoutWidth
    property real maximumWidth: Appearance.flyoutMaximumWidth
    default property alias content: contentColumn.data
    readonly property real naturalContentWidth: {
        let width = 0;
        for (const child of contentColumn.children) {
            if (child.visible)
                width = Math.max(width, child.implicitWidth);
        }
        return width;
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: Appearance.gap * 2
    grabFocus: true
    color: "transparent"
    implicitWidth: Math.min(maximumWidth, Math.max(minimumWidth, naturalContentWidth + Appearance.spaceRoomy * 2))
    implicitHeight: contentColumn.implicitHeight + Appearance.spaceRoomy * 2

    onVisibleChanged: {
        if (!controller || section.length === 0)
            return;
        if (visible && controller.openSection !== section)
            controller.openSection = section;
        else if (!visible && controller.openSection === section)
            controller.openSection = "";
    }

    EntryMotion {
        id: entry
        active: root.visible
    }

    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: root.visible
        onActivated: {
            if (root.controller)
                root.controller.dismiss();
            else
                root.visible = false;
        }
    }

    Component.onCompleted: {
        if (controller && section.length > 0)
            visible = controller.openSection === section;
    }

    Connections {
        target: root.controller
        enabled: root.controller !== null && root.section.length > 0

        function onOpenSectionChanged() {
            const shouldBeVisible = root.controller.openSection === root.section;
            if (root.visible !== shouldBeVisible)
                root.visible = shouldBeVisible;
        }
    }

    Surface {
        id: panel
        anchors.fill: parent
        focal: true
        reveal: entry.progress
        transform: Translate {
            y: (1 - entry.progress) * -Appearance.spaceCompact
        }

        Rectangle {
            width: Appearance.vectorLength * entry.progress
            height: Appearance.vectorLineWidth
            anchors.top: parent.top
            anchors.right: parent.right
            color: Appearance.accent
            visible: root.controller !== null && root.section.length > 0
        }

        Column {
            id: contentColumn
            opacity: entry.exposure
            anchors.fill: parent
            anchors.margins: Appearance.spaceRoomy
            spacing: Appearance.spaceRegular
        }
    }
}
