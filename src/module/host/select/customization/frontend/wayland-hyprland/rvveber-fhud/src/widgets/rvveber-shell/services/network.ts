// @ts-nocheck
import Network from "gi://AstalNetwork"
import GLib from "gi://GLib"
import { createBinding, createComputed, createState } from "gnim"
import { execAsync } from "ags/process"

const network = Network.get_default()
const primary = network ? createBinding(network, "primary") : undefined
const state = network ? createBinding(network, "state") : undefined
const connectivity = network ? createBinding(network, "connectivity") : undefined
const wifi = network ? createBinding(network, "wifi") : undefined
const wired = network ? createBinding(network, "wired") : undefined

const [vpnInfo, setVpnInfo] = createState<{ name: string; device?: string } | null>(null)

async function refreshVpnInfo() {
  try {
    const output = await execAsync(["nmcli", "-t", "-f", "TYPE,NAME,DEVICE", "connection", "show", "--active"])
    const vpnLine = output
      .split("\n")
      .map((line) => line.trim())
      .find((line) => line.startsWith("vpn:"))
    if (!vpnLine) {
      setVpnInfo(null)
      return
    }
    const [, name, device] = vpnLine.split(":")
    setVpnInfo({
      name: name || "VPN",
      device: device || undefined,
    })
  } catch (error) {
    setVpnInfo(null)
  }
}

if (network) {
  refreshVpnInfo()
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 5000, () => {
    refreshVpnInfo()
    return true
  })
}

function normalizePrimary(primaryValue: any) {
  const text = primaryValue?.to_string?.()
  if (typeof text === "string" && text.length > 0) return text.toLowerCase()
  if (typeof primaryValue === "number") {
    if (primaryValue === 2) return "wifi"
    if (primaryValue === 1) return "wired"
  }
  return String(primaryValue ?? "unknown").toLowerCase()
}

function normalizeState(stateValue: any) {
  const text = stateValue?.to_string?.()
  if (typeof text === "string" && text.length > 0) return text.toLowerCase()
  if (typeof stateValue === "number") {
    if (stateValue >= 4) return "connected"
    if (stateValue === 3) return "connecting"
    if (stateValue === 2) return "disconnected"
  }
  return "unknown"
}

function formatStrength(strength?: number) {
  if (typeof strength !== "number" || Number.isNaN(strength)) return "--"
  return `${Math.round(strength)}%`
}

function formatFrequency(frequency?: number) {
  if (!Number.isFinite(frequency) || !frequency) return "--"
  const ghz = frequency / 1000
  return `${ghz.toFixed(2)} GHz`
}

function normalizeAccessPoints(points: any) {
  if (!points) return []
  if (Array.isArray(points)) return points
  if (typeof points[Symbol.iterator] === "function") {
    return Array.from(points as Iterable<any>)
  }
  return []
}

function formatConnectivity(value: any) {
  if (value?.to_string) {
    const text = value.to_string()
    if (typeof text === "string" && text.length > 0) return text
  }
  if (typeof value === "number") {
    if (value === 4) return "full"
    if (value === 3) return "limited"
    if (value === 2) return "portal"
    if (value === 1) return "none"
  }
  return "unknown"
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

const primaryMode = primary ? primary.as(normalizePrimary) : "unknown"

const primaryLabel = createComputed((track) => {
  const mode = primaryMode ? track(primaryMode) : "unknown"
  const wifiIface = wifi ? track(wifi) : null
  const wiredIface = wired ? track(wired) : null
  const wifiUp = wifiIface && normalizeState(wifiIface?.state).includes("connected")
  const wiredUp = wiredIface && normalizeState(wiredIface?.state).includes("connected")

  if (wifiUp) return "Wi-Fi"
  if (wiredUp) return "Ethernet"
  if (mode === "wifi") return "Wi-Fi"
  if (mode === "wired") return "Ethernet"
  return "Offline"
})

const wifiSsid = wifi ? wifi.as((iface) => iface?.ssid || "Wi-Fi") : "Wi-Fi"
const wifiConnected = wifi
  ? wifi.as((iface) => normalizeState(iface?.state).includes("connected"))
  : false
const wifiFrequency = wifi ? wifi.as((iface) => formatFrequency(iface?.frequency)) : "--"
const wifiEnabled = wifi ? wifi.as((iface) => Boolean(iface?.enabled)) : false
const wifiScanning = wifi ? wifi.as((iface) => Boolean(iface?.scanning)) : false
const wifiNetworks = wifi
  ? wifi.as((iface) => {
      const points = normalizeAccessPoints(iface?.access_points ?? iface?.accessPoints)
      return points
        .filter((point) => Boolean(point?.ssid))
        .sort((a, b) => (b?.strength ?? 0) - (a?.strength ?? 0))
        .slice(0, 8)
        .map((point) => ({
          ssid: point?.ssid ?? "Hidden",
          strength: point?.strength ?? 0,
          frequency: point?.frequency ?? 0,
          secure: Boolean(point?.requires_password),
        }))
    })
  : []

function setWifiEnabled(enabled: boolean) {
  wifi?.get?.()?.set_enabled?.(enabled)
}

function rescanWifi() {
  const iface = wifi?.get?.()
  if (!iface) return
  if (!iface?.enabled) {
    iface?.set_enabled?.(true)
  }
  iface?.scan?.()
}

const wiredName = wired
  ? wired.as((iface) => iface?.connection?.id ?? iface?.device?.interface ?? "Ethernet")
  : "Ethernet"
const wiredConnected = wired
  ? wired.as((iface) => normalizeState(iface?.state).includes("connected"))
  : false

const activeName = createComputed((track) => {
  const mode = primaryMode ? track(primaryMode) : "unknown"
  const wifiIface = wifi ? track(wifi) : null
  const wiredIface = wired ? track(wired) : null
  const wifiUp = wifiIface && normalizeState(wifiIface?.state).includes("connected")
  const wiredUp = wiredIface && normalizeState(wiredIface?.state).includes("connected")

  if (wifiUp) {
    return wifiIface?.ssid || "Wi-Fi"
  }
  if (wiredUp) {
    return wiredIface?.connection?.id ?? wiredIface?.device?.interface ?? "Ethernet"
  }
  if (mode === "wifi") {
    return wifiIface?.ssid || "Wi-Fi"
  }
  if (mode === "wired") {
    return wiredIface?.connection?.id ?? wiredIface?.device?.interface ?? "Ethernet"
  }
  if (wifiIface?.ssid) return wifiIface.ssid
  if (wiredIface) return wiredIface?.connection?.id ?? "Ethernet"
  return "Offline"
})

const wiredLabel = wired ? wired.as((iface) => iface?.active_connection?.id ?? "Wired") : "Wired"

const activeIcon = createComputed((track) => {
  const mode = primaryMode ? track(primaryMode) : "unknown"
  const wifiIface = wifi ? track(wifi) : null
  const wiredIface = wired ? track(wired) : null
  const wifiUp = wifiIface && normalizeState(wifiIface?.state).includes("connected")
  const wiredUp = wiredIface && normalizeState(wiredIface?.state).includes("connected")

  if (wifiUp) {
    return wifiIface?.icon_name ?? wifiIface?.iconName ?? "network-wireless-symbolic"
  }
  if (wiredUp) {
    return wiredIface?.icon_name ?? wiredIface?.iconName ?? "network-wired-symbolic"
  }

  if (mode === "wifi") {
    return wifiIface?.icon_name ?? wifiIface?.iconName ?? "network-wireless-symbolic"
  }
  if (mode === "wired") {
    return wiredIface?.icon_name ?? wiredIface?.iconName ?? "network-wired-symbolic"
  }
  return "network-offline-symbolic"
})

const activeStatus = createComputed((track) => {
  const netState = state ? track(state) : null
  const conn = connectivity ? track(connectivity) : null
  const stateLabel = normalizeState(netState)
  const connLabel = formatConnectivity(conn)
  if (stateLabel.includes("connected")) {
    return connLabel && connLabel !== "unknown"
      ? `Connected · ${connLabel.toLowerCase()}`
      : "Connected"
  }
  if (stateLabel.includes("connecting")) return "Connecting"
  if (stateLabel.includes("disconnected")) return "Disconnected"
  return "Offline"
})

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
  primaryMode,
  primaryLabel,
  wifiSsid,
  wifiConnected,
  wifiFrequency,
  wifiEnabled,
  wifiScanning,
  wifiNetworks,
  setWifiEnabled,
  rescanWifi,
  wiredName,
  wiredConnected,
  activeIcon,
  activeStatus,
  activeName,
  wiredLabel,
  vpnInfo,
}
