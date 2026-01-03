// @ts-nocheck
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Pango from "gi://Pango?version=1.0"
import { hudService } from "../../services/hud"
import { For, createState, createComputed } from "gnim"
import Apps from "gi://AstalApps"

export default function Hud(gdkmonitor: Gdk.Monitor) {
  const { launcherVisible, activeMonitorName, closeLauncher } = hudService
  const apps = new Apps.Apps()
  const [list, setList] = createState(apps.get_list())
  const isVisible = createComputed((track) => {
    const visible = track(launcherVisible)
    const activeName = activeMonitorName ? track(activeMonitorName) : null
    return visible && (!activeName || activeName === gdkmonitor.connector)
  })
  
  let entry: Gtk.Entry

  function defaultList() {
    return [...apps.get_list()].sort((a, b) => {
      const diff = (b.frequency ?? 0) - (a.frequency ?? 0)
      if (diff !== 0) return diff
      return String(a.name).localeCompare(String(b.name))
    })
  }

  function search(text: string) {
    if (!text) setList(defaultList())
    else setList(apps.fuzzy_query(text))
  }

  function launch(app: Apps.Application) {
    closeLauncher()
    app.launch()
    setList(defaultList())
  }

  return (
    <window
      class="HudWindow"
      visible={isVisible((v) => {
        return v
      })}
      name={`hud-${gdkmonitor.connector}`}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      gdkmonitor={gdkmonitor}
      $={(self) => {
      }}
      onNotifyVisible={(self) => {
        if (self.visible) {
            entry?.grab_focus()
            entry?.set_text("")
            search("")
        }
      }}
    >
      <Gtk.EventControllerKey 
        onKeyPressed={(_, keyval) => {
            if (keyval === Gdk.KEY_Escape) {
                closeLauncher()
                return true
            }
        }}
      />
      <box
        class="HudOverlay"
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      >
        <box
          class="HudContainer"
          orientation={Gtk.Orientation.VERTICAL}
          widthRequest={560}
          spacing={16}
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
            <label class="HudTitle" label="Launch" />
            <label class="HudSubtitle" label="Type to search, Enter to open" />
          </box>
          <entry
              class="AppLauncher__search"
              $={(self) => entry = self}
              placeholderText="Search apps..."
              onChanged={(self) => search(self.text)}
              onActivate={() => {
                  const first = list()[0]
                  if (first) launch(first)
              }}
          />
          <Gtk.ScrolledWindow heightRequest={420} class="AppLauncher__list">
              <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
                  <For each={list}>
                      {(app) => {
                        const description = app.description ?? app.comment ?? app.exec ?? ""
                        return (
                          <button
                            class="AppItem"
                            onClicked={() => launch(app)}
                          >
                            <box spacing={12} valign={Gtk.Align.CENTER}>
                              <box class="AppItem__icon">
                                <image iconName={app.iconName} pixelSize={32} />
                              </box>
                              <box orientation={Gtk.Orientation.VERTICAL} spacing={2} hexpand>
                                <label class="AppItem__name" label={app.name} xalign={0} />
                                {description && (
                                  <label
                                    class="AppItem__description"
                                    label={description}
                                    xalign={0}
                                    ellipsize={Pango.EllipsizeMode.END}
                                  />
                                )}
                              </box>
                            </box>
                          </button>
                        )
                      }}
                  </For>
              </box>
          </Gtk.ScrolledWindow>
        </box>
      </box>
    </window>
  )
}
