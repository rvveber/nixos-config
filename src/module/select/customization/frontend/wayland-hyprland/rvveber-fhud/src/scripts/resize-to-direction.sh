#!/usr/bin/env bash

#fixme

# Passed argument will be one of r, l, u, d depending on which arrow key was pressed
direction=$1

# Define golden ratio and halving sequence in percentage terms
golden_ratio_and_halving_sequence=(61.80 50 38.20 30.90 25 19.10 15.45 12.5)

# Function to get active window details
get_active_window() {
    hyprctl activewindow
}

# Function to get monitor details
get_monitors() {
    hyprctl monitors
}

# Function to round float values
round() {
    echo $(awk "BEGIN {print int($1 + 0.5)}")
}

# Function to resize the window with rounded values
resize_window() {
    local new_width=$(round "$1")
    local new_height=$(round "$2")
    hyprctl notify -1 10000 "rgb(ff1ea3)" "hyprctl dispatch resizeactive exact ${new_width} ${new_height}"
    hyprctl dispatch resizeactive exact "${new_width}" "${new_height}"
}

# Get monitor and window details
monitor_info=$(get_monitors)
active_window_info=$(get_active_window)

# Extract monitor ID where the active window is located
active_monitor_id=$(echo "$active_window_info" | grep -oP '(?<=monitor: )[0-9]+')

# Filter out the monitor details where the active window is located
active_monitor_info=$(echo "$monitor_info" | awk "/Monitor.*(ID $active_monitor_id)/,/^$/")

# Extract monitor resolution (width and height)
monitor_width=$(echo "$active_monitor_info" | grep -oP '\d+x\d+(?=@)' | head -n 1 | awk -F'x' '{print $1}')
monitor_height=$(echo "$active_monitor_info" | grep -oP '\d+x\d+(?=@)' | head -n 1 | awk -F'x' '{print $2}')

# Extract the monitor position offset (e.g., "at 1600x0")
monitor_offset_x=$(echo "$active_monitor_info" | grep -oP '(?<=at )\d+x\d+' | head -n 1 | awk -F'x' '{print $1}')
monitor_offset_y=$(echo "$active_monitor_info" | grep -oP '(?<=at )\d+x\d+' | head -n 1 | awk -F'x' '{print $2}')

# Calculate monitor center
monitor_center_x=$(awk "BEGIN {print $monitor_width / 2}")
monitor_center_y=$(awk "BEGIN {print $monitor_height / 2}")

# Extract window size and position from active window info
window_x=$(echo "$active_window_info" | grep -oP '(?<=at: )\d+,\d+' | awk -F',' '{print $1}')
window_y=$(echo "$active_window_info" | grep -oP '(?<=at: )\d+,\d+' | awk -F',' '{print $2}')

window_width=$(echo "$active_window_info" | grep -oP '(?<=size: )\d+,\d+' | awk -F',' '{print $1}')
window_height=$(echo "$active_window_info" | grep -oP '(?<=size: )\d+,\d+' | awk -F',' '{print $2}')

# Adjust window_x and window_y relative to the active monitor by subtracting the monitor offset
adjusted_window_x=$(( window_x - monitor_offset_x ))
adjusted_window_y=$(( window_y - monitor_offset_y ))

# Calculate window center relative to the active monitor
window_center_x=$(awk "BEGIN {print $adjusted_window_x + $window_width / 2}")
window_center_y=$(awk "BEGIN {print $adjusted_window_y + $window_height / 2}")

# Round the calculated center positions
window_center_x=$(round "$window_center_x")
window_center_y=$(round "$window_center_y")
monitor_center_x=$(round "$monitor_center_x")
monitor_center_y=$(round "$monitor_center_y")

# Function to calculate the pixel-based sequence from percentages
calculate_pixel_sequence() {
    local total_size=$1
    local sequence=("${!2}")
    local pixel_sequence=()

    for percentage in "${sequence[@]}"; do
        pixel_value=$(awk "BEGIN {print int(($total_size * $percentage) / 100)}")
        pixel_sequence+=("$pixel_value")
    done
    echo "${pixel_sequence[@]}"
}

# Calculate width and height sequences in pixels
width_pixel_sequence=($(calculate_pixel_sequence "$monitor_width" golden_ratio_and_halving_sequence[@]))
height_pixel_sequence=($(calculate_pixel_sequence "$monitor_height" golden_ratio_and_halving_sequence[@]))

# Function to get the closest value from the pixel sequence
get_closest_value() {
    local current_size=$1
    local pixel_sequence=("${!2}")
    local closest_value=${pixel_sequence[0]}
    local smallest_diff=$(awk "BEGIN {print ($current_size - ${pixel_sequence[0]})^2}")

    for value in "${pixel_sequence[@]}"; do
        diff=$(awk "BEGIN {print ($current_size - $value)^2}")
        if awk "BEGIN {exit !($diff < $smallest_diff)}"; then
            smallest_diff=$diff
            closest_value=$value
        fi
    done

    echo "$closest_value"
}

# Function to get the next size based on direction and pixel sequences
get_next_size() {
    local current_size=$1
    local increment=$2
    local pixel_sequence=("${!3}")

    local closest_value=$(get_closest_value "$current_size" pixel_sequence[@])

    for i in "${!pixel_sequence[@]}"; do
        if [[ "$closest_value" -eq "${pixel_sequence[$i]}" ]]; then
            if [[ "$increment" == "increase" && $i -gt 0 ]]; then
                echo "${pixel_sequence[$((i-1))]}"
            elif [[ "$increment" == "decrease" && $i -lt $((${#pixel_sequence[@]} - 1)) ]]; then
                echo "${pixel_sequence[$((i+1))]}"
            else
                echo "$closest_value"
            fi
            return
        fi
    done

    echo "$current_size"
}

# Function to determine resizing logic based on direction and window position relative to monitor center
resize_based_on_direction() {
    local axis_center=$1
    local monitor_center=$2
    local size=$3
    local pixel_sequence=("${!4}")
    local direction=$5
    local new_size

    if [[ "$direction" == "decrease" ]]; then
        new_size=$(get_next_size "$size" "decrease" pixel_sequence[@])
    else
        new_size=$(get_next_size "$size" "increase" pixel_sequence[@])
    fi

    echo "$new_size"
}

# Apply the resizing logic based on direction
case "$direction" in
    r)
        hyprctl notify -1 10000 "rgb(ff1ea3)" "window_center_x=$window_center_x \n monitor_center_x=$monitor_center_x"
        if (( window_center_x >= monitor_center_x )); then
            hyprctl notify -1 10000 "rgb(ff1ea3)" "decrease"
            hyprctl notify -1 10000 "rgb(ff1ea3)" "$window_width"
            new_width=$(resize_based_on_direction "$window_center_x" "$monitor_center_x" "$window_width" width_pixel_sequence[@] "decrease")
            hyprctl notify -1 10000 "rgb(ff1ea3)" "$new_width"
        else
            hyprctl notify -1 10000 "rgb(ff1ea3)" "increase"
            hyprctl notify -1 10000 "rgb(ff1ea3)" "$window_width"
            new_width=$(resize_based_on_direction "$window_center_x" "$monitor_center_x" "$window_width" width_pixel_sequence[@] "increase")
            hyprctl notify -1 10000 "rgb(ff1ea3)" "$new_width"
        fi
        resize_window "$new_width" "$window_height"
        ;;
    l)
        hyprctl notify -1 10000 "rgb(ff1ea3)" "window_center_x=$window_center_x \n monitor_center_x=$monitor_center_x"
        if (( window_center_x <= monitor_center_x )); then
            hyprctl notify -1 10000 "rgb(ff1ea3)" "decrease"
            hyprctl notify -1 10000 "rgb(ff1ea3)" "$window_width"
            new_width=$(resize_based_on_direction "$window_center_x" "$monitor_center_x" "$window_width" width_pixel_sequence[@] "decrease")
            hyprctl notify -1 10000 "rgb(ff1ea3)" "$new_width"
        else
            hyprctl notify -1 10000 "rgb(ff1ea3)" "increase"
            hyprctl notify -1 10000 "rgb(ff1ea3)" "$window_width"
            new_width=$(resize_based_on_direction "$window_center_x" "$monitor_center_x" "$window_width" width_pixel_sequence[@] "increase")
            hyprctl notify -1 10000 "rgb(ff1ea3)" "$new_width"
        fi
        resize_window "$new_width" "$window_height"
        ;;
    u)
        if (( window_center_y < monitor_center_y )); then
            new_height=$(resize_based_on_direction "$window_center_y" "$monitor_center_y" "$window_height" height_pixel_sequence[@] "decrease")
        else
            new_height=$(resize_based_on_direction "$window_center_y" "$monitor_center_y" "$window_height" height_pixel_sequence[@] "increase")
        fi
        resize_window "$window_width" "$new_height"
        ;;
    d)
        if (( window_center_y > monitor_center_y )); then
            new_height=$(resize_based_on_direction "$window_center_y" "$monitor_center_y" "$window_height" height_pixel_sequence[@] "decrease")
        else
            new_height=$(resize_based_on_direction "$window_center_y" "$monitor_center_y" "$window_height" height_pixel_sequence[@] "increase")
        fi
        resize_window "$window_width" "$new_height"
        ;;
esac