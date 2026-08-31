// @ts-nocheck
import { createState } from "gnim"
import { hyprlandService } from "./hyprland"

type HudMode = "apps" | "clipboard"

const [launcherVisible, setLauncherVisible] = createState(false)
const [hudMode, setHudMode] = createState<HudMode>("apps")
const [activeMonitorName, setActiveMonitorName] = createState<string | null>(null)
const [returnTargetAddress, setReturnTargetAddress] = createState<string | null>(null)

function syncActiveMonitor() {
  const focused = hyprlandService.focusedMonitor?.get?.()
  const name = focused?.name ?? focused?.get_name?.()
  if (name) {
    setActiveMonitorName(name)
  }
}

function syncReturnTarget() {
  const focused = hyprlandService.focusedClient?.get?.()
  const address = focused?.address ?? focused?.get_address?.()
  const normalized = typeof address === "string" && address.length > 0
    ? address.startsWith("0x") ? address : `0x${address}`
    : null
  setReturnTargetAddress(normalized)
}

function setDefaultMonitorName(name: string) {
  if (!activeMonitorName.get()) {
    setActiveMonitorName(name)
  }
}

function openLauncher(mode: HudMode = "apps") {
  console.log(`Opening launcher in mode: ${mode}`)
  syncActiveMonitor()
  syncReturnTarget()
  setHudMode(mode)
  setLauncherVisible(true)
}

function closeLauncher() {
  console.log("Closing launcher")
  setLauncherVisible(false)
}

function toggleLauncher(mode: HudMode = "apps") {
  const current = launcherVisible.get()
  syncActiveMonitor()
  if (!current) syncReturnTarget()

  if (mode !== hudMode.get()) {
    setHudMode(mode)
  }

  setLauncherVisible(!current)
}

export const hudService = {
  launcherVisible,
  hudMode,
  activeMonitorName,
  returnTargetAddress,
  openLauncher,
  closeLauncher,
  toggleLauncher,
  setHudMode,
  setDefaultMonitorName,
}
