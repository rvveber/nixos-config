import Gtk from "gi://Gtk?version=4.0"
import type { Accessor } from "gnim"

type Reactive<T> = T | Accessor<T>

export default function IconButton({
  icon,
  tooltip,
  onClicked,
  className = "",
  children,
  ...props
}: {
  icon: Reactive<string>
  tooltip?: Reactive<string>
  onClicked?: () => void
  className?: string
  children?: JSX.Element | JSX.Element[] | Gtk.Widget | Gtk.Widget[] | null
} & Partial<Gtk.Button.ConstructorProps>) {
  const classes = ["IconButton", className].filter(Boolean).join(" ")

  // Compact action primitive: modules add text as children only when an icon alone is unclear.
  return (
    <button
      class={classes}
      tooltipText={tooltip}
      focusable
      onClicked={onClicked}
      {...props}
    >
      <box spacing={4} valign={Gtk.Align.CENTER}>
        <image iconName={icon} pixelSize={18} />
        {children}
      </box>
    </button>
  )
}
