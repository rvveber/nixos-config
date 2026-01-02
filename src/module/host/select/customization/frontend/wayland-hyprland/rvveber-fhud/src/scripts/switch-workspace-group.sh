#!/usr/bin/env bash
# Purpose: Switches workspaces synchronously across Hyprland monitors. It categorizes
#          workspaces into a 'Main Group' and an 'Alternate Group'. Depending on which
#          group the currently focused workspace belongs to, either the Main or
#          Alternate group will switch synchronously. An override flag allows switching
#          only the focused monitor's workspace.
#
# Behavior:
# 1.  Accepts a target workspace group number (1-9, or 0 for the 10th workspace in a group)
#     and an optional override_flag.
# 2.  Fetches current workspace and monitor information using `hyprctl activeworkspace -j`,
#     `hyprctl monitors -j`, and `hyprctl workspaces -j`, parsing them with `jq`.
# 3.  Dynamically determines a "base" workspace ID for each monitor. This is typically the
#     lowest numbered workspace on that monitor, rounded down to the nearest 10+1 (e.g., if
#     workspaces are 23, 24, the base is 21). This defines logical groups of 10 workspaces
#     (e.g., 11-20, 21-30).
# 4.  Defines two main operational groups of workspaces for switching:
#     -   **Alternate Group:**
#         -   Default: The 10 workspaces associated with the *lowest base workspace ID*
#             found across all monitors (e.g., workspaces 11-20 if 11 is the lowest base).
#         -   Override: Can be explicitly defined by setting the `WORKSPACE_IDS_ALTERNATE_GROUP`
#             environment variable to a space-separated list of 10 workspace IDs
#             (e.g., "21 22 23 24 25 26 27 28 29 30").
#     -   **Main Group:** All workspaces *not* belonging to the Alternate Group.
# 5.  Determines the target workspace ID for each monitor based on its base ID and the input
#     target group number.
#     - The input group number (1-9, or 0) acts as an offset within the 10-workspace group.
#       '1' targets the 1st workspace (base + 0), '2' targets the 2nd (base + 1), ...,
#       '9' targets the 9th (base + 8), and '0' targets the 10th (base + 9).
#     - Example: If a monitor's base is 21:
#       - Target group '3' results in target workspace 21 + (3-1) = 23.
#       - Target group '0' results in target workspace 21 + 9 = 30.
# 6.  Switching Logic:
#     - The script first determines if the *currently focused workspace* belongs to the
#       Alternate Group or the Main Group.
#     - **If the `override_flag` is set to 'true' or '1':**
#         The script switches *only* the workspace on the *currently focused monitor*
#         to its calculated target workspace. Grouping logic is bypassed.
#     - **Otherwise (no `override_flag`):**
#         -   **If the focused workspace is part of the Alternate Group:**
#             Only workspaces belonging to the Alternate Group are switched
#             synchronously to their respective target workspaces. Workspaces in the
#             Main Group remain unchanged.
#         -   **If the focused workspace is part of the Main Group:**
#             Only workspaces belonging to the Main Group are switched
#             synchronously to their respective target workspaces. Workspaces in the
#             Alternate Group remain unchanged.
# 7.  Captures the monitor ID where the mouse cursor is located *before* switching workspaces
#     to potentially restore focus (current implementation might need review for this specific aspect).
# 8.  Constructs a batch command string for `hyprctl --batch` to dispatch all workspace changes
#     in a single command.
#     - Example: "dispatch workspace 13; dispatch workspace 23"
# 9.  Executes the batch command.
#
# Dependencies:
# - hyprland (for `hyprctl`)
# - jq (for JSON parsing)
#
# Usage:
#   ./switch-workspace-group.sh <target_group_number> [override_flag]
#
#   <target_group_number>: 0-9.
#     Specifies the target workspace within each monitor's 10-workspace group.
#     '1' = 1st workspace, '2' = 2nd, ..., '9' = 9th, '0' = 10th.
#   [override_flag]: 'true' or '1' (optional).
#     If set, only the active monitor's workspace is switched.
#
# Configuration:
# - WORKSPACE_IDS_ALTERNATE_GROUP: (Optional Environment Variable)
#   A space-separated string of 10 workspace IDs that define the 'Alternate Group'.
#   Example: `export WORKSPACE_IDS_ALTERNATE_GROUP="21 22 23 24 25 26 27 28 29 30"`
#   If set, these 10 workspaces constitute the Alternate Group. If the currently focused
#   workspace is within this group (and no override_flag is used), only these Alternate
#   workspaces will switch together. If focus is outside this group, then these Alternate
#   workspaces will remain unchanged while the Main Group workspaces switch.
#   If empty or unset, the script defaults to the workspace group with the lowest starting ID
#   (e.g., 11-20 if '11' is the lowest default workspace on any monitor) as the Alternate Group.
#
# - Hyprland Workspace Setup (Recommended for predictable behavior):
#   Define your default workspaces in your Hyprland configuration (e.g., `hyprland.conf`
#   or via a NixOS module) in groups of 10, typically starting with a '1' in the tens place
#   for each monitor's first workspace in its group.
#   Example (conceptual, adapt to your monitor names/setup):
#   ```nix
#   # In your Hyprland configuration
#   wayland.windowManager.hyprland.settings.workspace = [
#     "11, monitor:DP-1, persistent:true, default:true"     # Monitor 1, Group 1 (11-20)
#     "12, monitor:DP-1, persistent:true"
#     # ... up to 10 workspaces for this monitor group
#     "21, monitor:HDMI-A-1, persistent:true, default:true" # Monitor 2, Group 2 (21-30)
#     "22, monitor:HDMI-A-1, persistent:true"
#     # ... up to 10 workspaces for this monitor group
#     "31, monitor:desc:Some Other Monitor, persistent:true, default:true" # Monitor 3, Group 3 (31-40)
#     # etc.
#   ];
#   ```
#   The script uses these initial workspace IDs (11, 21, 31) to determine the "base" ID for each monitor.
set -euo pipefail

# --- Script Arguments & Configuration ---
TARGET_GROUP_INPUT="${1:-}"
OVERRIDE_FLAG_INPUT="${2:-false}"

# Environment variable: WORKSPACE_IDS_ALTERNATE_GROUP

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

# Fetches all monitors and their IDs and names
# Output format: monitor_id monitor_name (one per line)
get_all_monitors_info() {
    hyprctl monitors -j | jq -r '.[] | "\(.id) \(.name)"' || die "Failed to get monitors info"
}

# Gets the ID of the currently active workspace
get_active_workspace_id() {
    hyprctl activeworkspace -j | jq -r '.id' || die "Failed to get active workspace ID"
}

# Calculates base workspace IDs for all monitors
# Populates global associative arrays:
#   monitor_base_ids[monitor_id]="base_id"
#   monitor_workspace_ids[monitor_id]="ws_id1 ws_id2 ..."
# Sets global variable:
#   overall_min_monitor_base_id
declare -A monitor_base_ids
declare -A monitor_workspace_ids
overall_min_monitor_base_id=""

calculate_all_monitor_base_ids() {
    local all_workspaces_info
    all_workspaces_info="$(get_all_workspaces_info)"
    if [[ -z "$all_workspaces_info" ]]; then
        die "No workspace information found. Ensure Hyprland is running and workspaces are configured."
    fi

    local all_monitors_info
    all_monitors_info="$(get_all_monitors_info)"
    if [[ -z "$all_monitors_info" ]]; then
        die "No monitor information found. Ensure Hyprland is running and monitors are detected."
    fi

    local temp_min_overall_base_id=99999 # Initialize with a large number

    while read -r monitor_id monitor_name; do
        # Filter workspaces for the current monitor_id and sort them
        local current_monitor_ws_ids_str
        current_monitor_ws_ids_str=$(echo "$all_workspaces_info" | awk -v mid="$monitor_id" '$2 == mid {print $1}' | sort -n | tr '\n' ' ')
        
        monitor_workspace_ids["$monitor_id"]="${current_monitor_ws_ids_str% }" # Store space-separated IDs

        if [[ -z "$current_monitor_ws_ids_str" ]]; then
            log "Monitor ID $monitor_id ($monitor_name) has no workspaces listed. Skipping base ID calculation for it."
            continue
        fi

        local min_ws_on_monitor
        read -r min_ws_on_monitor _ <<< "$current_monitor_ws_ids_str"

        if [[ -z "$min_ws_on_monitor" ]]; then
            log "Could not determine minimum workspace for monitor ID $monitor_id ($monitor_name) from string '$current_monitor_ws_ids_str'. Skipping."
            continue
        fi
        
        local base_id=$(( (min_ws_on_monitor - 1) / 10 * 10 + 1 ))
        monitor_base_ids["$monitor_id"]="$base_id"
        log "Monitor ID $monitor_id ($monitor_name): min_ws=$min_ws_on_monitor, base_id=$base_id"

        if [[ "$base_id" -lt "$temp_min_overall_base_id" ]]; then
            temp_min_overall_base_id="$base_id"
        fi
    done <<< "$all_monitors_info"

    if [[ "$temp_min_overall_base_id" -eq 99999 ]]; then
        die "Could not determine any monitor base IDs. Check Hyprland workspace configuration."
    fi
    overall_min_monitor_base_id="$temp_min_overall_base_id"
    log "Overall minimum monitor base ID: $overall_min_monitor_base_id"
}

# Determines the Alternate Group workspace IDs and its base ID
# Populates global array:
#   alternate_group_ws_ids (array of 10 workspace IDs)
# Sets global variable:
#   alternate_group_defining_base_id
declare -a alternate_group_ws_ids
alternate_group_defining_base_id=""

determine_alternate_group() {
    local env_alternate_group_str="${WORKSPACE_IDS_ALTERNATE_GROUP:-}"

    if [[ -n "$env_alternate_group_str" ]]; then
        log "WORKSPACE_IDS_ALTERNATE_GROUP is set. Raw value: \"$env_alternate_group_str\""
        # Convert space-separated string to array
        read -r -a env_ws_ids <<< "$env_alternate_group_str"
        log "Parsed env_ws_ids (count: ${#env_ws_ids[@]}): [${env_ws_ids[*]}]"
        
        if [[ "${#env_ws_ids[@]}" -ne 10 ]]; then
            die "WORKSPACE_IDS_ALTERNATE_GROUP must contain exactly 10 space-separated workspace IDs. Found ${#env_ws_ids[@]}."
        fi

        log "Validating each ID in WORKSPACE_IDS_ALTERNATE_GROUP:"
        for id_idx in "${!env_ws_ids[@]}"; do
            local id="${env_ws_ids[$id_idx]}"
            log "  Validating id[$id_idx]: '$id'"
            if ! [[ "$id" =~ ^[0-9]+$ ]]; then
                die "WORKSPACE_IDS_ALTERNATE_GROUP must contain only numeric IDs. Found '$id' at index $id_idx."
            fi
        done
        log "All IDs in WORKSPACE_IDS_ALTERNATE_GROUP are numeric."
        
        alternate_group_ws_ids=("${env_ws_ids[@]}")
        # Sort them numerically to correctly determine the defining base ID from the first element
        log "Alternate group IDs before sort: [${alternate_group_ws_ids[*]}]"
        IFS=$'\n' alternate_group_ws_ids=($(sort -n <<<"${alternate_group_ws_ids[*]}"))
        unset IFS
        log "Alternate group IDs after sort: [${alternate_group_ws_ids[*]}]"

        if [[ ${#alternate_group_ws_ids[@]} -eq 0 ]]; then
            die "Alternate group IDs array is empty after processing WORKSPACE_IDS_ALTERNATE_GROUP. This should not happen."
        fi

        local first_id_from_sorted_array="${alternate_group_ws_ids[0]}"
        log "First ID from sorted alternate_group_ws_ids: '$first_id_from_sorted_array'"
        
        # Defensively extract the first number part from the first ID
        local first_numeric_part=$(echo "$first_id_from_sorted_array" | awk '{print $1}' | grep -o '^[0-9]*' | head -n 1)
        if ! [[ "$first_numeric_part" =~ ^[0-9]+$ ]]; then
            die "Could not extract a valid numeric part from the first ID of WORKSPACE_IDS_ALTERNATE_GROUP ('$first_id_from_sorted_array'). Extracted: '$first_numeric_part'"
        fi
        log "Using first numeric part for base calculation: '$first_numeric_part'"

        alternate_group_defining_base_id=$(( (first_numeric_part - 1) / 10 * 10 + 1 ))
        log "Using Alternate Group from env var. Defining Base ID: $alternate_group_defining_base_id. IDs: ${alternate_group_ws_ids[*]}"
    else
        log "WORKSPACE_IDS_ALTERNATE_GROUP is not set. Using default Alternate Group."
        if [[ -z "$overall_min_monitor_base_id" ]]; then
            die "Cannot determine default Alternate Group: overall_min_monitor_base_id is not set."
        fi
        alternate_group_defining_base_id="$overall_min_monitor_base_id"
        alternate_group_ws_ids=()
        for i in {0..9}; do
            alternate_group_ws_ids+=("$((alternate_group_defining_base_id + i))")
        done
        log "Default Alternate Group. Defining Base ID: $alternate_group_defining_base_id. IDs: ${alternate_group_ws_ids[*]}"
    fi
}

# Checks if a workspace ID is present in a given array of workspace IDs
# Usage: is_workspace_in_array <ws_id> <array_name_as_string>
is_workspace_in_array() {
    local ws_id_to_check="$1"
    local arr_name="$2[@]"
    local arr=("${!arr_name}")
    for id_in_arr in "${arr[@]}"; do
        if [[ "$id_in_arr" -eq "$ws_id_to_check" ]]; then
            return 0 # True, found
        fi
    done
    return 1 # False, not found
}

# --- Main Script Logic ---
main() {
    if [[ -z "$TARGET_GROUP_INPUT" ]]; then
        die "Usage: $0 <target_group_number (0-9)> [override_flag (true/1)]"
    fi
    validate_target_group_num "$TARGET_GROUP_INPUT"

    local cursor_pos
    cursor_pos=$(hyprctl cursorpos -j || echo '{"x":-1,"y":-1}')
    local original_cursor_x
    original_cursor_x=$(echo "$cursor_pos" | jq -r '.x')
    local original_cursor_y
    original_cursor_y=$(echo "$cursor_pos" | jq -r '.y')
    
    if [[ "$original_cursor_x" -eq -1 ]]; then
        log "Warning: Could not determine original cursor position. Cursor will not be restored."
    else
        log "Original cursor position: x=$original_cursor_x, y=$original_cursor_y"
    fi

    local target_ws_offset
    target_ws_offset=$(calculate_target_offset "$TARGET_GROUP_INPUT")

    log "Target group input: $TARGET_GROUP_INPUT, Workspace offset: $target_ws_offset"
    log "Override flag: $OVERRIDE_FLAG_INPUT"

    calculate_all_monitor_base_ids
    determine_alternate_group

    local active_ws_id
    active_ws_id=$(get_active_workspace_id)
    log "Active workspace ID: $active_ws_id"

    local all_workspaces_info_for_active_lookup
    all_workspaces_info_for_active_lookup="$(get_all_workspaces_info)"
    
    local focused_monitor_hypr_id
    focused_monitor_hypr_id=$(echo "$all_workspaces_info_for_active_lookup" | awk -v awid="$active_ws_id" '$1 == awid {print $2; exit}')
    
    if [[ -z "$focused_monitor_hypr_id" ]]; then
        die "Could not determine the monitor for active workspace ID $active_ws_id."
    fi
    log "Monitor hosting active workspace (Hyprland ID): $focused_monitor_hypr_id"

    local other_monitors_commands=""
    local focused_monitor_command=""

    if [[ "$OVERRIDE_FLAG_INPUT" == "true" || "$OVERRIDE_FLAG_INPUT" == "1" ]]; then
        log "Override flag is active. Switching only focused monitor's workspace."
        local focused_monitor_base_id="${monitor_base_ids[$focused_monitor_hypr_id]:-}"
        if [[ -z "$focused_monitor_base_id" ]]; then
            die "Could not find base ID for focused monitor Hyprland ID $focused_monitor_hypr_id."
        fi
        local target_ws=$((focused_monitor_base_id + target_ws_offset))
        focused_monitor_command="dispatch focusmonitor $focused_monitor_hypr_id; dispatch workspace $target_ws;"
        log "Focused monitor (ID $focused_monitor_hypr_id) base: $focused_monitor_base_id, target: $target_ws"
    else
        log "Override flag is not active. Group switching logic applies."
        local active_ws_is_in_alternate_group=false
        if is_workspace_in_array "$active_ws_id" "alternate_group_ws_ids"; then
            active_ws_is_in_alternate_group=true
        fi

        if $active_ws_is_in_alternate_group; then
            log "Active workspace $active_ws_id is in the Alternate Group. Switching Alternate Group monitors."
        else
            log "Active workspace $active_ws_id is in the Main Group. Switching Main Group monitors."
        fi

        for monitor_hypr_id in "${!monitor_base_ids[@]}"; do
            local current_monitor_base_id="${monitor_base_ids[$monitor_hypr_id]}"
            local should_this_monitor_switch=false

            if $active_ws_is_in_alternate_group; then
                if [[ "$current_monitor_base_id" -eq "$alternate_group_defining_base_id" ]]; then
                    should_this_monitor_switch=true
                fi
            else
                if [[ "$current_monitor_base_id" -ne "$alternate_group_defining_base_id" ]]; then
                    should_this_monitor_switch=true
                fi
            fi

            if $should_this_monitor_switch; then
                local target_ws=$((current_monitor_base_id + target_ws_offset))
                local command_pair="dispatch focusmonitor $monitor_hypr_id; dispatch workspace $target_ws;"

                if [[ "$monitor_hypr_id" -eq "$focused_monitor_hypr_id" ]]; then
                    focused_monitor_command=$command_pair
                    log "Monitor (ID $monitor_hypr_id) is the FOCUSED one. Target: $target_ws. Saving for last."
                else
                    other_monitors_commands+=$command_pair
                    log "Monitor (ID $monitor_hypr_id) is an OTHER one. Target: $target_ws. Adding to batch."
                fi
            else
                log "Monitor (ID $monitor_hypr_id) base: $current_monitor_base_id. Not switching."
            fi
        done
    fi

    local final_dispatch_commands="${other_monitors_commands}${focused_monitor_command}"

    if [[ "$original_cursor_x" -ne -1 ]]; then
        final_dispatch_commands+="dispatch movecursor ${original_cursor_x} ${original_cursor_y};"
    fi

    if [[ -n "$final_dispatch_commands" ]]; then
        log "Executing hyprctl batch: $final_dispatch_commands"
        if ! hyprctl --batch "$final_dispatch_commands"; then
            die "hyprctl batch command failed."
        fi
        log "Workspace switch command sent."
    else
        log "No dispatch commands generated. Nothing to do."
    fi
}

# --- Run ---
main "$@"
exit 0