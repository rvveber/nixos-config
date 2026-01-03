// @ts-nocheck
import { execAsync } from "ags/process"
import { interval, timeout } from "ags/time"
import { createState } from "gnim"

const BRIGHTNESS_CMD = ["brightnessctl", "-m"]

type BrightnessState = {
  available: boolean
  percent: number
}

function clampPercent(value: number): number {
  if (Number.isNaN(value)) return 0
  return Math.min(Math.max(value, 0), 1)
}

function parseBrightness(stdout: string): BrightnessState {
  const parts = stdout.trim().split(",")
  if (parts.length < 5) {
    return { available: false, percent: 0 }
  }

  const percent = Number(parts[3]?.replace("%", "")) / 100
  return {
    available: true,
    percent: clampPercent(percent),
  }
}

const [brightness, setBrightnessState] = createState<BrightnessState>({
  available: false,
  percent: 0,
})

const [percent, setPercent] = createState(0)

let pendingTimer: import("ags/time").Timer | null = null
let pendingTarget: number | null = null
let isApplying = false
let lastUserChange = 0

async function refreshBrightnessState(force = false) {
  // Skip if we have pending changes or recently changed by user
  const timeSinceUserChange = Date.now() - lastUserChange
  if (!force && (pendingTimer || isApplying || timeSinceUserChange < 2000)) {
    return
  }

  try {
    const stdout = await execAsync(BRIGHTNESS_CMD)
    const state = parseBrightness(stdout)
    setBrightnessState(state)
    setPercent(state.percent)
  } catch (error) {
    console.warn("brightnessctl not available", error)
    setBrightnessState((prev) => ({
      available: false,
      percent: prev.percent,
    }))
  }
}

// Poll every second to stay in sync with the actual brightness
interval(1000, () => refreshBrightnessState(false))

// Populate initial state immediately
void refreshBrightnessState(true)

async function setBrightness(value: number) {
  const clamped = clampPercent(value)
  
  // Mark that user just changed brightness
  lastUserChange = Date.now()
  
  // Optimistically update UI so slider moves instantly
  setBrightnessState({ available: true, percent: clamped })
  setPercent(clamped)

  pendingTarget = clamped
  if (pendingTimer) {
    pendingTimer.cancel()
    pendingTimer = null
  }

  pendingTimer = timeout(120, () => {
    pendingTimer = null
    const target = pendingTarget
    if (target == null) {
      return
    }

    pendingTarget = null
    isApplying = true
    void (async () => {
      try {
        await execAsync(["brightnessctl", "set", `${Math.round(target * 100)}%`])
      } catch (error) {
        console.error("Failed to set brightness", error)
      } finally {
        isApplying = false
        void refreshBrightnessState(true)
      }
    })()
  })
}

export const brightnessService = {
  brightness,
  percent,
  setBrightness,
}
