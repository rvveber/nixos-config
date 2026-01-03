// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"
import { For, createBinding } from "gnim"
import { bluetoothService } from "../../../services/bluetooth"
import { IconBadge, PopoverCard, IconButton } from "../../../components"

function DeviceRow({ device }: { device: any }) {
  const alias = createBinding(device, "alias")
  const connected = createBinding(device, "connected")
  const connecting = createBinding(device, "connecting")
  const icon = createBinding(device, "icon")

  const name = alias?.((value) => value || "Unknown device")

  function toggleConnection() {
    if (!device) return
    bluetoothService.adapter?.set_powered(true)
    if (device.connecting || device.connected) {
      device.disconnect_device?.(null)
    } else {
      device.connect_device?.(null)
    }
  }

  return (
    <button class="DeviceButton" focusable onClicked={toggleConnection}>
      <box spacing={6} valign={Gtk.Align.CENTER}>
        <image iconName={icon} pixelSize={18} />
        <label xalign={0} hexpand label={name} />
        <Gtk.Revealer
          transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
          revealChild={connected}
        >
          <label class="StatusLabel" label="Connected" />
        </Gtk.Revealer>
        <Gtk.Revealer
          revealChild={connecting}
          transitionType={Gtk.RevealerTransitionType.CROSSFADE}
        >
          <Gtk.Spinner spinning />
        </Gtk.Revealer>
      </box>
    </button>
  )
}

function AdapterToolbar() {
  const { adapter, adapterPowered, adapterDiscovering } = bluetoothService

  if (!adapter) {
    return <label label="No adapter" opacity={0.6} />
  }

  function togglePower() {
    adapter.set_powered?.(!adapter.powered)
  }

  function toggleScan() {
    if (adapter.discovering) {
      adapter.stop_discovery?.()
    } else {
      adapter.start_discovery?.()
    }
  }

  return (
    <box spacing={6}>
      <IconButton
        className="IconAction"
        icon="bluetooth-active-symbolic"
        tooltip="Toggle power"
        onClicked={togglePower}
      >
        <label label={adapterPowered?.as((state) => (state ? "Turn Off" : "Turn On"))} />
      </IconButton>
      <IconButton
        className="IconAction"
        icon="view-refresh-symbolic"
        tooltip="Scan"
        onClicked={toggleScan}
      >
        <label label={adapterDiscovering?.as((active) => (active ? "Stop" : "Scan"))} />
      </IconButton>
    </box>
  )
}

export default function BluetoothModule() {
  const { bluetooth, devices, summary } = bluetoothService

  if (!bluetooth) {
    return null
  }

  return (
    <box class="TopBarSection TopBarSection--item">
      <menubutton
        class="TopBarButton"
        focusable
        receivesDefault
        tooltipText={summary}
      >
        <IconBadge icon="bluetooth-symbolic" text={summary} />
        <PopoverCard width={360} className="BluetoothPopover">
          <box spacing={10} orientation={Gtk.Orientation.VERTICAL}>
            <box spacing={6} valign={Gtk.Align.CENTER}>
              <label class="SectionTitle" label="Bluetooth" />
              <AdapterToolbar />
            </box>
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
              <label class="SectionLabel" label="Devices" />
              <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                {devices ? (
                  <For each={devices}>{(device) => <DeviceRow device={device} />}</For>
                ) : (
                  <label label="No devices" opacity={0.6} />
                )}
              </box>
            </box>
          </box>
        </PopoverCard>
      </menubutton>
    </box>
  )
}
