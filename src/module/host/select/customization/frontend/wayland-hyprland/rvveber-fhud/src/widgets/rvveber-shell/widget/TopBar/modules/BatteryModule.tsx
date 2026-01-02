// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"
import { batteryService } from "../../services/battery"
import { IconBadge, PopoverCard } from "../../common"

export default function BatteryModule() {
  const {
    battery,
    isPresent,
    percentLabel,
    icon,
    state,
    timeToEmpty,
    timeToFull,
    temperature,
    tooltip,
    formatDuration,
  } = batteryService

  if (!battery) {
    return null
  }

  return (
    
      <menubutton
        
        class="TopBarButton"
        focusable
        receivesDefault
        tooltipText={tooltip}
        visible={isPresent}
      >
        <IconBadge icon={icon} text={percentLabel?.as((value) => `${value}%`)} />
        <PopoverCard width={260} className="BatteryPopover">
          <box spacing={6} orientation={Gtk.Orientation.VERTICAL}>
            <label class="SectionTitle" label="Power" />
            <box spacing={8}>
              <label class="DataMono" label={percentLabel?.as((value) => `${value}%`)} />
              <label
                class="DataMono DataMono--secondary"
                label={state?.as((value) => (value ? value.toString() : ""))}
              />
            </box>
            <box spacing={8}>
              <label
                xalign={0}
                label={timeToEmpty?.as((v) => `Time left: ${formatDuration(Number(v))}`)}
              />
              <label
                xalign={0}
                label={timeToFull?.as((v) => `Time to full: ${formatDuration(Number(v))}`)}
              />
            </box>
            <label
              xalign={0}
              label={temperature?.as((value) =>
                Number.isFinite(value) ? `${Math.round(value)}°C` : "",
              )}
            />
          </box>
        </PopoverCard>
      </menubutton>
    
  )
}
