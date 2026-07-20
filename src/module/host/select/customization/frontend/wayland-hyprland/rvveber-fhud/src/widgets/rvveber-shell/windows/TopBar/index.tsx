// @ts-nocheck
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { onCleanup } from "gnim"
import WorkspaceGrid from "./WorkspaceGrid"
import DateTimeDisplay from "./DateTimeDisplay"
import { TOP_BAR_MODULES } from "./modules/index"

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
          {TOP_BAR_MODULES.map((Module) => (
            <Module />
          ))}
        </box>
      </centerbox>
    </window>
  )
}
