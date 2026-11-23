# 1. Project and product

## Direction

MGOS is a private fork of `twentyhq/twenty` serving as the MGRE/MGOS CRM and
platform shell. The base commit is `4bac2940dcdcbf4bb4c974b628cd5e1b0a2e37e0`
(2026-11-22 upstream `main`); the fork then rebrands every user-visible surface
from Twenty to MGOS and proves that custom surfaces can render inside the
Twenty shell.

The near-term product goal is **nabra on MGOS**: bring nabra-smma's ads and
content-posting features into MGOS, inheriting MGOS's design system, with Zernio
as the provider (**Option B**: MGOS calls Zernio directly, no nabra-smma service
dependency).

## Repository boundary

| Boundary | Owner |
| --- | --- |
| This repository | MGOS application source (fork of Twenty) |
| `nabra-smma` | Separate repo at `/root/work/nabra-smma` on sh2; reference source for the ads/content work, **not modified** |
| `mgos` live stack | sh2 (`192.168.100.181`), operator-owned |
| Deployed topologies | sh5b and other VMs per `docs/plans/mgos-sh5b-runbook.md` |

## Source-visible surfaces

| Surface | Entry |
| --- | --- |
| Sign in / Sign up | `/welcome` |
| Object views (Companies, People, Opportunities, Tasks, Notes, Dashboards) | `/objects/:objectName` |
| Workflows | `/objects/workflows` |
| Campaigns | `/objects/campaigns` |
| Calculator (custom-UI proof) | `/calculator` |
| Settings | `/settings` |
| AI | AI sidebar |

**Planned surfaces (not built, plan only):** `/ads` (analytics, read-only),
`/content` (content calendar, read-only), AI sidebar + MCP tools (the ONLY write
path). See [nabra-on-mgos plans](../plans/nabra-on-mgos/00-INDEX.md).

## Branding

The fork ships its own branding-override pattern: a `--t-accent-*` CSS variable
ramp plus a class toggle and favicon swap, so the monochrome accent is
configuration, not a fork of the design system. See
[`packages/twenty-front/src/mgos-theme.css`](../../packages/twenty-front/src/mgos-theme.css)
and `docs/plans/mgos-rebrand-plan.md`.

## Scope honesty

- **Phase B (16 package renames) was dropped by owner decision.** Package names
  are internal identifiers; renaming buys zero user-facing value and makes every
  upstream merge worse.
- **Never touch:** the 667 migrations, Redis queue names, storage prefixes,
  stored metadata keys, licence headers/`LICENSE` files.
- No ads or content feature code has been written — plan only, as instructed.