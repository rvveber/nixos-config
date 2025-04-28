import { App, Astal, Gtk, Gdk, Widget } from "astal/gtk4";
import { Variable } from "astal";

const time = Variable("").poll(1000, "date");


export default function Bar2(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      visible
      cssClasses={["Bar"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={App}
    >
      <box orientation={"vertical"} valign={Gtk.Align.CENTER}>
        <box orientation={"horizontal"}>
          <box hexpand/>
          <menubutton>
            <label label={time()} />
            <popover>
              <Gtk.Calendar />
            </popover>
          </menubutton>
        </box>
      </box>
    </window>
  );
}

function Bar(): Widget.ButtonProps {
  return Widget.Button({
    visible: true,
    cssClasses: ["Bar"],
    gdkmonitor: Gdk.Monitor,
    exclusivity: Astal.Exclusivity.EXCLUSIVE,
    anchor: Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT,
    application: App
  });
};