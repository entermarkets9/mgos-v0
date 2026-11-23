#!/usr/bin/env bash
# Parallel-agent worktree slots on shared hosts (sh2 and any shared checkout).
#
# One writer per checkout. A slot is a dedicated `git worktree` with its own
# branch, so no agent ever runs `git checkout`/`git switch` in a checkout that
# another agent is using, and no in-progress edit is lost to a branch switch.
#
#   scripts/dx/slot.sh claim <name> [--ref <ref>] [--owner <label>]
#   scripts/dx/slot.sh release <name> [--force]
#   scripts/dx/slot.sh list
#   scripts/dx/slot.sh status
#
# Slots live in ${MGOS_DX_HOME:-$HOME/.mgos-dx}/worktrees/<name> on branch
# task/<name>. Releasing removes the worktree and keeps the branch, so committed
# work survives until it is merged into the development branch.
set -Eeuo pipefail

# Source-only portability shims (flock/realpath/sha256sum fallbacks).
_dx_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for _dx_p in "$_dx_here/portable.sh" "$_dx_here/dx-portable.sh"; do
  if [[ -f "$_dx_p" ]]; then source "$_dx_p"; break; fi
done
unset _dx_here _dx_p

DX_HOME="${MGOS_DX_HOME:-$HOME/.mgos-dx}"
# Tolerate Windows-style MGOS_DX_HOME (Git Bash/WSL users): backslashes would
# otherwise be lost to bash escape processing or break path joins.
DX_HOME="${DX_HOME//\\//}"
SLOTS="$DX_HOME/worktrees"
LOCK="$SLOTS/.claim.lock"
# The development branch is main. Resolve the first ref that actually exists so
# checkouts with and without a fetched remote both work.
DEFAULT_REF_CANDIDATES=("origin/main" "main")
DEFAULT_REF="${DEFAULT_REF_CANDIDATES[0]}"
NAME_RE='^[a-z0-9][a-z0-9._-]{1,40}$'

die() { printf 'slot: %s\n' "$*" >&2; exit 1; }
usage() { sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2; }

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null \
    || die "not inside a git worktree (run from any MGOS checkout)"
}

cmd_claim() {
  local name="" ref="" owner=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ref) [[ $# -ge 2 ]] || usage; ref="$2"; shift 2 ;;
      --owner) [[ $# -ge 2 ]] || usage; owner="$2"; shift 2 ;;
      -*) usage ;;
      *) [[ -z "$name" ]] || usage; name="$1"; shift ;;
    esac
  done
  [[ -n "$name" ]] || usage
  [[ "$name" =~ $NAME_RE ]] || die "invalid slot name '$name' (lowercase, 2-41 chars: a-z 0-9 . _ -)"

  local root target branch candidate
  root="$(repo_root)"
  target="$SLOTS/$name"
  branch="task/$name"

  if [[ -z "$ref" ]]; then
    for candidate in "${DEFAULT_REF_CANDIDATES[@]}"; do
      if git -C "$root" rev-parse --verify --quiet "$candidate" >/dev/null; then ref="$candidate"; break; fi
    done
    [[ -n "$ref" ]] || die "no development branch found; tried: ${DEFAULT_REF_CANDIDATES[*]}"
  fi

  [[ ! -e "$target" ]] || die "slot '$name' already claimed at $target (see: slot.sh list)"
  git -C "$root" rev-parse --verify --quiet "$branch" >/dev/null \
    && die "branch '$branch' already exists; release/reuse it or pick another slot name"
  git -C "$root" rev-parse --verify --quiet "$ref" >/dev/null \
    || die "ref '$ref' not found in $root (fetch first)"

  mkdir -p "$SLOTS"
  exec 9>"$LOCK"
  flock -w 120 9 || die "another claim is still in progress"
  [[ ! -e "$target" ]] || die "slot '$name' was claimed concurrently"

  git -C "$root" worktree add -b "$branch" --no-track "$target" "$ref" >/dev/null
  # Metadata lives beside the slot, never inside it: an untracked file would
  # make the checkout dirty and block release for the wrong reason.
  {
    printf 'name=%s\n' "$name"
    printf 'branch=%s\n' "$branch"
    printf 'ref=%s\n' "$ref"
    printf 'owner=%s\n' "${owner:-$USER}"
    printf 'created=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'source=%s\n' "$root"
  } > "$SLOTS/$name.slot"
  printf '%s\n' "$target"
}

cmd_release() {
  local name="" force=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force) force=1; shift ;;
      -*) usage ;;
      *) [[ -z "$name" ]] || usage; name="$1"; shift ;;
    esac
  done
  [[ -n "$name" ]] || usage
  [[ "$name" =~ $NAME_RE ]] || die "invalid slot name '$name'"

  local root target
  root="$(repo_root)"
  target="$SLOTS/$name"
  [[ -d "$target" ]] || die "no such slot '$name'"

  if [[ -n "$(git -C "$target" status --porcelain 2>/dev/null)" && "$force" -ne 1 ]]; then
    die "slot '$name' has uncommitted changes; commit or push them, or pass --force to discard"
  fi
  exec 9>"$LOCK"
  flock -w 120 9 || die "another release is still in progress"
  git -C "$root" worktree remove --force "$target" >/dev/null 2>&1 || rm -rf "$target"
  rm -f "$SLOTS/$name.slot"
  printf 'released %s (branch %s retained)\n' "$name" "task/$name"
}

cmd_list() {
  local root
  root="$(repo_root)"
  git -C "$root" worktree list --porcelain | awk -v slots="$SLOTS" '
    /^worktree / { path = substr($0, 10) }
    /^branch /   { branch = substr($0, 8); sub(/^refs\/heads\//, "", branch) }
    /^detached$/ { branch = "(detached)" }
    /^$/ {
      if (index(path, slots "/") == 1) {
        n = split(path, parts, "/"); name = parts[n]
        printf "%-24s %-28s %s\n", name, branch, path
      }
      path = ""; branch = ""
    }
  '
}

cmd_status() {
  local root target
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git worktree"
  target="$root"
  printf 'checkout: %s\n' "$target"
  printf 'branch:   %s\n' "$(git -C "$target" symbolic-ref --quiet --short HEAD 2>/dev/null || echo '(detached HEAD)')"
  if [[ -f "$SLOTS/$(basename "$target").slot" ]] || [[ "$target" == "$SLOTS/"* ]]; then
    printf 'slot:     %s\n' "$(basename "$target")"
  else
    printf 'slot:     shared checkout - never switch branches or stash here\n'
  fi
  local dirty
  dirty="$(git -C "$target" status --porcelain 2>/dev/null | wc -l)"
  printf 'dirty:    %s path(s)\n' "$dirty"
  git -C "$target" status --porcelain 2>/dev/null | head -20
}

[[ $# -ge 1 ]] || usage
cmd="$1"; shift
case "$cmd" in
  claim) cmd_claim "$@" ;;
  release) cmd_release "$@" ;;
  list) cmd_list ;;
  status) cmd_status ;;
  -h|--help|help) usage ;;
  *) usage ;;
esac
