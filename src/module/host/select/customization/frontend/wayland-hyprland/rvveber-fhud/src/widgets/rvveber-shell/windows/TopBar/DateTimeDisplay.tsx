// @ts-nocheck
import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"
import { createPoll } from "ags/time"
import { PopoverCard } from "../../components"

const TIMESTAMP_FORMAT = "%Y-%m-%d · %H:%M"

const timestamp = createPoll("--", 1000, () => {
  const now = GLib.DateTime.new_now_local()
  return now ? now.format(TIMESTAMP_FORMAT) ?? "--" : "--"
})

const tooltip = createPoll("", 60000, () => {
  const now = GLib.DateTime.new_now_local()
  if (!now) {
    return "Time unavailable"
  }

  const week = now.get_week_of_year()
  const weekday = now.format("%A") ?? ""
  return `Week ${week} • ${weekday}`
})

export default function DateTimeDisplay({ className = "", ...props }: { className?: string } & any) {
  return (
    <box class={className} {...props}>
      <menubutton
        class="TopBarButton"
        focusable
        receivesDefault
        tooltipText={tooltip}
      >
        <label class="DataMono" label={timestamp} />
        <PopoverCard width={280} className="CalendarPopover">
          <Gtk.Calendar />
        </PopoverCard>
      </menubutton>
    </box>
  )
}
