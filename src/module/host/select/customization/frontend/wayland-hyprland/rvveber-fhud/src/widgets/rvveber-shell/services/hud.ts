// @ts-nocheck
import { createState } from "gnim"
import { hyprlandService } from "./hyprland"

type HudMode = "apps" | "clipboard"

const [launcherVisible, setLauncherVisible] = createState(false)
const [hudMode, setHudMode] = createState<HudMode>("apps")
const [activeMonitorName, setActiveMonitorName] = createState<string | null>(null)

function syncActiveMonitor() {
  const focused = hyprlandService.focusedMonitor?.get?.()
  const name = focused?.name ?? focused?.get_name?.()
  if (name) {
    setActiveMonitorName(name)
  }
}

function setDefaultMonitorName(name: string) {
  if (!activeMonitorName.get()) {
    setActiveMonitorName(name)
  }
}

function openLauncher(mode: HudMode = "apps") {
  console.log(`Opening launcher in mode: ${mode}`)
  syncActiveMonitor()
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

  if (mode !== hudMode.get()) {
    setHudMode(mode)
  }

  setLauncherVisible(!current)
}

export const hudService = {
  launcherVisible,
  hudMode,
  activeMonitorName,
  openLauncher,
  closeLauncher,
  toggleLauncher,
  setHudMode,
  setDefaultMonitorName,
}
