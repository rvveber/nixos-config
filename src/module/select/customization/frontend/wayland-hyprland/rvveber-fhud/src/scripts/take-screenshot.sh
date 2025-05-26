#!/usr/bin/env bash
# requires: grim slurp hyprpicker magick satty

# Define variables
# Determine the Pictures directory
echo $XDG_PICTURES_DIR
if [ -n "$XDG_PICTURES_DIR" ]; then
  OUTPUT_DIR="$XDG_PICTURES_DIR/Screenshots"
elif command -v xdg-user-dir &> /dev/null; then
  OUTPUT_DIR=$(xdg-user-dir PICTURES)/Screenshots
else
  OUTPUT_DIR="$HOME/Pictures/Screenshots"
fi
TIMESTAMP=$(date +%Y%m%d)
SECONDS_SINCE_MIDNIGHT=$(($(date +%s) - $(date -d "$(date +%Y-%m-%d)" +%s)))
FINAL_OUTPUT_PATH="$OUTPUT_DIR/$TIMESTAMP-$SECONDS_SINCE_MIDNIGHT.png"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Freeze the screen by overlaying a screenshot with hyprpicker.
# grim pipes its output to hyprpicker. The pipeline runs in the background.
# HYPRPICKER_PID will be the PID of the hyprpicker process itself.
grim - | hyprpicker -r -z > /dev/null &
HYPRPICKER_PID=$!

# Wait a very short moment for hyprpicker to initialize and overlay the screen
# This delay might need adjustment based on system performance.
sleep 0.2

# Select the region using slurp, launched via uwsm
SELECTED_GEOMETRY=$(slurp)

# Kill hyprpicker (the freezer) now that selection is done.
# Trying SIGTERM as SIGUSR1 was not effective.
if [ -n "$HYPRPICKER_PID" ]; then
  kill -SIGTERM "$HYPRPICKER_PID"
  wait "$HYPRPICKER_PID" 2>/dev/null # Wait for it to exit
fi

# If a region was selected, take the actual screenshot of that region
if [ -n "$SELECTED_GEOMETRY" ]; then
  grim -g "$SELECTED_GEOMETRY" "$FINAL_OUTPUT_PATH"
else
  echo "Screenshot cancelled or region selection failed."
  # Clean up potential empty file if grim was not called
  rm -f "$FINAL_OUTPUT_PATH"
  exit 1
fi

# Process the screenshot with magick and satty
magick "${FINAL_OUTPUT_PATH}" -quality 75 "${FINAL_OUTPUT_PATH}"
satty -f "${FINAL_OUTPUT_PATH}" --initial-tool "rectangle" --early-exit --save-after-copy --output-filename "${FINAL_OUTPUT_PATH}" --copy-command "wl-copy" --font-family "Source Code Pro" --disable-notifications --corner-roundness 5

# Output the final file path for reference
echo "Screenshot saved to: $FINAL_OUTPUT_PATH"