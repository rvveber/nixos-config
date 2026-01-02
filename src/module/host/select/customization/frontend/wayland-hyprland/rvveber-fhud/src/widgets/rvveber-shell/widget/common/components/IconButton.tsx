// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"

export default function IconButton({
  icon,
  tooltip,
  onClicked,
  className = "",
  children,
  ...props
}: {
  icon: string
  tooltip?: string
  onClicked?: () => void
  className?: string
  children?: Gtk.Widget | Gtk.Widget[] | null
} & Partial<Gtk.Button.ConstructorProps>) {
  const classes = ["IconButton", className].filter(Boolean).join(" ")

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
