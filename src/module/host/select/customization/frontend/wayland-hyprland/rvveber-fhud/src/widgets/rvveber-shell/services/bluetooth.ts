// @ts-nocheck
import Bluetooth from "gi://AstalBluetooth"
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

export const bluetoothService = {
  bluetooth,
  devices,
  adapter,
  adapterPowered,
  adapterDiscovering,
  summary,
  toArray,
}
