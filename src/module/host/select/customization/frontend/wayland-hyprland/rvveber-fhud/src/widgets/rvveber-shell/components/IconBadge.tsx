// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"

type IconBadgeProps = {
  icon: string
  text?: string
  className?: string
  children?: Gtk.Widget[] | Gtk.Widget | null
} & Partial<Gtk.Box.ConstructorProps>

export default function IconBadge({
  icon,
  text,
  children,
  className = "",
  spacing,
  valign,
  ...rest
}: IconBadgeProps) {
  const classes = ["IconBadge", className].filter(Boolean).join(" ")

  return (
    <box
      class={classes}
      spacing={spacing ?? 6}
      valign={valign ?? Gtk.Align.CENTER}
      {...rest}
    >
      <image iconName={icon} class="IconBadge__icon" pixelSize={18} />
      {text && <label class="IconBadge__text" xalign={0} label={text} />}
      {children}
    </box>
  )
}
