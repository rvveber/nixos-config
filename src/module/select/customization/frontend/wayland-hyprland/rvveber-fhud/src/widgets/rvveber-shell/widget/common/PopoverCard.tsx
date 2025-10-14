// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"

type PopoverCardProps = {
  children?: Gtk.Widget[] | Gtk.Widget | null
  className?: string
  width?: number
  height?: number
} & Partial<Gtk.Popover.ConstructorProps>

export default function PopoverCard({
  children,
  className = "",
  width,
  height,
  position,
  autohide,
  ...rest
}: PopoverCardProps) {
  const classes = ["PopoverCard", className].filter(Boolean).join(" ")

  return (
    <popover
      class={classes}
      position={position ?? Gtk.PositionType.BOTTOM}
      autohide={autohide ?? true}
      widthRequest={width}
      heightRequest={height}
      {...rest}
    >
      <box orientation={Gtk.Orientation.VERTICAL} class="PopoverCard__content">
        {children}
      </box>
    </popover>
  )
}
