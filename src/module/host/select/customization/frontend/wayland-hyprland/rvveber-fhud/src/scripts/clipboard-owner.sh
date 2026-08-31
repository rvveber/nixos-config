set -euo pipefail

runtime_dir=${XDG_RUNTIME_DIR:?}/rvveber-fhud-clipboard
selection=$runtime_dir/selection
mime_file=$runtime_dir/mime

[[ -r "$selection" && -r "$mime_file" ]] || exit 1
mime=$(<"$mime_file")

exec wl-copy --foreground --type "$mime" <"$selection"
