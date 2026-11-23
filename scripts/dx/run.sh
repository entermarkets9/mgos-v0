#!/usr/bin/env bash
# Forward to an operator-installed CLI on PATH. DX never provisions tools.
set -Eeuo pipefail
[[ $# -gt 0 ]] || { echo "Usage: npm run dx -- <installed-cli> [arguments]" >&2; exit 2; }
TOOL="$1"
shift
case "$TOOL" in
  gitnexus|gh|node|yarn|npm|psql|redis-cli|ssh|sshpass) ;;
  *) echo "Unknown DX CLI. Use an installed supported tool." >&2; exit 2 ;;
esac
command -v "$TOOL" >/dev/null 2>&1 || {
  echo "CLI '$TOOL' is not installed on PATH. Install it explicitly; DX does not provision tools." >&2
  exit 127
}
exec "$TOOL" "$@"
