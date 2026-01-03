import app from "ags/gtk4/app"
import style from "./style.scss"
import TopBar from "./windows/TopBar"
import Hud from "./windows/Hud"
import { hudService } from "./services/hud"

app.start({
  css: style,
  main() {
    console.log("Starting rvveber-fhud-ui...")
    const monitors = app.get_monitors()
    console.log(`Found ${monitors.length} monitors`)
    if (monitors.length > 0) {
      TopBar(monitors[0])
      hudService.setDefaultMonitorName(monitors[0].connector)
      monitors.forEach((monitor) => Hud(monitor))
    }
  },
  requestHandler(request, res) {
    console.log(`Received request: ${JSON.stringify(request)}`)
    
    // Handle potential comma-separated args (e.g. "request,toggle,launcher")
    // or just "toggle launcher"
    let cmd = typeof request === 'string' ? request : String(request)

    // Remove "request," prefix if present (artifact of how it's called sometimes)
    if (cmd.startsWith("request,")) {
        cmd = cmd.substring(8)
    }
    // Replace remaining commas with spaces
    cmd = cmd.replace(/,/g, " ").trim()

    if (cmd === "toggle launcher") {
      hudService.toggleLauncher()
      res("ok")
    } else if (cmd === "open launcher") {
      hudService.openLauncher()
      res("ok")
    } else if (cmd === "close launcher") {
      hudService.closeLauncher()
      res("ok")
    } else {
      console.warn(`Unknown request: ${request} (parsed: ${cmd})`)
      res("unknown command")
    }
  },
})
