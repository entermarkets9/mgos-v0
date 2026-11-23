# MGOS agent policy

Project: **MGOS** — a private fork of `twentyhq/twenty` (Nx / Yarn 4 monorepo) at
`git@github.com:entermarkets9/mgos.git`. The integration branch is **`main`**
(`origin/HEAD`); land work there via PR. Node `^26.5.1` is mandatory (the
engines gate in `yarn.config.cjs` hard-fails any other major), Yarn 4 runs
through corepack / `.yarnrc.yml` (`yarn install --immutable`).

Environments: **the operator PC** clone at `C:\codespace\mgos` (write code here,
in an agent worktree); **sh2** (`192.168.100.181`, `/srv/mgos/mgos`, front
`:3001`, server `:3020`) is the shared live Linux dev box; **sh5b** and other
VMs run the deployed topologies (`docs/plans/mgos-sh5b-runbook.md`). Worktree,
DX and release rules below apply everywhere.

Code house rules, commands and gotchas are in [CLAUDE.md](./CLAUDE.md) — that
file wins for code style, build/test commands and repo-specific traps. This file
governs how agents work in parallel and how developer tooling is used.

## Parallel agents — session identity and worktrees (mandatory)

Several agents can share this repo — on the operator PC and on sh2. Lost work
has one shape: two writers in one directory, and one of them runs
`git checkout`/`git switch`/`git stash`/`git reset --hard`/`git clean`, or
edits files the other is building.

**Rules. Every agent, every task, no exceptions.**

1. **Claim a letter at session start.** Before touching any working tree, pick
   the lowest free single-letter identity — `Agent-A`, `Agent-B`, `Agent-C`, … —
   and announce it first ("I am Agent-A"). Check taken letters with
   `git worktree list`, sibling `*-Agent-*` directories, `git branch -a | grep -i agent`,
   and `scripts/dx/slot.sh list` on sh2. If the operator assigns a letter, take
   it; never reuse another session's letter while its worktree or branch is
   live. The letter binds to the session: use it as the slot `--owner`, inside
   branch names (`agent/<letter>/<task>` or `task/<name>`), and in commit/PR
   notes so work maps back to an agent.
2. **Work only inside your own worktree.**
   - Operator PC: `git worktree add ..\mgos-Agent-A -b agent/a/<task> origin/main`
     — the sibling directory `mgos-Agent-A` is Agent-A's tree for the session.
   - sh2: `cd /srv/mgos/mgos`, then
     `SLOT="$(scripts/dx/slot.sh claim <task-name> --owner Agent-A)"`;
     `cd "$SLOT"` and work ONLY there. A slot is a real `git worktree` under
     `${MGOS_DX_HOME:-$HOME/.mgos-dx}/worktrees/<task-name>` on branch
     `task/<task-name>`, created from `origin/main`.
   - Two writers never share a working tree, an index, `node_modules`, or a
     branch, so no switch can discard another's uncommitted work.
3. **Never switch branches in a checkout you do not own.** `git checkout`,
   `git switch`, `git stash`, `git reset --hard`, `git clean`, `git rebase`,
   `git pull`, `git worktree remove` are forbidden in `C:\codespace\mgos`, in
   `/srv/mgos/mgos`, and in any other agent's worktree/slot. Treat those
   branches as fixed.
4. **Slots are per task on sh2, per agent on the PC.** One agent working two
   tasks claims two sh2 slots, both owned by its letter. Re-claiming a live
   name, or a name whose `task/<name>` branch already exists, is refused on
   purpose: reuse would reset someone's commits. On the PC the agent's worktree
   hosts its task branches sequentially; commit before switching tasks inside it.
5. **Land work onto `main` by push/merge, never by moving another checkout onto
   your branch.** Commit in your worktree/slot, push the branch, open a PR into
   `main` (or hand it to the orchestrator). Fast-forward a shared checkout only
   when it is clean; otherwise report the dirty paths instead of stashing them.
6. **Never clean up another agent's worktree or slot.** `slot.sh release <name>`
   refuses a dirty slot unless `--force`; `--force` discards that slot's
   uncommitted work and stays with the slot owner or the orchestrator. Releasing
   keeps `task/<name>`, so committed work is still mergeable. The same applies
   on the PC: `git worktree remove`/`--force` on another agent's tree is
   forbidden.
7. **No state smuggling between worktrees.** Never copy `.env`, credentials,
   cookies, or OAuth/session stores between checkouts — a fresh worktree starts
   without them by design (`packages/twenty-server/.env` and
   `packages/twenty-front/.env` are local-only; recreate them, see
   `docs/plans/MGOS-HANDOFF.md` §4). `node_modules` is per-worktree; install
   only what the task needs (`yarn dx:runtime`, or `yarn install --immutable`).
8. **Shared runtime, private ports.** sh2 already runs the live dev stack on
   `3001`/`3020` — only one such stack runs per machine. An agent that needs a
   second stack must use different ports and a different database name, or
   wait; never stop, restart, migrate or reseed the shared stack mid-run.
   Serialize shared-stack use by announcing it in the run notes rather than
   assuming you have it.
9. **Before you touch anything, look:**

   ```bash
   git worktree list            # every agent's tree on this machine
   scripts/dx/slot.sh list      # sh2: who owns which live slot
   scripts/dx/slot.sh status    # current checkout, branch, dirty paths
   ```

   A dirty shared checkout or a live `*-Agent-*` worktree means another agent
   is mid-edit. Do not "clean it to get a build"; claim your own worktree and
   report the dirty paths.
10. **Deploy/activation stays with the operator.** Worktrees, slots and ports
    never authorize a database reset or migration apply (`nx database:reset`,
    upgrade commands, migration runs), a service restart on sh2/sh5b, or a
    deployment. Those stay with the operator and the guarded lifecycle.
11. **Stack phase PRs on top of each other (mandatory).** For sequential
    multi-phase work (e.g. `docs/plans/nabra-on-mgos/PHASE-*`), a phase's
    branch/PR is created from the **previous phase's branch** (its unmerged
    tip), not from `origin/main` — never from an older merged commit. A later
    phase may start before the earlier phase merges; it just builds on that
    branch. Each PR still targets `main` and its base branch is recorded in the
    PR body so the merge order is explicit. Do not rebase a stack mid-flight
    unless the operator asks: rebasing one PR in a stack rewrites every PR
    above it.

**Regression proof for slot tooling:** `yarn dx:test` runs
`scripts/dx/slot.test.mjs`, which proves that a claim creates an isolated worktree
on its own branch, that two slots cannot see each other's edits or branches, that
the shared checkout stays clean and on its branch, and that a dirty slot cannot
be released without `--force`.

## On-demand DX — every checkout and subtask

Source inspection and planning require no dependency installation, doctor run or
index. Install only application/test dependencies when the checkout's
`node_modules` is missing or stale (`yarn dx:runtime` → `yarn install --immutable`
under a per-checkout stamp).
`yarn dx -- <cli>` and `scripts/dx/env.sh` forward to operator-installed CLIs on
PATH — they never provision external copies, pin toolchains by download, rewrite
PATH or override index/auth stores. Read `SKILLS.md` and the repo skills under
`.claude/skills/` before using a tool one of them covers. Never assume a session
inherits local OAuth sessions or credentials.

DX setup never migrates or activates anything. Report database migration and
service/worker activation state as Unknown until an approved lifecycle supplies
evidence. `scripts/dx/startup.sh` exists to make explicit that automatic
developer-tool setup is disabled.

## GitNexus — opt-in, CLI-only, never reindex by default

GitNexus is optional and routine work never requires an index. When the user
explicitly requests GitNexus, use the installed CLI on PATH
(`yarn dx -- gitnexus` / `scripts/dx/gitnexus.sh`) and the current checkout's own
index; never a checkout-local runner or an unpinned package-manager download.
Never run `clean`, `--force` or `--embeddings 0` as routine work — those force a
full reindex, which happens only on an explicit operator command, honoring the
embedding defaults in `scripts/dx/env.sh` (Voyage Code 4, 1024 dimensions).
Keep each worktree's index independent; never share, replace, clean or redirect
another worktree's index. Preserve failed evidence and queue out-of-scope
repairs instead of rebuilding to make a gate pass, and do not present stale
analysis as a freshly verified final review. Report the exact gate when analysis
is blocked.
