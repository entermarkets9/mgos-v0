#!/usr/bin/env bash
# Source-only. Lets the DX scripts run on macOS and Windows Git Bash.
# Each shim is defined only when the native tool is missing or lacks the needed
# behaviour, so Linux behaviour is unchanged. Requires node (already required by
# every DX script) and perl for the fallbacks.

# GNU `realpath -m` (resolve even when the path does not exist). BSD/macOS
# realpath has no -m and fails on missing paths.
if ! realpath -m / >/dev/null 2>&1; then
  realpath() {
    [[ "${1:-}" == -m ]] && shift
    node -e '
      const fs = require("node:fs"), path = require("node:path");
      let p = path.resolve(process.argv[1]); const rest = [];
      while (!fs.existsSync(p) && path.dirname(p) !== p) { rest.unshift(path.basename(p)); p = path.dirname(p); }
      process.stdout.write(path.join(fs.realpathSync(p), ...rest) + "\n");
    ' "${1:-.}"
  }
fi

# sha256sum -> shasum (same "<hash>  <file|->" output format).
if ! command -v sha256sum >/dev/null 2>&1 && command -v shasum >/dev/null 2>&1; then
  sha256sum() { shasum -a 256 "$@"; }
fi

# util-linux flock on an inherited descriptor: `flock -w SECONDS FD` / `flock -u FD`.
# The lock lives on the shared open file description, so it survives the helper
# process and is released when the shell closes/unlocks the descriptor.
if ! command -v flock >/dev/null 2>&1 && command -v perl >/dev/null 2>&1; then
  flock() {
    local wait=0 unlock=0 fd
    while (($#)); do
      case "$1" in
        -w) wait="$2"; shift 2 ;;
        -u) unlock=1; shift ;;
        -n) wait=0; shift ;;
        *) fd="$1"; shift ;;
      esac
    done
    perl -MFcntl=:flock -MTime::HiRes=sleep,time -e '
      my ($fd, $wait, $unlock) = @ARGV;
      open(my $fh, ">&=", $fd) or exit 1;
      if ($unlock) { exit(flock($fh, LOCK_UN) ? 0 : 1); }
      my $deadline = time + $wait;
      until (flock($fh, LOCK_EX | LOCK_NB)) { exit 1 if time >= $deadline; sleep 0.1; }
      exit 0;
    ' "$fd" "$wait" "$unlock"
  }
fi
