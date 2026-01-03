// @ts-nocheck
import Hyprland from "gi://AstalHyprland"
import { createBinding, createComputed } from "gnim"

const hyprland = Hyprland.get_default()

const workspaces = hyprland ? createBinding(hyprland, "workspaces") : undefined
const clients = hyprland ? createBinding(hyprland, "clients") : undefined
const focusedWorkspace = hyprland ? createBinding(hyprland, "focusedWorkspace") : undefined
const focusedMonitor = hyprland ? createBinding(hyprland, "focusedMonitor") : undefined

export const hyprlandService = {
  hyprland,
  workspaces,
  clients,
  focusedWorkspace,
  focusedMonitor,
  workspaceTileClass(index: number) {
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
  },
}
