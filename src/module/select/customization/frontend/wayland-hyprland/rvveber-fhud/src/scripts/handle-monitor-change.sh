#!/usr/bin/env sh

# This script listens for monitor added/removed events from Hyprland
# and triggers 'hyprctl dispatch exit' to close Hyprland.

echo "Starting monitor event listener to exit Hyprland on changes..." >&2

socat -u UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while IFS= read -r line; do
  # Check for preMonitorRemoved or preMonitorAdded events
  # The event format is typically "eventname>>parameters"
  if echo "$line" | grep -qE "^monitorremoved>>|^monitoradded>>"; then 
    echo "Monitor event detected: [$line]. Exiting Hyprland." >&2
    hyprctl dispatch exit
    # Once exit is dispatched, Hyprland will terminate, and this script
    # will likely be killed as part of the session shutdown.
    # Exiting the loop explicitly in case the script continues for a moment.
    break
  fi
done

echo "Monitor event listener finished." >&2
