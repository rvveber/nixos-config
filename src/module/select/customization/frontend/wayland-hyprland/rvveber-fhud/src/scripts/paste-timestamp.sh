#!/usr/bin/env bash
# requires: wl-clipboard hyprland

# Copy the current Unix epoch timestamp
date +%s | wl-copy

# Paste via hyprctl dispatch sendshortcut
hyprctl dispatch sendshortcut CTRL+SHIFT,V,
