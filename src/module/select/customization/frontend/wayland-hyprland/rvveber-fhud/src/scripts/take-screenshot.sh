#!/usr/bin/env bash

# Define variables
# If xdg-user-dir is available use it, otherwise use the default path
if command -v xdg-user-dir &> /dev/null; then
  OUTPUT_DIR=$(xdg-user-dir PICTURES)/Screenshots
else
  OUTPUT_DIR=$HOME/Pictures/Screenshots
fi
TIMESTAMP=$(date +%Y%m%d)
SECONDS_SINCE_MIDNIGHT=$(($(date +%s) - $(date -d "$(date +%Y-%m-%d)" +%s)))
FINAL_OUTPUT_PATH="$OUTPUT_DIR/$TIMESTAMP-$SECONDS_SINCE_MIDNIGHT.png"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Start wayfreeze with the after-freeze command
wayfreeze --after-freeze-cmd " \
    grim -g \"\$(slurp)\" \"${FINAL_OUTPUT_PATH}\"; \
    kill \$(pgrep -x wayfreeze); \
    magick \"${FINAL_OUTPUT_PATH}\" -quality 75 \"${FINAL_OUTPUT_PATH}\"; \
    satty -f \"${FINAL_OUTPUT_PATH}\" \
        --early-exit \
        --save-after-copy \
        --output-filename \"${FINAL_OUTPUT_PATH}\" \
        --copy-command \"wl-copy\" \
        --font-family \"Source Code Pro\" \
" &

# Wait for wayfreeze to finish
wait

# Output the final file path for reference
echo "Screenshot saved to: $FINAL_OUTPUT_PATH"
S