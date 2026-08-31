#!/usr/bin/env sh

# This script listens for monitor added/removed events from Hyprland and exits
# the compositor when the changed topology remains stable for six seconds.

monitor_topology() {
  hyprctl -j monitors | jq -r 'map(.name) | sort | .[]'
}

initial_topology=$(monitor_topology)

echo "Starting monitor event listener to exit Hyprland on changes..." >&2

socat -u UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while IFS= read -r line; do
  case "$line" in
  monitorremoved\>\>* | monitoradded\>\>*)
    echo "Monitor event detected: [$line]. Waiting six seconds for the topology to settle." >&2
    sleep 6

    if [ "$(monitor_topology)" = "$initial_topology" ]; then
      echo "Original monitor topology restored. Keeping Hyprland running." >&2
      continue
    fi

    echo "Monitor topology changed. Exiting Hyprland." >&2
    hyprctl dispatch exit
    break
    ;;
  esac
done

echo "Monitor event listener finished." >&2
