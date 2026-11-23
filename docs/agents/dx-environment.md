# MGOS developer environment (agent DX)

Ported from nabra-smma's DX and worktree model (`docs/current/dx-environment.md`
and the SH1 slot workflow), adapted to MGOS: Yarn 4 / Node `^26.5.1`, `main` as
the integration branch, sh2 as the shared Linux dev box, the operator PC clone
at `C:\codespace\mgos`. The binding rules live in [AGENTS.md](../../AGENTS.md);
this page carries the environment detail behind them.

## Start a session or subtask

Routine editor/task setup uses application/test dependencies and relevant checks;
it does not require all-tool bootstrap, doctor, authentication, or a CLI tour.
Invoke only a specifically needed operator-installed tool with
`yarn dx -- <cli> ...` (or `npm run dx -- <cli> ...`); direct CLI invocation
preserves the current checkout. Do not turn isolated-task access limitations
into a blanket login/bootstrap prerequisite.

- Source inspection and planning need **no** dependency install, doctor run or
  graph index.
- Install only application/test dependencies when the checkout's `node_modules`
  is missing or stale: `yarn dx:runtime` (plain `yarn install --immutable` is
  equivalent).
- No authorization is inherited merely because a CLI is installed; never assume
  a session inherits local OAuth sessions or credentials.

## External DX home

Tool state lives under `${MGOS_DX_HOME:-$HOME/.mgos-dx}`, outside the
application checkout and never inside a publishable tree:

- `bin/` (and similar) hold operator-installed CLI binaries — shared per
  machine, never provisioned by DX.
- `worktrees/<name>` holds slot worktrees (see below).
- Credential/OAuth stores, if any, stay outside the checkout and are never
  copied between checkouts, worktrees or machines.

`scripts/dx/env.sh` is the source-only environment entry: it sets
`MGOS_DX_HOME` and the GitNexus embedding defaults (Voyage Code 4, 1024
dimensions, batch 512 / sub-batch 64 / request dimensions `omit`). Source it
from any checkout; it has no dependency on the primary worktree's location.

## On-demand CLI forwarding

`scripts/dx/run.sh` (via `yarn dx -- <cli>`) forwards to an operator-installed
CLI on PATH and refuses everything else. It never downloads, pins, or installs
a tool; `scripts/dx/startup.sh` exists to state that automatic developer-tool
setup is disabled, and `scripts/dx/bootstrap.sh` only *checks* availability
(`--level runtime|cli|full`, `--tool <cli>`, `--with-gitnexus`). A missing tool
fails with exit 127 and an instruction to install it explicitly.

`scripts/dx/gitnexus.sh` forwards to the installed GitNexus CLI and refuses
checkout-local runners or self-installation. The known-good version is recorded
in `scripts/dx/toolchain.json` (informational; DX does not provision it).

## Worktree slots

One writer per checkout. On shared hosts (sh2), a slot is a dedicated
`git worktree` under `${MGOS_DX_HOME:-$HOME/.mgos-dx}/worktrees/<name>` on
branch `task/<name>`, so no agent ever runs `git checkout`/`git switch` in a
checkout another agent is using:

```bash
scripts/dx/slot.sh claim <name> [--ref <ref>] [--owner <label>]
scripts/dx/slot.sh release <name> [--force]
scripts/dx/slot.sh list
scripts/dx/slot.sh status
```

- `claim` resolves the development branch (`origin/main`, then `main`) unless
  `--ref` names one; it refuses a slot name or `task/<name>` branch that already
  exists so committed work is never reset. Slot metadata is written **beside**
  the slot (`<name>.slot`), never inside it, so the checkout stays clean.
- `release` refuses uncommitted work without `--force`, and keeps the
  `task/<name>` branch either way so committed work survives for merge.
- `list` shows only slot worktrees; `status` labels a shared checkout as
  off-limits for branch switching.

Note: on a Windows host where `bash` is WSL, `git status` over `/mnt/c` on the
full monorepo can take minutes (9p I/O); prefer Git Bash on Windows or run the
slot commands on sh2. `yarn dx:test` handles WSL path/env quirks itself.

On the operator PC the same isolation is plain git: one worktree per agent
(`git worktree add ..\mgos-Agent-A -b agent/a/<task> origin/main`), never a
branch switch in the shared clone. Never clean up another agent's worktree.

## Runtime dependencies per worktree

`scripts/dx/runtime.sh` installs **application dependencies only** — no
developer CLI installation, auth, database or sync. It fingerprints the
dependency-relevant parts of `package.json` plus `yarn.lock` and the toolchain
versions into `node_modules/.mgos-runtime-lock`, runs
`yarn install --immutable` only when that stamp is missing or stale, and
serializes writers per checkout. `--check` reports staleness without changing
anything. `node_modules` is per-worktree and is never shared between worktrees.

## Regression proof

`yarn dx:test` runs `scripts/dx/slot.test.mjs` against a disposable temp repo:
a claim creates an isolated worktree on its own branch; two slots cannot see
each other's edits or branches; the shared checkout stays clean and on its
branch; a dirty slot cannot be released without `--force`; a slot name that
would break a path or branch is refused. Run it after touching anything under
`scripts/dx/`.

## What DX never does

- Provision tools, credentials, or OAuth state.
- Migrate the database, activate workers/services, or deploy anything.
- Share `node_modules`, indexes or credential stores between worktrees.
- Rewrite PATH, lockfiles, or another worktree's state to make a check pass.

Missing tools, absent indexes and unmeasurable state are reported as missing or
Unknown — never synthesized as success.
