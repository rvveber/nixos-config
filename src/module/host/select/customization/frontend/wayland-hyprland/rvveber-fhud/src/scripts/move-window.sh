set -euo pipefail

direction=${1:-}

case "$direction" in
  l | r | u | d) ;;
  *)
    printf 'Usage: %s {l|r|u|d}\n' "$0" >&2
    exit 2
    ;;
esac

active=$(hyprctl activewindow -j)
address=$(jq -r '.address // empty' <<<"$active")
workspace=$(jq -r '.workspace.id // empty' <<<"$active")
monitor=$(jq -r '.monitor // empty' <<<"$active")

[[ -n "$address" && -n "$workspace" && -n "$monitor" ]] || exit 0

snapshot() {
  hyprctl clients -j \
    | jq -c --argjson workspace "$workspace" \
      '[.[] | select(.workspace.id == $workspace) | {address, at, size}] | sort_by(.address)'
}

before=$(snapshot)
hyprctl dispatch "hl.dsp.window.move({ direction = \"$direction\" })" >/dev/null
after=$(snapshot)
current_monitor=$(hyprctl activewindow -j | jq -r '.monitor // empty')

if [[ "$before" != "$after" || "$current_monitor" != "$monitor" ]]; then
  exit 0
fi

hyprctl dispatch "hl.dsp.focus({ monitor = \"$direction\" })" >/dev/null
target_monitor=$(hyprctl monitors -j | jq -r 'first(.[] | select(.focused) | .name) // empty')
hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null

if [[ -n "$target_monitor" && "$target_monitor" != "$(hyprctl monitors -j | jq -r --argjson monitor "$monitor" 'first(.[] | select(.id == $monitor) | .name) // empty')" ]]; then
  hyprctl dispatch "hl.dsp.window.move({ monitor = \"$target_monitor\", follow = true })" >/dev/null
fi
