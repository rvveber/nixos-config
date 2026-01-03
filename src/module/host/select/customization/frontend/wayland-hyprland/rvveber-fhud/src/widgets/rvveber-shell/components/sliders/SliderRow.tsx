// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"
import { Accessor } from "gnim"

export default function SliderRow({
  title,
  value,
  onChange,
  min = 0,
  max = 1,
  step = 0.01,
  quickSteps,
  className = "",
}: {
  title: string
  value: any
  onChange: (value: number) => void
  min?: number
  max?: number
  step?: number
  quickSteps?: number[]
  className?: string
}) {
  const classes = ["SliderRow", className].filter(Boolean).join(" ")

  return (
    <box class={classes} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <label class="SectionTitle" label={title} />
      <box spacing={6} valign={Gtk.Align.CENTER}>
        <slider
          hexpand
          min={min}
          max={max}
          value={value}
          step={step}
          // IMPORTANT: Use "value: newValue" to avoid shadowing the outer "value" prop.
          // Shadowing causes the JSX transformer to break Accessor reactive bindings!
          onChangeValue={({ value: newValue }) => {
            // Use a different variable name to avoid shadowing
            onChange(newValue)
          }}
          drawValue={false}
        />
        {quickSteps && (
          <box spacing={4} class="QuickSteps">
            {quickSteps.map((stepValue) => (
              <button
                class="QuickStepButton"
                focusable
                onClicked={() => onChange(stepValue)}
              >
                <label label={`${Math.round(stepValue * 100)}%`} />
              </button>
            ))}
          </box>
        )}
      </box>
    </box>
  )
}
