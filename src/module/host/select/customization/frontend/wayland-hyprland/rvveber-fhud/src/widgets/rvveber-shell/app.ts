import app from "ags/gtk4/app"
import style from "./style.scss"
import TopBar from "./widget/TopBar"

app.start({
  css: style,
  main() {
    const monitors = app.get_monitors()
    if (monitors.length > 0) {
      TopBar(monitors[0])
    }
    
    // Deferred widgets like launcher/card demos can be initialized here later
  },
})
