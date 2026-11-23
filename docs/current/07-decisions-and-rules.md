# 7. Decisions and safety rules

These are constraints, not claims that all enforcement or live configuration has
been reverified. The current user request and [agent policy](../../AGENTS.md)
bound execution. A historical handoff is not standing approval for another task.

## Agent worktree rules (non-negotiable)

- Claim a letter at session start; work only inside your own worktree or sh2
  slot. Never reuse another session's letter while its worktree/branch is live.
- Never switch branches, stash, reset, clean, or rebase in a checkout you do not
  own (`C:\codespace\mgos`, `/srv/mgos/mgos`, any agent's worktree/slot).
- Land work onto `main` by push/merge/PR, never by moving another checkout onto
  your branch.
- Never clean up another agent's worktree or slot.
- No state smuggling between worktrees: `.env`, credentials, cookies, OAuth
  stores stay local; recreate `.env` per checkout.
- Shared runtime, private ports: only one dev stack per machine; never stop,
  restart, migrate, or reseed the shared stack mid-run.

## Operator-owned lifecycle

Database resets/migrations/upgrades, service restarts on sh2/sh5b, and
deployments stay with the operator and the guarded lifecycle. Worktrees, slots,
and ports never authorize them. A dirty shared checkout means another agent is
mid-edit — report it, do not "clean it to get a build."

## Code house rules (CLAUDE.md wins)

- Short-form `//` comments only for WHY, never JSDoc; hard ceiling of five
  lines.
- Types over interfaces; string literals over enums (except GraphQL enums); no
  `any`; named exports; functional components only.
- Use existing guards/helpers (`isDefined`, `isNonEmptyString`, …) before
  writing your own; reimplementing an existing util is the most common
  AI-authored defect here.
- Lingui for user-facing strings, `doNotTranslate()` for protocol tokens;
  Linaria for twenty-front styling.
- Icons from `twenty-ui/icon`, never `@tabler/icons-react` directly.
- Test behavior, not implementation; query by user-visible text/roles.

## Fork-specific safety

- **Never touch:** the 667 migrations, Redis queue names, storage prefixes,
  stored metadata keys, licence headers/`LICENSE` files.
- **Phase B package renames are dropped by owner decision** — internal
  identifiers, zero user-facing value, worse upstream merges.
- Do not commit translation catalogs unless translations are the task (`lingui
  extract/compile` churn stays out of commits).
- Commit messages must not carry AI attribution (CI rejects `@anthropic.com`
  co-author trailers or "Generated with Claude Code" lines).
- Upgrade commands: add/edit only under the current `TWENTY_CURRENT_VERSION`
  directory with a real epoch-ms timestamp greater than every existing one; never
  rewrite committed command logic; runtime code never branches on migration
  state.
- Entity file changes need a generated instance command
  (`database:migrate:generate`).

## Product safeguards (nabra on MGOS)

- The read/write split is the safety design: `/ads` and `/content` are views
  only; all mutation happens through the AI sidebar with a manager role +
  confirmation step. A mis-click in a calendar cannot spend money.
- MGOS must **degrade** a misconfigured Zernio integration (blank ads page), not
  refuse to boot like nabra-smma's exclusive `zernio` mode.
- Real ad spend is an irreversible external action — dry-run/sandbox per
  platform (Meta, Google, TikTok all differ), spend caps, idempotency keys for
  webhooks, and destination shown in any confirmation.
- Cross-tenant ad account leakage is a data breach, not a bug.
- No production Zernio credentials until `D-CRED-01` is answered and per
  environment.

## Verification proportion

- Distinguish source, isolated regression, authenticated UI, runtime, provider,
  and release evidence. A healthy port does not prove the intended
  process/configuration is serving it.
- Report exact gate when analysis is blocked; preserve failed evidence and queue
  out-of-scope repairs instead of rebuilding to make a gate pass.
- GitNexus is opt-in, CLI-only, never reindex by default; keep each worktree's
  index independent.