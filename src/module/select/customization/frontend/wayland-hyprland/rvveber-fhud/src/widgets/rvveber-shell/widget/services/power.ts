// @ts-nocheck
import { execAsync } from "ags/process"

const COMMANDS = {
  suspend: ["systemctl", "suspend"],
  reboot: ["systemctl", "reboot"],
  shutdown: ["systemctl", "poweroff"],
  lock: ["uwsm", "app", "--", "rvveber-fhud-lock-and-suspend"],
  hibernate: ["systemctl", "hibernate"],
}

async function run(command: keyof typeof COMMANDS) {
  const args = COMMANDS[command]
  if (!args) return
  try {
    await execAsync(args)
  } catch (error) {
    console.error(`Failed to run power command ${command}`, error)
  }
}

export const powerService = {
  run,
}
