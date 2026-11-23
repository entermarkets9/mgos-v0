#!/usr/bin/env bash
# App dependencies only: no developer CLI installation, auth, database or sync.
# Yarn 4 (node-modules linker) variant of the DX runtime contract.
set -Eeuo pipefail
_dx_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for _dx_p in "$_dx_here/portable.sh" "$_dx_here/dx-portable.sh"; do
  if [[ -f "$_dx_p" ]]; then source "$_dx_p"; break; fi
done
unset _dx_here _dx_p
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
case "${1:-}" in ""|--check) ;; *) echo "Usage: runtime.sh [--check]" >&2; exit 2 ;; esac
[[ $# -le 1 ]] || exit 2
for tool in node yarn sha256sum flock; do
  command -v "$tool" >/dev/null || { echo "Required runtime tool missing: $tool" >&2; exit 127; }
done
STAMP="$ROOT/node_modules/.mgos-runtime-lock"
HASH="$( {
  # Script/description edits must not trigger a dependency reinstall.
  node - "$ROOT/package.json" <<'JS'
const fs = require("node:fs");
const manifest = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const keys = ["name", "version", "dependencies", "devDependencies", "optionalDependencies",
  "peerDependencies", "resolutions", "workspaces", "engines", "packageManager", "os", "cpu", "libc"];
const selected = Object.fromEntries(keys.filter(key => key in manifest).map(key => [key, manifest[key]]));
selected.installScripts = Object.fromEntries(["preinstall", "install", "postinstall", "prepare"]
  .filter(key => manifest.scripts?.[key]).map(key => [key, manifest.scripts[key]]));
process.stdout.write(JSON.stringify(selected));
JS
  sha256sum "$ROOT/yarn.lock"
  node --version
  yarn --version
} | sha256sum | cut -d' ' -f1)"
ready() {
  local recorded
  recorded="$(cat "$STAMP" 2>/dev/null || true)"
  [[ "$recorded" == "$HASH" &&
    -e "$ROOT/node_modules/.bin/nx" && -e "$ROOT/node_modules/.bin/tsx" ]]
}
if [[ "${1:-}" == --check ]]; then
  ready || { echo "Runtime dependencies missing/stale; run bash scripts/dx/runtime.sh." >&2; exit 1; }
else
  # Serialize writers per checkout; do not share node_modules between worktrees.
  LOCK_ID="$(printf '%s' "$ROOT" | sha256sum | cut -c1-24)"
  exec 9>"${TMPDIR:-/tmp}/mgos-runtime-$UID-$LOCK_ID.lock"
  flock -w 300 9 || { echo "Runtime dependency installation is still running." >&2; exit 1; }
  if ! ready; then
    (cd "$ROOT" && yarn install --immutable </dev/null)
    printf '%s\n' "$HASH" > "$STAMP"
    ready || { echo "Runtime install completed without required build/test executables." >&2; exit 1; }
  fi
  printf '%s\n' "$HASH" > "$STAMP"
fi
echo "Runtime dependencies ready; provider authorization not required."
