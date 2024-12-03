#!/usr/bin/env bash

###
# this script should be called on lid-switch
###

# If the device is connected to multiple displays avoid suspending
monitor_count=$(hyprctl monitors | grep -c "^Monitor ")
if [[ $monitor_count -eq 1 ]]; then
    (sleep 1 && systemctl suspend) &
    hyprlock
fi