# 3. Current status

Compact evidence summary, not an append-only work log. Every fact below was
verified on the live system, not recalled.

## Repository

| Item | Value |
| --- | --- |
| Repo | `git@github.com:entermarkets9/mgos.git` (private) |
| Base commit | `4bac2940dcdcbf4bb4c974b628cd5e1b0a2e37e0` (2026-11-22 upstream `main`) |
| HEAD | `c7f721d402` = `origin/main` |
| Working tree | clean (operator PC `C:\codespace\mgos`) |

## Live dev environment (sh2 `192.168.100.181`)

| Item | Value |
| --- | --- |
| Frontend | `http://192.168.100.181:3001` → 200 |
| Server | `:3020/healthz` → 200 |
| Node | v26.13.1 (`/opt/node-v26.13.1-linux-x64/bin`) |
| Postgres | `mgos` db, role `mgos`, 127.0.0.1:5432 |
| Redis | 127.0.0.1:6379, PONG |
| Workspace | `Mgos` / ACTIVE / id `25e6a7ae-fb63-4033-bc99-5c4bc7a8837d` / schema `workspace_28s05y2lxh7uzx5y93g6sk3nh` |
| Log | `/var/log/mgos/dev.log` (server+front), `/var/log/mgos/worker.log` (worker) |

## Worker (activated 2026-11-23)

The dev stack runs front + server + **worker** when started with the root
`yarn start`. A prior start via `nx run-many -t start -p twenty-server
twenty-front` skipped the worker; queues backed up. The worker is now running
(`queue-worker` entry) and drained the backlog:

- 43 jobs processed at activation (webhook, workspace, entity-events, calendar, email)
- All BullMQ queues now at wait=0 / failed=0
- Email pipeline verified end-to-end: `emailPasswordResetLink` mutation →
  server enqueues → worker processes → LOGGER driver prints reset URL
  (`http://192.168.100.181:3001/reset-password/<token>`) — email-queue 1
  completed, 0 failed.

## Data

| Table | Count |
| --- | --- |
| `core.workspace` | 1 (`Mgos`) |
| `core.user` | 1 (`admin@mgos.local`, email verified, password reset 2026-11-23 to `TwentyMgmt!2026`) |
| `core."navigationMenuItem"` | 14 (Workspace folder, Workflows, Campaigns, Calculator, …) |
| `workspace_.../company` | 5 |
| `workspace_.../person` | 5 |
| `workspace_.../opportunity` | 6 |

## Open bug (sidebar nav)

The `Calculator` row exists in `core."navigationMenuItem"` with `isActive=t` but
does **not** render in the sidebar on first load. Direct navigation to
`/calculator` works. Candidate causes: client-side nav cache hydration before
the row existed, or a per-user `userWorkspaceId` join the row does not satisfy.
Fix via the UI's "Edit navigation" flow and diff the extra state it writes.
This blocks every future custom surface (`/ads`, `/content`, OpenWA, DataVault).

## Sign-in trap (resolved for admin)

`SIGN_IN_PREFILLED=true` prefills `tim@apple.dev`, which does not exist, so the
auto-detected mode shows "Sign up" only. Existing users (e.g.
`admin@mgos.local`) correctly show "Sign in". Login works:

```
email:    admin@mgos.local
password: TwentyMgmt!2026
```

## Not done

- No ads/content feature code — plan only.
- `nabra-smma` untouched.
- sh5b still stopped with all 10 volumes intact.
- No Phase B package renames.