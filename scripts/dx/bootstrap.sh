#!/usr/bin/env bash
set -Eeuo pipefail
LEVEL=runtime
TOOL=""
EXPLICIT_LEVEL=0
INCLUDE_GITNEXUS=0
usage() { echo "Usage: bootstrap.sh [--level runtime|cli|full] [--tool <installed-cli>] [--with-gitnexus]" >&2; exit 2; }
while (($#)); do
  case "$1" in
    --level) [[ $# -ge 2 ]] || usage; LEVEL="$2"; EXPLICIT_LEVEL=1; shift 2 ;;
    --tool) [[ $# -ge 2 && -z "$TOOL" ]] || usage; TOOL="$2"; shift 2 ;;
    --with-gitnexus) INCLUDE_GITNEXUS=1; shift ;;
    *) usage ;;
  esac
done
case "$LEVEL" in runtime|cli|full) ;; *) usage ;; esac
case "$TOOL" in ""|gitnexus|gh|node|yarn|npm|psql|redis-cli|ssh|sshpass) ;; *) usage ;; esac
if [[ -n "$TOOL" ]]; then
  [[ "$EXPLICIT_LEVEL" == 0 || "$LEVEL" == cli ]] || usage
  LEVEL=cli
fi
[[ "$LEVEL" != cli || -n "$TOOL" ]] || usage
[[ "$INCLUDE_GITNEXUS" == 0 || "$LEVEL" == full ]] || usage
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ "$LEVEL" == runtime ]]; then exec bash "$ROOT/scripts/dx/runtime.sh"; fi
TOOLS=("$TOOL")
if [[ "$LEVEL" == full ]]; then
  TOOLS=(git node yarn gh ssh sshpass psql redis-cli)
  [[ "$INCLUDE_GITNEXUS" == 0 ]] || TOOLS+=(gitnexus)
fi
for tool in "${TOOLS[@]}"; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Required CLI '$tool' is not installed on PATH. Install it explicitly; automatic provisioning is retired." >&2
    exit 127
  }
done
echo "Installed CLI availability checked. No tools, credentials or configuration were changed."
