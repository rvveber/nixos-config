// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"

export default function IconToggleButton({
  icon,
  activeIcon,
  active,
  tooltip,
  onClicked,
  className = "",
  ...props
}: {
  icon: string
  activeIcon?: string
  active?: boolean
  tooltip?: string
  onClicked?: () => void
  className?: string
} & Partial<Gtk.ToggleButton.ConstructorProps>) {
  const classes = ["IconToggleButton", className].filter(Boolean).join(" ")

  return (
    <togglebutton
      class={classes}
      focusable
      tooltipText={tooltip}
      active={active}
      onToggled={onClicked}
      {...props}
    >
      <image iconName={active && activeIcon ? activeIcon : icon} pixelSize={18} />
    </togglebutton>
  )
}
