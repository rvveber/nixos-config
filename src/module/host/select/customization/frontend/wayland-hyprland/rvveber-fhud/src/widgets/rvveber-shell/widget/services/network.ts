// @ts-nocheck
import Network from "gi://AstalNetwork"
import { createBinding, createComputed } from "gnim"
import { execAsync } from "ags/process"

const network = Network.get_default()
const primary = network ? createBinding(network, "primary") : undefined
const state = network ? createBinding(network, "state") : undefined
const connectivity = network ? createBinding(network, "connectivity") : undefined
const wifi = network ? createBinding(network, "wifi") : undefined
const wired = network ? createBinding(network, "wired") : undefined

function formatStrength(strength?: number) {
  if (typeof strength !== "number" || Number.isNaN(strength)) return "--"
  return `${Math.round(strength)}%`
}

const tooltip = primary
  ? createComputed([primary, state, connectivity], (p, s, c) => {
      const primaryLabel = p?.to_string?.() ?? "unknown"
      const stateLabel = s?.to_string?.() ?? "unknown"
      const connLabel = c?.to_string?.() ?? "unknown"
      return `Network: ${primaryLabel} • State: ${stateLabel} • Connectivity: ${connLabel}`
    })
  : "Network"

const signalStrength = wifi
  ? wifi.as((iface) => formatStrength(iface?.strength))
  : "--"

const wifiIcon = wifi
  ? wifi.as((iface) => iface?.icon_name ?? iface?.iconName ?? "network-wireless-symbolic")
  : "network-wireless-symbolic"

const wiredSpeed = wired ? wired.as((iface) => iface?.speed ?? 0) : undefined

const activeName = wifi
  ? wifi.as((iface) => iface?.ssid || "Wi-Fi")
  : primary?.as((p) => (p?.to_string?.() === "wired" ? "Ethernet" : "Offline")) ?? "Network"

const wiredLabel = wired
  ? wired.as((iface) => iface?.active_connection?.id ?? "Wired")
  : "Wired"

async function reconnectVpn() {
  try {
    await execAsync(["mullvad", "relay", "switch"])
  } catch (error) {
    console.error("Failed to reconnect Mullvad", error)
  }
}

export const networkService = {
  network,
  wifi,
  wired,
  primary,
  state,
  connectivity,
  tooltip,
  signalStrength,
  wifiIcon,
  wiredSpeed,
  activeName,
  wiredLabel,
  reconnectVpn,
}
