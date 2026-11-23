#!/usr/bin/env bash
set -Eeuo pipefail
set +x
CLI="$(command -v gitnexus || true)"
if [[ -z "$CLI" || "$CLI" == "$0" ]]; then
  echo "Use the installed GitNexus CLI on PATH; external DX installation and storage overrides are retired." >&2
  exit 127
fi
exec "$CLI" "$@"
