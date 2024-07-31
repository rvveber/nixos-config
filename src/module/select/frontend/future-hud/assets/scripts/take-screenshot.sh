#!/usr/bin/env bash

# Define variables
OUTPUT_DIR=$(xdg-user-dir PICTURES)/Screenshots
TIMESTAMP=$(date +%Y%m%d)
SECONDS_SINCE_MIDNIGHT=$(date +%s -d "$(date +%Y-%m-%d)" | awk '{print strftime("%s", systime()) - $1}')
FINAL_OUTPUT_PATH="$OUTPUT_DIR/$TIMESTAMP-$SECONDS_SINCE_MIDNIGHT.png"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Take a screenshot with grim and slurp
grim -g "$(slurp)" - | satty -f - --early-exit --save-after-copy --output-filename ${FINAL_OUTPUT_PATH} --copy-command "wl-copy" --font-family "Source Code Pro"

# Output the final file path for reference
echo "Screenshot saved to: $FINAL_OUTPUT_PATH"