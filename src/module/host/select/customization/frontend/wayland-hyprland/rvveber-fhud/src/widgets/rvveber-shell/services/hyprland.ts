// @ts-nocheck
import Hyprland from "gi://AstalHyprland"
import GLib from "gi://GLib?version=2.0"
import { createBinding, createComputed } from "gnim"

const hyprland = Hyprland.get_default()

const workspaces = hyprland ? createBinding(hyprland, "workspaces") : undefined
const clients = hyprland ? createBinding(hyprland, "clients") : undefined
const monitors = hyprland ? createBinding(hyprland, "monitors") : undefined
const focusedWorkspace = hyprland ? createBinding(hyprland, "focusedWorkspace") : undefined
const focusedMonitor = hyprland ? createBinding(hyprland, "focusedMonitor") : undefined
const focusedClient = hyprland ? createBinding(hyprland, "focusedClient") : undefined

function workspaceBase(id: number) {
  return Math.floor((id - 1) / workspaceSpan) * workspaceSpan + 1
}

const configuredWorkspaceSpan = Number(GLib.getenv("RVVEBER_FHUD_WORKSPACES_PER_MONITOR") ?? "10")
export const workspaceSpan =
  Number.isInteger(configuredWorkspaceSpan) && configuredWorkspaceSpan >= 10 ? configuredWorkspaceSpan : 10

function activeWorkspaceId(monitor: any) {
  return monitor?.activeWorkspace?.id ?? monitor?.get_active_workspace?.()?.id
}

function arrangeWorkspaceGroups(bases: number[]) {
  const configured = GLib.getenv("RVVEBER_FHUD_WORKSPACE_GROUPS")
  if (configured) {
    const available = new Set(bases)
    const assigned = new Set<number>()
    const groups = configured
      .split(";")
      .map((group) =>
        group
          .split(",")
          .map(Number)
          .filter((base) => {
            if (!available.has(base) || assigned.has(base)) return false
            assigned.add(base)
            return true
          }),
      )
      .filter((group) => group.length > 0)

    for (const base of bases) {
      if (!assigned.has(base)) groups.push([base])
    }
    if (groups.length > 0) return groups
  }

  if (bases.length < 2) return bases.map((base) => [base])
  return [[bases[0]], bases.slice(1)]
}

const workspaceGroups = createComputed((track) => {
  if (!monitors) return []

  if (focusedWorkspace) track(focusedWorkspace)
  const monitorList = track(monitors) as unknown as any[]
  const bases = Array.from(
    new Set(
      monitorList
        .map((monitor) => activeWorkspaceId(monitor))
        .filter((id): id is number => Number.isInteger(id) && id > 0)
        .map(workspaceBase),
    ),
  ).sort((a, b) => a - b)

  return arrangeWorkspaceGroups(bases).map((group) => ({
    key: `group:${group.join("+")}`,
    bases: group,
  }))
})

export const hyprlandService = {
  focusedClient,
  focusedMonitor,
  workspaceGroups,
  workspaceTileClass(bases: number[], offset: number) {
    if (!hyprland || !workspaces || !clients || !monitors) {
      return "WorkspaceTile WorkspaceTile--inactive"
    }

    return createComputed((track) => {
      const ids = bases.map((base) => base + offset)
      const existingWorkspaces = track(workspaces) as unknown as any[]
      const workspaceExists = existingWorkspaces.some((workspace) => ids.includes(workspace?.id))

      const clientList = track(clients) as unknown as any[]
      const isOccupied = clientList.some((client) => ids.includes(client?.workspace?.id))

      const monitorList = track(monitors) as unknown as any[]
      const isVisible = monitorList.some((monitor) => ids.includes(activeWorkspaceId(monitor)))

      const focus = focusedWorkspace ? (track(focusedWorkspace) as unknown as any | null) : null
      const isFocused = ids.includes(focus?.id)

      const classes = [
        "WorkspaceTile",
        isOccupied ? "WorkspaceTile--occupied" : "WorkspaceTile--inactive",
      ]

      if (!workspaceExists) {
        classes.push("WorkspaceTile--virtual")
      }

      if (isVisible) classes.push("WorkspaceTile--visible")
      if (isFocused) {
        classes.push("WorkspaceTile--focused")
      }

      return classes.join(" ")
    })
  },
}
