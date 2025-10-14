// @ts-nocheck
import Battery from "gi://AstalBattery"
import { createBinding } from "gnim"

const battery = Battery.get_default()

const isPresent = battery ? createBinding(battery, "isPresent") : undefined
const percentRaw = battery ? createBinding(battery, "percentage") : undefined
const percentLabel = percentRaw ? percentRaw.as((value) => `${Math.round((value ?? 0) * 100)}`) : undefined
const icon = battery ? createBinding(battery, "iconName") : undefined
const state = battery ? createBinding(battery, "state") : undefined
const timeToEmpty = battery ? createBinding(battery, "timeToEmpty") : undefined
const timeToFull = battery ? createBinding(battery, "timeToFull") : undefined
const temperature = battery ? createBinding(battery, "temperature") : undefined

function formatDuration(seconds: number) {
  if (!Number.isFinite(seconds) || seconds <= 0) {
    return "--"
  }

  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  if (hours === 0) {
    return `${minutes}m`
  }
  return `${hours}h ${minutes}m`
}

export const batteryService = {
  battery,
  isPresent,
  percentRaw,
  percentLabel,
  icon,
  state,
  timeToEmpty,
  timeToFull,
  temperature,
  tooltip: percentLabel?.as((value) => `Battery ${value}%`),
  formatDuration,
}
