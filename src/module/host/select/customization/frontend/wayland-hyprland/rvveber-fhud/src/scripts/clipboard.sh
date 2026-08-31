set -euo pipefail

command=${1:-}
id=${2:-}
return_target=${3:-}
phase=arguments

log() {
  local priority=${1:-info}
  shift
  printf '%s\n' "$*" | systemd-cat --identifier=rvveber-fhud-clipboard --priority="$priority"
}

log_failure() {
  local status=$?
  set +e
  log err "result=failure command=$command id=${id:-none} phase=$phase status=$status"
  exit "$status"
}

trap log_failure ERR

require_id() {
  case "$id" in
    '' | *[!0-9]*)
      printf 'Invalid clipboard entry id: %s\n' "$id" >&2
      exit 2
      ;;
  esac
}

require_return_target() {
  if [[ "$return_target" =~ ^[0-9a-fA-F]+$ ]]; then
    return_target=0x$return_target
  elif [[ -n "$return_target" && ! "$return_target" =~ ^0x[0-9a-fA-F]+$ ]]; then
    printf 'Invalid return window address: %s\n' "$return_target" >&2
    exit 2
  fi
}

query() {
  printf '%s\t\n' "$id"
}

own_selection() {
  local runtime_dir selection mime_file decoded check mime ready
  runtime_dir=${XDG_RUNTIME_DIR:?}/rvveber-fhud-clipboard
  selection=$runtime_dir/selection
  mime_file=$runtime_dir/mime
  decoded=$(mktemp)
  check=$(mktemp)
  trap 'rm -f "$decoded" "$check"' RETURN

  umask 077
  install -d -m 0700 "$runtime_dir"
  phase=decode
  query | cliphist decode >"$decoded"
  mime=$(file --brief --mime-type "$decoded")
  [[ "$mime" != application/x-empty ]] || mime=text/plain
  log info "result=progress command=paste id=$id phase=decoded bytes=$(wc -c <"$decoded") mime=$mime"
  install -m 0600 "$decoded" "$selection"
  printf '%s\n' "$mime" >"$mime_file"

  phase=owner-restart
  systemctl --user restart rvveber-fhud-clipboard-owner.service

  phase=publish
  ready=false
  for ((attempt = 0; attempt < 50; attempt++)); do
    if wl-paste --type "$mime" --no-newline >"$check" 2>/dev/null && cmp -s "$selection" "$check"; then
      ready=true
      break
    fi
    sleep 0.01
  done

  if [[ "$ready" != true ]]; then
    printf 'Clipboard owner did not publish entry %s\n' "$id" >&2
    exit 1
  fi
  log info "result=progress command=paste id=$id phase=published mime=$mime"
}

focus_return_target() {
  [[ -n "$return_target" ]] || return
  phase=focus-return-target
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$return_target\" })" >/dev/null

  for ((attempt = 0; attempt < 50; attempt++)); do
    if [[ "$(hyprctl activewindow -j | jq -r '.address // empty')" == "$return_target" ]]; then
      return
    fi
    sleep 0.01
  done
}

wait_for_hud_to_close() {
  phase=wait-for-hud-close
  for ((attempt = 0; attempt < 50; attempt++)); do
    if ! hyprctl -j clients | jq -e '.[] | select(.title == "FHUD")' >/dev/null; then
      return
    fi
    sleep 0.01
  done
}

case "$command" in
  list)
    phase=list
    raw_list=$(mktemp)
    trap 'rm -f "$raw_list"' EXIT
    for ((attempt = 0; attempt < 5; attempt++)); do
      if cliphist list >"$raw_list"; then
        entries=$(wc -l <"$raw_list")
        tr -d '\000' <"$raw_list"
        log info "result=success command=list entries=$entries"
        exit
      fi
      sleep 0.02
    done
    log err "result=failure command=list phase=list attempts=5"
    exit 1
    ;;
  paste)
    log info "result=start command=paste id=${id:-none} target=${return_target:-activewindow}"
    require_id
    require_return_target
    own_selection
    wait_for_hud_to_close
    focus_return_target
    phase=send-shortcut
    if [[ -n "$return_target" ]]; then
      hyprctl dispatch "hl.dsp.send_shortcut({ mods = \"CTRL\", key = \"V\", window = \"address:$return_target\" })" >/dev/null
    else
      hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL", key = "V" })' >/dev/null
    fi
    log info "result=success command=paste id=$id target=${return_target:-activewindow}"
    ;;
  delete)
    log info "result=start command=delete id=${id:-none}"
    require_id
    phase=delete
    query | cliphist delete
    runtime_dir=${XDG_RUNTIME_DIR:?}/rvveber-fhud-clipboard
    rm -f "$runtime_dir/$id.png"
    rm -f "$runtime_dir/$id-cover.png"
    log info "result=success command=delete id=$id"
    ;;
  thumbnail)
    require_id
    phase=thumbnail
    runtime_dir=${XDG_RUNTIME_DIR:?}/rvveber-fhud-clipboard
    target="$runtime_dir/$id-cover.png"
    umask 077
    install -d -m 0700 "$runtime_dir"

    if [[ ! -s "$target" ]]; then
      raw=$(mktemp "$runtime_dir/raw.XXXXXX")
      thumbnail=$(mktemp "$runtime_dir/thumbnail.XXXXXX")
      trap 'rm -f "$raw" "$thumbnail"' EXIT
      query | cliphist decode >"$raw"

      case "$(file --brief --mime-type "$raw")" in
        image/*)
          magick "${raw}[0]" -auto-orient -thumbnail '128x80^' -gravity center -extent 128x80 "png:$thumbnail"
          chmod 0600 "$thumbnail"
          mv "$thumbnail" "$target"
          ;;
        *)
          exit 1
          ;;
      esac
    fi

    printf '%s\n' "$target"
    log info "result=success command=thumbnail id=$id"
    ;;
  *)
    printf 'Usage: %s {list|paste|delete|thumbnail} [id]\n' "$0" >&2
    exit 2
    ;;
esac
