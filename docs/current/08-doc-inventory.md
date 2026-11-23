# 8. Documentation inventory and trust

## Maintained roles

| Material | Meaning |
| --- | --- |
| This `docs/current/` tree | Concise current guidance; not chronological release evidence |
| [`docs/plans/`](../plans/) | Handoff, preflight, rebrand, runbook, and nabra-on-mgos plans — including the 21 files moved into the repo on 2026-11-23 |
| [`docs/mgos/`](../mgos/) | Carried-over CRM docs from `mgre-new` (env contracts, source audit, preflight) — historical planning, not current runtime attestation |
| [`docs/uat/`](../uat/) | UAT materials |

## Key plans (read order for ads/content)

1. `docs/plans/MGOS-HANDOFF.md` — full handoff, 396 lines, everything verified live
2. `docs/plans/twenty-custom-ui-preflight.md` — how custom UI actually works
3. `docs/plans/nabra-on-mgos/00-INDEX.md` — ads/content architecture
4. `docs/plans/nabra-on-mgos/PHASE-0-readiness.md` — the 7 blocking decisions

Other maintained plans: `mgos-rebrand-plan.md` (branding phases A/B/C),
`mgos-single-vm-megaplan.md`, `mgos-sh5b-runbook.md` (executable runbook).

## Evidence boundaries

- The handoff's "verified live" claims are true for the state at handoff time
  (`b15ddf17` / later `c7f721d402`), not a standing attestation of every
  subsequent change.
- The nabra-on-mgos plans (2,311 lines) are **plan only** — no feature code
  exists. A plan is not permission to execute it.
- `nabra-smma` at `/root/work/nabra-smma` on sh2 is a reference source; do not
  modify it from this repo's work.
- sh5b runbook describes a topology that is currently stopped (10 volumes
  intact); "stopped" does not mean "cleaned up."

## Intentional exceptions

- Root `AGENTS.md` and `CLAUDE.md` are policy files, not documentation to be
  reorganized.
- `.env` files are local-only by design; documented in
  [operations](04-operations-runbook.md), never committed.
- Upstream Twenty docs and license headers are inherited; do not rewrite them as
  part of MGOS branding work.

## Maintenance rule

When current guidance changes, update its maintained inbound links and source
status. Move the prior snapshot to the matching dated archive path. Do not
flatten unrelated histories or mark unverified old issues resolved.