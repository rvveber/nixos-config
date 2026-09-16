case "${1:-apps}" in
  apps)
    rvveber-fhud-ui ipc call hud toggle apps
    ;;
  clipboard)
    rvveber-fhud-ui ipc call hud toggle clipboard
    ;;
  *)
    printf 'Usage: %s [apps|clipboard]\n' "$0" >&2
    exit 2
    ;;
esac
