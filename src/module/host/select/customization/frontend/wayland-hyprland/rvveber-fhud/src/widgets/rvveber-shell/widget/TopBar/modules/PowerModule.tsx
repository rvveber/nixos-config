// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"
import { powerService } from "../../services/power"
import { PopoverCard, IconButton } from "../../common"

const POWER_ACTIONS = [
  { label: "Lock", icon: "system-lock-screen-symbolic", command: "lock" },
  { label: "Suspend", icon: "media-playback-pause-symbolic", command: "suspend" },
  { label: "Hibernate", icon: "weather-clear-night-symbolic", command: "hibernate" },
  { label: "Reboot", icon: "system-reboot-symbolic", command: "reboot" },
  { label: "Shutdown", icon: "system-shutdown-symbolic", command: "shutdown" },
]

function PowerButton({ label, icon, command }: { label: string; icon: string; command: string }) {
  return (
    <button class="PowerButton" focusable onClicked={() => powerService.run(command)}>
      <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
        <image iconName={icon} pixelSize={24} />
        <label label={label} />
      </box>
    </button>
  )
}

export default function PowerModule() {
  return (
    
      <menubutton
        
        class="TopBarButton"
        focusable
        receivesDefault
        tooltipText="System power"
      >
        <Gtk.Image iconName="system-shutdown-symbolic" pixelSize={18} />
        <PopoverCard width={320} className="PowerPopover">
          <box spacing={10} orientation={Gtk.Orientation.VERTICAL}>
            <label class="SectionTitle" label="Power" />
            <box spacing={8}>
              {POWER_ACTIONS.map((action) => (
                <PowerButton {...action} />
              ))}
            </box>
          </box>
        </PopoverCard>
      </menubutton>
    
  )
}
