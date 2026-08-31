#!/usr/bin/env bash
# requires: wl-clipboard hyprland

# Copy the current Unix epoch timestamp
date +%s | wl-copy

# Paste into the focused window through Hyprland's Lua dispatcher API.
hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL+SHIFT", key = "V" })'
