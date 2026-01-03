// @ts-nocheck
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { onCleanup } from "gnim"
import WorkspaceGrid from "./WorkspaceGrid.tsx"
import DateTimeDisplay from "./DateTimeDisplay.tsx"
import AudioModule from "./modules/AudioModule.tsx"
import BrightnessModule from "./modules/BrightnessModule.tsx"
import BatteryModule from "./modules/BatteryModule.tsx"
import BluetoothModule from "./modules/BluetoothModule.tsx"
import NetworkModule from "./modules/NetworkModule.tsx"
import NotificationModule from "./modules/NotificationModule.tsx"
import PowerModule from "./modules/PowerModule.tsx"

export default function TopBar(gdkmonitor: Gdk.Monitor) {
  let win: Astal.Window
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  onCleanup(() => {
    win?.destroy?.()
  })

  return (
    <window
      $={(self) => (win = self)}
      visible
      namespace="rvveber-topbar"
      name={`rvveber-topbar-${gdkmonitor.connector}`}
      class="TopBarWindow"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox class="TopBarLayout" halign={Gtk.Align.CENTER}>
        <WorkspaceGrid 
          $type="start" 
          class="TopBarSection" 
        />
        
        <DateTimeDisplay 
          $type="center"
          class="TopBarSection TopBarSection--center"
          halign={Gtk.Align.CENTER}
        />

        <box $type="end" spacing={4}>
          <AudioModule />
          <BrightnessModule />
          <BatteryModule />
          <BluetoothModule />
          <NetworkModule />
          <NotificationModule />
          <PowerModule />
        </box>
      </centerbox>
    </window>
  )
}
