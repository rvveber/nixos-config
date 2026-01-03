// @ts-nocheck
import Gtk from "gi://Gtk?version=4.0"

const focusClass = "is-focus-visible"

function applyFocusStyle(widget: Gtk.Widget) {
  widget.add_css_class?.(focusClass)
}

function removeFocusStyle(widget: Gtk.Widget) {
  widget.remove_css_class?.(focusClass)
}

export default function FocusManager(widget: Gtk.Widget) {
  if (!widget) return

  // GTK4 uses different approach - we need to use state-flags-changed
  // or EventControllerFocus. For now, let's use a simpler approach
  // by monitoring the has-focus property
  
  const updateFocusStyle = () => {
    if (widget.has_focus) {
      applyFocusStyle(widget)
    } else {
      removeFocusStyle(widget)
    }
  }

  // Connect to notify::has-focus property change
  // In GTK4/GJS, connect is available on GObject.Object
  if (typeof widget.connect === 'function') {
    widget.connect("notify::has-focus", updateFocusStyle)
    widget.connect("destroy", () => removeFocusStyle(widget))
  }
}
