#!/usr/bin/env bash
# Purpose: Moves the active window to a target workspace within a 10-workspace group
#          on its current monitor.
#
# Behavior:
# 1.  Accepts a target workspace group number (1-9, or 0 for the 10th workspace in a group).
# 2.  Identifies the monitor of the currently active window.
# 3.  Determines the "base" workspace ID for that monitor (e.g., if workspaces are 23, 24,
#     the base is 21). This assumes workspaces are grouped in tens (e.g., 11-20, 21-30).
# 4.  Calculates the target workspace ID based on the monitor's base ID and the input
#     target group number.
#     - The input group number (1-9, or 0) acts as an offset.
#       '1' targets the 1st workspace (base + 0), '2' targets the 2nd (base + 1), ...,
#       '9' targets the 9th (base + 8), and '0' targets the 10th (base + 9).
# 5.  Uses `hyprctl dispatch movetoworkspacesilent <target_workspace_id>` to move the window.
#
# Dependencies:
# - hyprland (for `hyprctl`)
# - jq (for JSON parsing)
#
# Usage:
#   ./move-to-workspace-group.sh <target_group_number>
#
#   <target_group_number>: 0-9.
#     Specifies the target workspace within the monitor's 10-workspace group.

set -euo pipefail

# --- Script Arguments ---
TARGET_GROUP_INPUT="${1:-}"

# --- Logging and Error Handling ---
log() {
    echo >&2 "[LOG] $*"
}

die() {
    echo >&2 "[ERROR] $*"
    exit 1
}

# --- Helper Functions ---

# Validates the target group number (0-9)
validate_target_group_num() {
    local num="$1"
    if ! [[ "$num" =~ ^[0-9]$ ]]; then
        die "Target group number must be a single digit from 0 to 9. Received: '$num'"
    fi
}

# Calculates the actual offset for workspace calculation (0-9)
# Input '0' means 10th item (offset 9), '1' means 1st item (offset 0)
calculate_target_offset() {
    local target_group_num="$1"
    if [[ "$target_group_num" -eq 0 ]]; then
        echo 9
    else
        echo "$((target_group_num - 1))"
    fi
}

# Fetches all workspaces and their monitor IDs
# Output format: workspace_id monitor_id (one per line)
get_all_workspaces_info() {
    hyprctl workspaces -j | jq -r '.[] | "\(.id) \(.monitorID)"' || die "Failed to get workspaces info"
}

# Gets the Hyprland monitor ID of the currently active window
get_active_window_monitor_id() {
    hyprctl activewindow -j | jq -r '.monitor' || die "Failed to get active window's monitor ID"
}

# Calculates base workspace ID for a specific monitor
# Arguments:
#   $1: monitor_hypr_id
#   $2: string containing all_workspaces_info output
# Output: base_id for the monitor, or exits if error
get_monitor_base_id() {
    local monitor_hypr_id="$1"
    local all_workspaces_info_str="$2"
    
    local current_monitor_ws_ids_str
    current_monitor_ws_ids_str=$(echo "$all_workspaces_info_str" | awk -v mid="$monitor_hypr_id" '$2 == mid {print $1}' | sort -n | tr '\\n' ' ')
    
    if [[ -z "$current_monitor_ws_ids_str" ]]; then
        local monitor_name # Try to get monitor name for a better error message
        monitor_name=$(hyprctl monitors -j | jq -r --argjson mid "$monitor_hypr_id" '.[] | select(.id == $mid) | .name' 2>/dev/null || echo "Unknown")
        die "Monitor ID $monitor_hypr_id ($monitor_name) has no workspaces listed. Cannot calculate base ID."
    fi

    local min_ws_on_monitor
    read -r min_ws_on_monitor _ <<< "$current_monitor_ws_ids_str"

    if [[ -z "$min_ws_on_monitor" ]] || ! [[ "$min_ws_on_monitor" =~ ^[0-9]+$ ]]; then
        local monitor_name # Try again for error
        monitor_name=$(hyprctl monitors -j | jq -r --argjson mid "$monitor_hypr_id" '.[] | select(.id == $mid) | .name' 2>/dev/null || echo "Unknown")
        die "Could not determine a valid minimum workspace for monitor ID $monitor_hypr_id ($monitor_name) from string '$current_monitor_ws_ids_str'."
    fi
    
    echo "$(( (min_ws_on_monitor - 1) / 10 * 10 + 1 ))"
}

# --- Main Script Logic ---
main() {
    if [[ -z "$TARGET_GROUP_INPUT" ]]; then
        die "Usage: $0 <target_group_number (0-9)>"
    fi
    validate_target_group_num "$TARGET_GROUP_INPUT"

    local target_ws_offset
    target_ws_offset=$(calculate_target_offset "$TARGET_GROUP_INPUT")
    log "Target group input: $TARGET_GROUP_INPUT, Workspace offset: $target_ws_offset"

    local active_window_monitor_id
    active_window_monitor_id=$(get_active_window_monitor_id)
    if [[ -z "$active_window_monitor_id" ]] || ! [[ "$active_window_monitor_id" =~ ^[0-9]+$ ]]; then
        die "Could not retrieve a valid monitor ID for the active window."
    fi
    log "Active window is on monitor ID: $active_window_monitor_id"
    
    local all_workspaces_info
    all_workspaces_info="$(get_all_workspaces_info)"
    if [[ -z "$all_workspaces_info" ]]; then
        die "No workspace information found. Ensure Hyprland is running and workspaces are configured."
    fi

    local current_monitor_base_id
    current_monitor_base_id=$(get_monitor_base_id "$active_window_monitor_id" "$all_workspaces_info")
    log "Base ID for monitor $active_window_monitor_id is: $current_monitor_base_id"

    local target_move_ws_id=$((current_monitor_base_id + target_ws_offset))
    log "Calculated target workspace ID to move window to: $target_move_ws_id"

    local dispatch_command="dispatch movetoworkspacesilent $target_move_ws_id"
    
    log "Executing hyprctl command: $dispatch_command"
    if ! hyprctl -- "$dispatch_command"; then # Using -- to signify end of options for hyprctl
        die "hyprctl command '$dispatch_command' failed."
    fi
    log "Window move command sent."
}

# --- Run ---
main "$@"
exit 0
