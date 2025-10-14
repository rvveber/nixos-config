// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"
import Hyprland from "gi://AstalHyprland"
import { createBinding, createComputed } from "gnim"
import type { Accessor } from "gnim"

const TOTAL_WORKSPACES = 20
const WORKSPACE_INDICES = Array.from({ length: TOTAL_WORKSPACES }, (_, idx) => idx + 1)

const hyprland = Hyprland.get_default()
const workspaces = hyprland ? createBinding(hyprland, "workspaces") : undefined
const clients = hyprland ? createBinding(hyprland, "clients") : undefined
const focusedWorkspace = hyprland ? createBinding(hyprland, "focusedWorkspace") : undefined

function tileState(index: number): Accessor<string> | string {
  if (!hyprland || !workspaces || !clients) {
    return "WorkspaceTile WorkspaceTile--inactive"
  }

  return createComputed((track) => {
    const existingWorkspaces = track(workspaces) as unknown as any[]
    const workspace = existingWorkspaces.find((ws) => ws?.id === index)

    const clientList = track(clients) as unknown as any[]
    const isOccupied = clientList.some((client) => client?.workspace?.id === index)

    const focus = focusedWorkspace ? (track(focusedWorkspace) as unknown as any | null) : null
    const isFocused = focus?.id === index

    const classes = [
      "WorkspaceTile",
      isOccupied ? "WorkspaceTile--active" : "WorkspaceTile--inactive",
    ]

    if (!workspace) {
      classes.push("WorkspaceTile--virtual")
    }

    if (isFocused) {
      classes.push("WorkspaceTile--focused")
    }

    return classes.join(" ")
  })
}

export default function WorkspaceGrid() {
  const topTiles = WORKSPACE_INDICES.slice(0, 10).map(
    (index) =>
      (
        <box widthRequest={10} heightRequest={10} class={tileState(index)} />
      ) as unknown as Gtk.Widget,
  )

  const bottomTiles = WORKSPACE_INDICES.slice(10).map(
    (index) =>
      (
        <box widthRequest={10} heightRequest={10} class={tileState(index)} />
      ) as unknown as Gtk.Widget,
  )

  return (
    <box class="WorkspaceGrid" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
      <box spacing={2}>{topTiles as unknown as Gtk.Widget[]}</box>
      <box spacing={2}>{bottomTiles as unknown as Gtk.Widget[]}</box>
    </box>
  )
}
