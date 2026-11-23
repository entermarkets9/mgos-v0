# 11. Release and runtime state inventory

Source-based inventory of the currently identified deployment state. Not a
clean-host bootstrap procedure or evidence that a release is live. Re-read the
executing revision; older runs may use different formats.

## Known environments

| Environment | State | Notes |
| --- | --- | --- |
| **sh2** (`192.168.100.181`) | Live dev stack | front :3001, server :3020, worker running, Postgres `mgos`, Redis :6379. The primary shared dev box. |
| **sh5b** | Stopped | All 10 volumes intact; runbook at `docs/plans/mgos-sh5b-runbook.md`. Deployment/activation stays with the operator. |
| **Operator PC** (`C:\codespace\mgos`) | Dev checkout | Write code here, in an agent worktree; `.env` files local-only. |
| **Other VMs** | Deployed topologies | Per `docs/plans/mgos-single-vm-megaplan.md` and the sh5b runbook. |

## sh2 runtime identity

| Item | Value |
| --- | --- |
| Workspace | `Mgos` / ACTIVE / id `25e6a7ae-fb63-4033-bc99-5c4bc7a8837d` |
| Workspace schema | `workspace_28s05y2lxh7uzx5y93g6sk3nh` |
| Node | v26.13.1 at `/opt/node-v26.13.1-linux-x64/bin` |
| Yarn | 4.18.1 via committed `.yarn/releases/yarn-4.18.1.cjs` |
| Logs | `/var/log/mgos/dev.log`, `/var/log/mgos/worker.log` |
| Email driver | LOGGER (dev default; emails printed to logs, not sent) |
| Storage | local |

## Verified 2026-11-23

- Front 200, server `/healthz` 200, Redis PONG.
- Worker activated; all BullMQ queues drained to wait=0 / failed=0.
- Email pipeline end-to-end verified via `emailPasswordResetLink` (reset URL
  printed by worker LOGGER driver).
- Sign-in verified with `admin@mgos.local` / `TwentyMgmt!2026` (password reset
  and email-verified flag set on 2026-11-23 because the email is fictional and
  cannot receive verification links).

## Not deployed / not created

- No ads/content feature code (plan only).
- No production Zernio credentials.
- No Phase B package renames.
- sh5b still stopped with all 10 volumes intact.