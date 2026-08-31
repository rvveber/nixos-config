set -euo pipefail

exec bash "$(dirname "$0")/switch-workspace-group.sh" move "$@"
