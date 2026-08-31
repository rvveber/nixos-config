set -euo pipefail

direction=${1:-}

case "$direction" in
  hud | l | r | u | d) ;;
  *)
    printf 'Usage: %s {hud|l|r|u|d}\n' "$0" >&2
    exit 2
    ;;
esac

active=$(hyprctl activewindow -j)
workspace=$(jq -r '.workspace.id // empty' <<<"$active")
active_address=$(jq -r '.address // empty' <<<"$active")
hud_address=$(
  hyprctl clients -j \
    | jq -r --argjson workspace "${workspace:-0}" \
      'first(.[] | select(.title == "FHUD" and .visible and .workspace.id == $workspace) | .address) // empty'
)

if [[ -n "$hud_address" && "$hud_address" != "$active_address" ]]; then
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$hud_address\" })" >/dev/null
elif [[ "$direction" != hud ]]; then
  hyprctl dispatch "hl.dsp.focus({ direction = \"$direction\" })" >/dev/null
fi
