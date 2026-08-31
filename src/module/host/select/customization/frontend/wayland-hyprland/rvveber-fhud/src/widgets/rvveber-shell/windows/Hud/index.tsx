// @ts-nocheck
import app from "ags/gtk4/app"
import { Gtk, Gdk } from "ags/gtk4"
import { createComputed, createState, For } from "gnim"
import Pango from "gi://Pango?version=1.0"
import Apps from "gi://AstalApps"
import { clipboardService } from "../../services/clipboard"
import type { ClipboardEntry } from "../../services/clipboard"
import { hudService } from "../../services/hud"

const apps = new Apps.Apps()
const MAX_APPS = 9

type HudItem =
  | { key: string; kind: "app"; app: Apps.Application }
  | { key: string; kind: "clipboard"; entry: ClipboardEntry }

function defaultApps() {
  return [...apps.get_list()]
    .sort((a, b) => {
      const frequency = (b.frequency ?? 0) - (a.frequency ?? 0)
      return frequency || String(a.name).localeCompare(String(b.name))
    })
    .slice(0, MAX_APPS)
}

function findApps(text: string) {
  return (text ? apps.fuzzy_query(text) : defaultApps()).slice(0, MAX_APPS)
}

export default function Hud(gdkmonitor: Gdk.Monitor) {
  const { launcherVisible, hudMode, activeMonitorName, returnTargetAddress, closeLauncher } = hudService
  const [list, setList] = createState(new Array<HudItem>())
  const [selectedIndex, setSelectedIndex] = createState(0)
  const itemWidgets = new Map<string, Gtk.Widget>()
  let entry: Gtk.Entry
  let query = ""
  let refreshGeneration = 0

  const isVisible = createComputed((track) => {
    const visible = track(launcherVisible)
    const activeName = activeMonitorName ? track(activeMonitorName) : null
    return visible && (!activeName || activeName === gdkmonitor.connector)
  })

  const title = hudMode((mode) => (mode === "clipboard" ? "Clipboard" : "Launch"))
  const subtitle = hudMode((mode) =>
    mode === "clipboard" ? "Enter to paste · Delete to remove" : "Type to search · Enter to open",
  )
  const placeholder = hudMode((mode) =>
    mode === "clipboard" ? "Search clipboard history..." : "Search apps...",
  )

  function setItems(items: HudItem[]) {
    setList(items)
    setSelectedIndex(0)
  }

  function searchApps(text: string) {
    setItems(
      findApps(text).map((application) => ({
        key: `app:${application.entry}`,
        kind: "app",
        app: application,
      })),
    )
  }

  function searchClipboard(text: string) {
    setItems(
      clipboardService.query(text).map((clipboardEntry) => ({
        key: `clipboard:${clipboardEntry.id}`,
        kind: "clipboard",
        entry: clipboardEntry,
      })),
    )
  }

  async function refreshClipboard() {
    const generation = ++refreshGeneration
    await clipboardService.refresh()
    if (generation === refreshGeneration) searchClipboard(query)
  }

  function search(text: string) {
    query = text
    if (hudMode.get() === "clipboard") searchClipboard(text)
    else searchApps(text)
  }

  async function activate(item?: HudItem) {
    if (!item) return

    closeLauncher()
    if (item.kind === "app") {
      item.app.launch()
      return
    }

    try {
      await clipboardService.paste(item.entry, returnTargetAddress.get())
    } catch (error) {
      console.error(`Failed to paste clipboard entry: ${error}`)
    }
  }

  async function removeSelected() {
    const item = list.get()[selectedIndex.get()]
    if (!item || item.kind !== "clipboard") return

    try {
      await clipboardService.remove(item.entry)
      searchClipboard(query)
    } catch (error) {
      console.error(`Failed to delete clipboard entry: ${error}`)
    }
  }

  function moveSelection(offset: number) {
    const items = list.get()
    if (items.length === 0) return

    const next = Math.max(0, Math.min(items.length - 1, selectedIndex.get() + offset))
    setSelectedIndex(next)

    const widget = itemWidgets.get(items[next].key)
    widget?.grab_focus()
    entry?.grab_focus()
  }

  function onKeyPressed(_: Gtk.EventControllerKey, keyval: number) {
    if (keyval === Gdk.KEY_Escape) {
      closeLauncher()
      return true
    }
    if (keyval === Gdk.KEY_Up) {
      moveSelection(-1)
      return true
    }
    if (keyval === Gdk.KEY_Down) {
      moveSelection(1)
      return true
    }
    if (keyval === Gdk.KEY_Return || keyval === Gdk.KEY_KP_Enter) {
      void activate(list.get()[selectedIndex.get()])
      return true
    }
    if (keyval === Gdk.KEY_Delete && hudMode.get() === "clipboard") {
      void removeSelected()
      return true
    }
    return false
  }

  apps.connect("notify::list", () => {
    if (launcherVisible.get() && hudMode.get() === "apps") searchApps(query)
  })

  function ClipboardPreview(clipboardEntry: ClipboardEntry) {
    if (!clipboardEntry.binary) {
      return (
        <label
          class="ClipboardItem__preview"
          label={clipboardEntry.preview || "Empty text"}
          xalign={0}
          wrap
          wrapMode={Pango.WrapMode.WORD_CHAR}
          lines={3}
        />
      )
    }

    return (
      <image
        class="ClipboardItem__image"
        iconName={clipboardEntry.image ? "image-x-generic-symbolic" : "application-x-generic-symbolic"}
        widthRequest={128}
        heightRequest={80}
        $={(self) => {
          if (!clipboardEntry.image) return

          clipboardService
            .thumbnail(clipboardEntry)
            .then((path) => self.set_from_file(path))
            .catch((error) => console.error(`Failed to load clipboard thumbnail: ${error}`))
        }}
      />
    )
  }

  return (
    <Gtk.ApplicationWindow
      class="HudWindow"
      visible={isVisible}
      name={`hud-${gdkmonitor.connector}`}
      title="FHUD"
      defaultWidth={600}
      defaultHeight={600}
      decorated={false}
      resizable={false}
      application={app}
      onCloseRequest={() => {
        closeLauncher()
        return true
      }}
      onNotifyVisible={(self) => {
        if (!self.visible) return

        entry?.set_text("")
        entry?.grab_focus()
        query = ""
        if (hudMode.get() === "clipboard") void refreshClipboard()
        else searchApps("")
      }}
    >
      <Gtk.EventControllerKey
        $={(self) => self.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)}
        onKeyPressed={onKeyPressed}
      />
      <box class="HudOverlay" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        <box class="HudContainer" orientation={Gtk.Orientation.VERTICAL} widthRequest={560} spacing={16}>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
            <label class="HudTitle" label={title} />
            <label class="HudSubtitle" label={subtitle} />
          </box>
          <entry
            class="AppLauncher__search"
            $={(self) => (entry = self)}
            placeholderText={placeholder}
            onChanged={(self) => search(self.text)}
          />
          <Gtk.ScrolledWindow heightRequest={420} class="AppLauncher__list">
            <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
              <For each={list}>
                {(item, index) => {
                  const className = createComputed((track) => {
                    const selected = track(index) === track(selectedIndex)
                    const base = item.kind === "clipboard" ? "ClipboardItem" : "AppItem"
                    return selected ? `${base} ${base}--selected` : base
                  })

                  if (item.kind === "clipboard") {
                    return (
                      <button
                        class={className}
                        $={(self) => itemWidgets.set(item.key, self)}
                        onClicked={() => void activate(item)}
                      >
                        <box spacing={12} valign={Gtk.Align.CENTER}>
                          {ClipboardPreview(item.entry)}
                        </box>
                      </button>
                    )
                  }

                  const description = item.app.description ?? item.app.comment ?? item.app.exec ?? ""
                  return (
                    <button
                      class={className}
                      $={(self) => itemWidgets.set(item.key, self)}
                      onClicked={() => void activate(item)}
                    >
                      <box spacing={12} valign={Gtk.Align.CENTER}>
                        <box class="AppItem__icon">
                          <image iconName={item.app.iconName} pixelSize={32} />
                        </box>
                        <box orientation={Gtk.Orientation.VERTICAL} spacing={2} hexpand>
                          <label class="AppItem__name" label={item.app.name} xalign={0} />
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
    </Gtk.ApplicationWindow>
  )
}
