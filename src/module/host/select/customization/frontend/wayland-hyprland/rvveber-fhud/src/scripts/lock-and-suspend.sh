#!/usr/bin/env bash
# requires: hyprland hyprlock

# this script should be called on lid-switch

# Check if hyprlock is already running
if pgrep -x "hyprlock" > /dev/null; then
    # If hyprlock is running, just suspend
    systemctl suspend
else
    # If hyprlock is not running, proceed with monitor check
    # If the device is connected to multiple displays avoid suspending
    # If the system is already locked suspend nevertheless
    monitor_count=$(hyprctl monitors | grep -c "^Monitor ")
    if [[ $monitor_count -eq 1 ]]; then
        (sleep 1 && systemctl suspend) &
        hyprlock
    else
        # If multiple monitors, just lock
        hyprlock
    fi
fi

