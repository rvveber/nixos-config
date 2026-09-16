import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../Theme"
import "../Components"

Column {
    id: root

    readonly property var hyprlandMonitors: Hyprland.monitors.values
    readonly property var hyprlandWorkspaces: Hyprland.workspaces.values
    readonly property int focusedWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
    readonly property int workspaceSpan: {
        const configured = Number(Quickshell.env("RVVEBER_FHUD_WORKSPACES_PER_MONITOR") || "10");
        return Number.isInteger(configured) && configured >= 10 ? configured : 10;
    }
    readonly property var groups: arrangeGroups()

    spacing: Appearance.spaceTight

    function workspaceBase(id: int): int {
        return Math.floor((id - 1) / workspaceSpan) * workspaceSpan + 1;
    }

    function arrangeGroups(): var {
        const bases = Array.from(new Set(root.hyprlandMonitors.map(monitor => workspaceBase(monitor.activeWorkspace ? monitor.activeWorkspace.id : 0)).filter(base => base > 0))).sort((a, b) => a - b);
        const configured = Quickshell.env("RVVEBER_FHUD_WORKSPACE_GROUPS") || "";

        if (configured.length > 0) {
            const available = new Set(bases);
            const assigned = new Set();
            const result = configured.split(";").map(definition => definition.split(",").map(Number).filter(base => {
                    if (!available.has(base) || assigned.has(base))
                        return false;
                    assigned.add(base);
                    return true;
                })).filter(group => group.length > 0);
            bases.forEach(base => {
                if (!assigned.has(base))
                    result.push([base]);
            });
            if (result.length > 0)
                return result;
        }

        if (bases.length < 2)
            return bases.map(base => [base]);
        return [[bases[0]], bases.slice(1)];
    }

    Repeater {
        model: root.groups

        Row {
            id: groupRow

            required property var modelData

            readonly property bool focusedGroup: modelData.indexOf(root.workspaceBase(root.focusedWorkspaceId)) >= 0
            spacing: Appearance.spaceCompact

            HudText {
                width: Appearance.readoutValueWidth
                anchors.verticalCenter: parent.verticalCenter
                text: groupRow.modelData.join("+")
                color: groupRow.focusedGroup ? Appearance.accent : Appearance.foreground
                font.pixelSize: Appearance.textLabel
                elide: Text.ElideRight
                Accessible.name: "Workspace ranges " + groupRow.modelData.join(", ")
            }

            Item {
                width: slots.implicitWidth
                height: Appearance.workspaceLaneHeight

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Appearance.vectorLineWidth
                    color: Appearance.alpha(Appearance.accent, Appearance.opacityQuiet)
                }

                Rectangle {
                    visible: groupRow.focusedGroup
                    x: Math.max(0, root.focusedWorkspaceId - root.workspaceBase(root.focusedWorkspaceId)) * (Appearance.workspaceSlotWidth + Appearance.spaceTight)
                    anchors.bottom: parent.bottom
                    width: Appearance.workspaceSlotWidth
                    height: Appearance.vectorLineWidth
                    color: Appearance.foregroundStrong
                    Behavior on x {
                        NumberAnimation {
                            duration: Appearance.motionMove
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Row {
                    id: slots
                    spacing: Appearance.spaceTight

                    Repeater {
                        model: root.workspaceSpan

                        WorkspaceSlot {
                            required property int index
                            readonly property var workspaceIds: groupRow.modelData.map(base => base + index)
                            readonly property var workspaces: root.hyprlandWorkspaces.filter(workspace => workspaceIds.indexOf(workspace.id) >= 0)

                            number: index === 9 ? 0 : index + 1
                            windows: workspaces.reduce((count, workspace) => count + (workspace.toplevels ? workspace.toplevels.values.length : 0), 0)
                            current: root.hyprlandMonitors.some(monitor => monitor.activeWorkspace && workspaceIds.indexOf(monitor.activeWorkspace.id) >= 0)
                            urgent: workspaces.some(workspace => workspace.urgent)
                            description: "Workspace IDs " + workspaceIds.join(", ")
                            onActivated: Quickshell.execDetached(["rvveber-fhud-switch-workspace-group", number.toString(), groupRow.modelData[0].toString()])
                        }
                    }
                }
            }
        }
    }
}
