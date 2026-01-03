// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"
import { batteryService } from "../../../services/battery"
import { powerProfilesService } from "../../../services/powerprofiles"
import { IconBadge, PopoverCard } from "../../../components"

const STATE_LABELS = [
  "Unknown",
  "Charging",
  "Discharging",
  "Empty",
  "Fully charged",
  "Pending charge",
  "Pending discharge",
]

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
  const { activeProfile, powerProfiles, setProfile } = powerProfilesService

  if (!battery) {
    return null
  }

  return (
    <box class="TopBarSection TopBarSection--item" visible={isPresent}>
      <menubutton
        class="TopBarButton"
        focusable
        receivesDefault
        tooltipText={tooltip}
      >
        <IconBadge icon={icon} text={percentLabel?.as((value) => `${value}%`)} />
        <PopoverCard width={260} className="BatteryPopover">
          <box spacing={10} orientation={Gtk.Orientation.VERTICAL}>
            <label class="SectionTitle" label="Power" />
            <box class="BatteryHeader" spacing={10} valign={Gtk.Align.CENTER}>
              <box class="BatteryHeader__icon">
                <image iconName={icon} pixelSize={24} />
              </box>
              <box orientation={Gtk.Orientation.VERTICAL} spacing={2} hexpand>
                <label class="BatteryHeader__percent" label={percentLabel?.as((value) => `${value}%`)} xalign={0} />
                <label
                  class="BatteryHeader__state"
                  label={state?.as((value) => STATE_LABELS[value as number] ?? "Unknown")}
                  xalign={0}
                />
              </box>
            </box>
            {powerProfiles && (
              <box class="PowerProfileRow" spacing={6}>
                <button
                  class={activeProfile?.as((profile) =>
                    profile === "power-saver"
                      ? "PowerProfileButton is-active"
                      : "PowerProfileButton"
                  )}
                  onClicked={() => setProfile("power-saver")}
                >
                  <box spacing={6} valign={Gtk.Align.CENTER}>
                    <image iconName="power-profile-power-saver-symbolic" pixelSize={16} />
                    <label label="Max battery" />
                  </box>
                </button>
                <button
                  class={activeProfile?.as((profile) =>
                    profile === "performance"
                      ? "PowerProfileButton is-active"
                      : "PowerProfileButton"
                  )}
                  onClicked={() => setProfile("performance")}
                >
                  <box spacing={6} valign={Gtk.Align.CENTER}>
                    <image iconName="power-profile-performance-symbolic" pixelSize={16} />
                    <label label="Max performance" />
                  </box>
                </button>
              </box>
            )}
            <box class="BatteryStats" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
              <box spacing={8}>
                <label
                  class="BatteryStat"
                  label={timeToEmpty?.as((v) => `Time left ${formatDuration(Number(v))}`)}
                  xalign={0}
                  hexpand
                />
                <label
                  class="BatteryStat"
                  label={timeToFull?.as((v) => `To full ${formatDuration(Number(v))}`)}
                  xalign={0}
                />
              </box>
              <label
                class="BatteryTemp"
                xalign={0}
                label={temperature?.as((value) =>
                  Number.isFinite(value) ? `${Math.round(value)}°C` : "Temp --",
                )}
              />
            </box>
          </box>
        </PopoverCard>
      </menubutton>
    </box>
  )
}
