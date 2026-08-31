case "${1:-apps}" in
  apps)
    rvveber-fhud-ui request "toggle launcher"
    rvveber-fhud-focus-window hud
    ;;
  clipboard)
    rvveber-fhud-ui request "toggle clipboard"
    rvveber-fhud-focus-window hud
    ;;
  *)
    printf 'Usage: %s [apps|clipboard]\n' "$0" >&2
    exit 2
    ;;
esac
