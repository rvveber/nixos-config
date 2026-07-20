// @ts-nocheck
import { Astal, Gtk } from "ags/gtk4"
import { hyprlandService } from "../../services/hyprland"

const TOTAL_WORKSPACES = 20
const WORKSPACE_INDICES = Array.from({ length: TOTAL_WORKSPACES }, (_, idx) => idx + 1)

function WorkspaceTile({ index }: { index: number }) {
  return (
    <box
      widthRequest={10}
      heightRequest={10}
      class={hyprlandService.workspaceTileClass(index)}
    />
  )
}

export default function WorkspaceGrid({ className = "", ...props }: { className?: string } & Astal.BoxProps) {
  const topTiles = WORKSPACE_INDICES.slice(0, 10).map((index) => (
    <WorkspaceTile index={index} />
  ))

  const bottomTiles = WORKSPACE_INDICES.slice(10).map((index) => (
    <WorkspaceTile index={index} />
  ))

  return (
    <box 
      class={`WorkspaceGrid ${className}`} 
      orientation={Gtk.Orientation.VERTICAL} 
      spacing={2}
      {...props}
    >
      <box spacing={2}>{topTiles as unknown as Gtk.Widget[]}</box>
      <box spacing={2}>{bottomTiles as unknown as Gtk.Widget[]}</box>
    </box>
  )
}
