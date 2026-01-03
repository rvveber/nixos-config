// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"
import { brightnessService } from "../../../services/brightness"
import { IconBadge, PopoverCard, SliderRow } from "../../../components"

export default function BrightnessModule() {
  const { brightness, percent, setBrightness } = brightnessService

  return (
    <box class="TopBarSection TopBarSection--item" visible={brightness((state) => state.available)}>
      <menubutton
        class="TopBarButton"
        focusable
        receivesDefault
        tooltipText={percent((value) => `Brightness ${Math.round(value * 100)}%`)}
      >
        <IconBadge
          icon="display-brightness"
          text={percent((value) => `${Math.round(value * 100)}%`)}
        />
        <PopoverCard width={320} className="BrightnessPopover">
          <box spacing={10} orientation={Gtk.Orientation.VERTICAL}>
            <SliderRow
              title="Brightness"
              value={percent}
              onChange={setBrightness}
              quickSteps={[0, 0.5, 1]}
            />
          </box>
        </PopoverCard>
      </menubutton>
    </box>
  )
}
