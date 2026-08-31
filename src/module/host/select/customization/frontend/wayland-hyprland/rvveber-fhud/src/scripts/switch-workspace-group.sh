set -euo pipefail

# Workspace groups give each monitor its own decade of workspace IDs while
# allowing related monitors to change desktops together. With bases 21 and 31,
# SUPER+4 opens workspaces 24 and 34 on those monitors; a monitor on base 11 can
# form another group and changes only 14. The focused monitor decides which
# group is operated, and focus returns there after all members have changed.
#
# Configuration lives in this block. A group is a comma-separated list of
# workspace bases; semicolons separate any number of groups:
#
#   RVVEBER_FHUD_WORKSPACE_GROUPS='11;21,31;41,51,61'
#
# Leave it empty to discover the current topology. Auto-discovery isolates the
# lowest base and groups every remaining monitor, matching a laptop display plus
# a synchronized external-monitor group. WORKSPACES_PER_MONITOR controls the
# size of each range. The default 10 maps keys 1..9,0 to offsets 0..9.
#
# This file implements both public operations so their topology cannot drift:
#   switch <key>  changes the selected desktop on every monitor in the group
#   move <key>    sends the focused window within its monitor's workspace range
WORKSPACES_PER_MONITOR=${RVVEBER_FHUD_WORKSPACES_PER_MONITOR:-10}
WORKSPACE_GROUPS=${RVVEBER_FHUD_WORKSPACE_GROUPS:-}

operation=${1:-switch}
if [[ "$operation" == switch || "$operation" == move ]]; then
  shift
else
  operation=switch
fi

target=${1:-}
if [[ ! "$target" =~ ^[0-9]$ ]]; then
  printf 'Usage: %s [switch|move] <workspace 0-9>\n' "$0" >&2
  exit 2
fi

if [[ ! "$WORKSPACES_PER_MONITOR" =~ ^[1-9][0-9]*$ || "$WORKSPACES_PER_MONITOR" -lt 10 ]]; then
  printf 'RVVEBER_FHUD_WORKSPACES_PER_MONITOR must be an integer of at least 10\n' >&2
  exit 2
fi

if [[ "$target" == 0 ]]; then
  offset=9
else
  offset=$((target - 1))
fi

workspace_base() {
  local workspace_id=$1
  printf '%s\n' "$((((workspace_id - 1) / WORKSPACES_PER_MONITOR) * WORKSPACES_PER_MONITOR + 1))"
}

dispatch_focus_monitor() {
  local monitor=$1
  if [[ ! "$monitor" =~ ^[A-Za-z0-9_.:-]+$ ]]; then
    printf 'Unsupported monitor name for Lua dispatch: %s\n' "$monitor" >&2
    exit 2
  fi
  hyprctl dispatch "hl.dsp.focus({ monitor = \"$monitor\" })" >/dev/null
}

dispatch_focus_workspace() {
  local workspace=$1
  hyprctl dispatch "hl.dsp.focus({ workspace = \"$workspace\" })" >/dev/null
}

dispatch_move_window() {
  local workspace=$1
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"$workspace\", follow = false })" >/dev/null
}

if [[ "$operation" == move ]]; then
  workspace_id=$(hyprctl activewindow -j | jq -r '.workspace.id // empty')
  if [[ ! "$workspace_id" =~ ^[0-9]+$ ]]; then
    printf 'Hyprland reported no active window workspace\n' >&2
    exit 1
  fi

  base=$(workspace_base "$workspace_id")
  dispatch_move_window "$((base + offset))"
  exit
fi

monitor_json=$(hyprctl monitors -j)
cursor_json=$(hyprctl cursorpos -j)
cursor_x=$(jq -r '.x | floor' <<<"$cursor_json")
cursor_y=$(jq -r '.y | floor' <<<"$cursor_json")
mapfile -t monitor_rows < <(
  jq -r '.[] | select(.disabled != true) | [.name, .activeWorkspace.id, .focused] | @tsv' <<<"$monitor_json"
)

if ((${#monitor_rows[@]} == 0)); then
  printf 'Hyprland reported no enabled monitors\n' >&2
  exit 1
fi

focused_monitor=
focused_base=
minimum_base=

for row in "${monitor_rows[@]}"; do
  IFS=$'\t' read -r monitor_name workspace_id focused <<<"$row"
  base=$(workspace_base "$workspace_id")

  if [[ "$focused" == true ]]; then
    focused_monitor=$monitor_name
    focused_base=$base
  fi

  if [[ -z "$minimum_base" || "$base" -lt "$minimum_base" ]]; then
    minimum_base=$base
  fi
done

if [[ -z "$focused_monitor" || -z "$focused_base" ]]; then
  printf 'Hyprland reported no focused monitor\n' >&2
  exit 1
fi

selected_bases=()
if [[ -n "$WORKSPACE_GROUPS" ]]; then
  IFS=';' read -r -a group_definitions <<<"$WORKSPACE_GROUPS"
  for definition in "${group_definitions[@]}"; do
    [[ -n "$definition" ]] || continue
    IFS=',' read -r -a group_bases <<<"$definition"
    contains_focused=false
    for base in "${group_bases[@]}"; do
      if [[ ! "$base" =~ ^[1-9][0-9]*$ ]]; then
        printf 'RVVEBER_FHUD_WORKSPACE_GROUPS must contain positive numeric bases\n' >&2
        exit 2
      fi
      [[ "$base" == "$focused_base" ]] && contains_focused=true
    done
    if [[ "$contains_focused" == true ]]; then
      selected_bases=("${group_bases[@]}")
      break
    fi
  done

  if ((${#selected_bases[@]} == 0)); then
    printf 'Focused workspace base %s is absent from RVVEBER_FHUD_WORKSPACE_GROUPS\n' "$focused_base" >&2
    exit 2
  fi
else
  for row in "${monitor_rows[@]}"; do
    IFS=$'\t' read -r _ workspace_id _ <<<"$row"
    base=$(workspace_base "$workspace_id")
    if [[ "$focused_base" == "$minimum_base" && "$base" == "$minimum_base" ]]; then
      selected_bases+=("$base")
    elif [[ "$focused_base" != "$minimum_base" && "$base" != "$minimum_base" ]]; then
      selected_bases+=("$base")
    fi
  done
fi

base_is_selected() {
  local candidate=$1
  local selected
  for selected in "${selected_bases[@]}"; do
    [[ "$candidate" == "$selected" ]] && return 0
  done
  return 1
}

for row in "${monitor_rows[@]}"; do
  IFS=$'\t' read -r monitor_name workspace_id _ <<<"$row"
  base=$(workspace_base "$workspace_id")
  base_is_selected "$base" || continue

  dispatch_focus_monitor "$monitor_name"
  dispatch_focus_workspace "$((base + offset))"
done

dispatch_focus_monitor "$focused_monitor"
hyprctl dispatch "hl.dsp.cursor.move({ x = $cursor_x, y = $cursor_y })" >/dev/null
