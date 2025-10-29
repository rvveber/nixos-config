#!/usr/bin/env bash
# High-level overview:
# - Freeze screen with hyprpicker for stable selection.
# - Select region with slurp.
# - Capture and edit screenshot with grim and satty.
# - Export to PNG and AVIF with adaptive quality.
# - Handle clipboard for broad compatibility.
#
# Dependencies: grim, slurp, hyprpicker, satty, hyprctl, jq, avifenc, wl-copy, mkfifo
# Tunables allow customization; script is robust to cancellations and errors.

set -euo pipefail

# --- Tunables ---
: "${AVIF_BASE_QUALITY:=80}"    # Base quality (0-100); adjusted by image size.
: "${AVIF_SPEED:=6}"            # Encoding speed (0=slowest/best - 10=fastest).
: "${AVIF_YUV:=444}"            # Chroma subsampling (444=crisp text, 420=smaller files).
: "${KEEP_PNG:=1}"              # Retain PNG after AVIF export (1=yes, 0=no).
: "${DEBUG:=0}"                 # Enable debug logs (1=yes).

# --- Utility Functions ---
say() { printf '%s\n' "$*"; }
log() {
  if [ "$DEBUG" -eq 1 ]; then
    printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*"
  fi
}
need() { command -v "$1" >/dev/null 2>&1 || { say "Missing dependency: $1"; exit 1; }; }

for dep in grim slurp hyprpicker satty hyprctl jq avifenc wl-copy mkfifo; do need "$dep"; done

# --- Paths and Temps ---
OUTDIR="${XDG_PICTURES_DIR:-$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")}/Screenshots"
mkdir -p "$OUTDIR"
DATESTAMP="$(date +%Y%m%d)"
SECS="$(( $(date +%s) - $(date -d "$(date +%Y-%m-%d)" +%s) ))"
PNG_PATH="$OUTDIR/$DATESTAMP-$SECS.png"
AVIF_PATH="${PNG_PATH%.png}.avif"
SATLOG="$(mktemp)"
PIPE="$(mktemp -u)"; mkfifo "$PIPE"

# --- Helpers for Hyprland Layers ---
layer_present() { hyprctl -j layers | jq -e --arg n "$1" '.. | objects | select(.namespace?==$n or .name?==$n)' >/dev/null 2>&1; }
wait_layer_present() {
  local n="$1"; for _ in {1..240}; do layer_present "$n" && return 0; sleep 0.005; done; return 1;
}
wait_layer_absent() {
  local n="$1"; for _ in {1..240}; do layer_present "$n" || return 0; sleep 0.005; done; return 1;
}

# --- State and Cleanup ---
HYPRPICKER_PID=""
_ANIM_ORIG="$(hyprctl -j getoption animations:enabled 2>/dev/null | jq -r '.int // .value // .set // 1' 2>/dev/null || echo 1)"
cleanup() {
  set +e
  [ -n "${HYPRPICKER_PID:-}" ] && kill -SIGTERM "$HYPRPICKER_PID" 2>/dev/null
  [ -n "${HYPRPICKER_PID:-}" ] && wait "$HYPRPICKER_PID" 2>/dev/null
  hyprctl keyword animations:enabled "${_ANIM_ORIG}" >/dev/null 2>&1
  rm -f "$PIPE" "$SATLOG" 2>/dev/null
  set -e
}
trap cleanup EXIT

# --- Disable Animations Temporarily ---
hyprctl keyword animations:enabled 0 >/dev/null 2>&1
log "Animations disabled (original: ${_ANIM_ORIG})."

# --- Freeze Screen and Select Region ---
say "Freeze active — select region…"
grim - | hyprpicker -r -z >/dev/null & HYPRPICKER_PID=$!
wait_layer_present "hyprpicker" || { say "Failed to detect freeze layer (namespace: hyprpicker). Check with 'hyprctl layers'."; exit 1; }
log "Freeze layer active."

GEOM="$(slurp -d || true)"
[ -z "$GEOM" ] && { say "Selection cancelled."; exit 0; }
log "Selected: $GEOM"

wait_layer_absent "selection" || wait_layer_absent "slurp" || true  # Clear slurp overlay

# --- Capture and Edit with Satty ---
satty -f - \
  --initial-tool "rectangle" \
  --early-exit \
  --save-after-copy \
  --output-filename "$PNG_PATH" \
  --copy-command "wl-copy" \
  --font-family "Source Code Pro" \
  --disable-notifications \
  --corner-roundness 5 \
  <"$PIPE" >"$SATLOG" 2>&1 &
SATTY_PID=$!

grim -g "$GEOM" -t png - >"$PIPE" ; GRIM_STATUS=$?
kill -SIGTERM "$HYPRPICKER_PID" 2>/dev/null
wait "$HYPRPICKER_PID" 2>/dev/null || true  # Ignore exit status (e.g., 143 from SIGTERM)
HYPRPICKER_PID=""
rm -f "$PIPE" 2>/dev/null

wait "$SATTY_PID" 2>/dev/null
log "Satty closed (grim status: $GRIM_STATUS)."
say "Saved PNG: $PNG_PATH"

# --- Export AVIF Adaptively ---
SEL_W="${GEOM##* }"; SEL_W="${SEL_W%x*}"
SEL_H="${GEOM##*x}"
PIXELS=$(( SEL_W * SEL_H ))
QUALITY="$AVIF_BASE_QUALITY"
if   (( PIXELS <= 1000000 )); then QUALITY=$(( QUALITY + 10 ))
elif (( PIXELS >= 8000000 )); then QUALITY=$(( QUALITY - 10 ))
fi
(( QUALITY > 100 )) && QUALITY=100
(( QUALITY < 50  )) && QUALITY=50

say "Exporting AVIF (quality=$QUALITY, yuv=$AVIF_YUV, speed=$AVIF_SPEED)…"
avifenc -q "$QUALITY" -s "$AVIF_SPEED" -y "$AVIF_YUV" -d 8 -j all "$PNG_PATH" "$AVIF_PATH"
say "Saved AVIF: $AVIF_PATH"

# --- Update Clipboard if Copied in Satty ---
if grep -q '^Copied to clipboard\.$' "$SATLOG"; then
  wl-copy --type image/png < "$AVIF_PATH" || wl-copy < "$AVIF_PATH"
  say "Clipboard updated (AVIF as image/png)."
fi

# --- Optional PNG Cleanup ---
[ "$KEEP_PNG" = "1" ] || rm -f "$PNG_PATH" 2>/dev/null

say "Done."