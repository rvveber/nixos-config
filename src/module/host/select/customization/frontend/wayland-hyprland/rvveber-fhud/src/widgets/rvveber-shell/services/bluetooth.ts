// @ts-nocheck
import Bluetooth from "gi://AstalBluetooth"
import GLib from "gi://GLib"
import { createBinding, createComputed } from "gnim"

const bluetooth = Bluetooth.get_default()
const devices = bluetooth ? createBinding(bluetooth, "devices") : undefined
const adapter = bluetooth?.get_adapter?.() ?? null
const adapterPowered = adapter ? createBinding(adapter, "powered") : undefined
const adapterDiscovering = adapter ? createBinding(adapter, "discovering") : undefined

function toArray(list: any): any[] {
  if (!list) return []
  if (Array.isArray(list)) return list
  if (typeof list[Symbol.iterator] === "function") {
    return Array.from(list as Iterable<any>)
  }

  const result: any[] = []
  let node = list
  while (node) {
    result.push(node.data ?? node.value ?? node)
    node = node.next
  }
  return result
}

const summary = devices
  ? createComputed([devices], (list) => {
      const arr = toArray(list)
      const connected = arr.find((device) => device?.connected)
      if (connected) {
        return connected.alias || connected.name || "Connected"
      }
      if (!adapter) return "Bluetooth unavailable"
      return adapter.powered ? "No device" : "Bluetooth Off"
    })
  : "Bluetooth"

function ensurePowered() {
  adapter?.set_powered?.(true)
}

function setTrusted(device: any, trusted: boolean) {
  try {
    device.trusted = trusted
  } catch (error) {
    console.error("Bluetooth trust update failed:", error)
  }
}

function isIgnorableBtError(error: unknown) {
  const message = String(error ?? "")
  return /AlreadyExists|InProgress|Already Exists|NotConnected|DoesNotExist/i.test(message)
}

function pairIfNeeded(device: any) {
  if (device.paired) return
  try {
    device.pair?.()
  } catch (error) {
    if (!isIgnorableBtError(error)) {
      console.error("Bluetooth pair failed:", error)
    }
  }
}

function startConnect(device: any) {
  try {
    device.connect_device?.(null)
  } catch (error) {
    if (!isIgnorableBtError(error)) {
      console.error("Bluetooth connect failed:", error)
    }
  }
}

/**
 * Connect flow:
 * 1. power adapter
 * 2. trust immediately
 * 3. pair if not already paired
 * 4. connect (retry briefly while pairing settles)
 */
function connectDevice(device: any) {
  if (!device || device.connecting || device.connected) return
  ensurePowered()

  // Trust right away so the device is authorized after pairing/connect.
  setTrusted(device, true)
  pairIfNeeded(device)
  startConnect(device)

  // If pair is still settling, retry connect a few times.
  if (!device.paired) {
    let attempts = 0
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
      attempts += 1
      if (!device || device.connected || device.connecting) return GLib.SOURCE_REMOVE
      if (device.paired || attempts >= 8) {
        startConnect(device)
        return GLib.SOURCE_REMOVE
      }
      if (attempts % 2 === 0) pairIfNeeded(device)
      startConnect(device)
      return GLib.SOURCE_CONTINUE
    })
  }
}

function disconnectDevice(device: any) {
  if (!device) return
  try {
    device.disconnect_device?.(null)
  } catch (error) {
    if (!isIgnorableBtError(error)) {
      console.error("Bluetooth disconnect failed:", error)
    }
  }
}

function removeDevice(device: any) {
  if (!adapter || !device) return
  setTrusted(device, false)
  try {
    adapter.remove_device?.(device)
  } catch (error) {
    if (!isIgnorableBtError(error)) {
      console.error("Bluetooth remove failed:", error)
    }
  }
}

/** Untrust and permanently remove pairing for a device. */
function forgetDevice(device: any) {
  if (!device || !adapter) return

  let finished = false
  const finish = () => {
    if (finished) return
    finished = true
    removeDevice(device)
  }

  if (device.connected || device.connecting) {
    try {
      device.disconnect_device?.(() => finish())
      // Fallback if the async disconnect callback never fires.
      GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1500, () => {
        finish()
        return GLib.SOURCE_REMOVE
      })
      return
    } catch (error) {
      if (!isIgnorableBtError(error)) {
        console.error("Bluetooth disconnect before forget failed:", error)
      }
    }
  }

  finish()
}

function toggleDeviceConnection(device: any) {
  if (!device) return
  if (device.connecting || device.connected) {
    disconnectDevice(device)
  } else {
    connectDevice(device)
  }
}

export const bluetoothService = {
  bluetooth,
  devices,
  adapter,
  adapterPowered,
  adapterDiscovering,
  summary,
  connectDevice,
  disconnectDevice,
  forgetDevice,
  toggleDeviceConnection,
}
