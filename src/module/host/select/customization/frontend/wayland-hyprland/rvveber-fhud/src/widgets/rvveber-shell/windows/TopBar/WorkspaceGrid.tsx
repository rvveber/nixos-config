// @ts-nocheck
import { Astal, Gtk } from "ags/gtk4"
import { For } from "gnim"
import { hyprlandService, workspaceSpan } from "../../services/hyprland"

const WORKSPACE_OFFSETS = Array.from({ length: workspaceSpan }, (_, index) => index)

function WorkspaceTile({ bases, offset }: { bases: number[]; offset: number }) {
  return (
    <box
      widthRequest={10}
      heightRequest={10}
      class={hyprlandService.workspaceTileClass(bases, offset)}
    />
  )
}

export default function WorkspaceGrid({ className = "", ...props }: { className?: string } & Astal.BoxProps) {
  return (
    <box
      class={`WorkspaceGrid ${className}`}
      orientation={Gtk.Orientation.VERTICAL}
      spacing={2}
      {...props}
    >
      <For each={hyprlandService.workspaceGroups}>
        {(group) => (
          <box spacing={2}>
            {WORKSPACE_OFFSETS.map((offset) => (
              <WorkspaceTile bases={group.bases} offset={offset} />
            )) as unknown as Gtk.Widget[]}
          </box>
        )}
      </For>
    </box>
  )
}
