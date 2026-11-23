# 6. Open work

Do not treat an old finding as fixed because its document moved, or as still
broken merely because a historical ledger says so.

## Fix first: sidebar nav bug

**The Calculator row exists in the database but does not appear in the sidebar
on first load.**

```
SECTION   | Workspace  |         | isActive=t
FOLDER    | Workflows  |         | isActive=t
FOLDER    | Campaigns  |         | isActive=t
LINK      | Calculator | /calculator | isActive=t
```

Direct navigation to `/calculator` works. The nav list does not show it.

Two candidate causes, in order:
1. Client-side nav state cached and hydrated before the row existed.
2. Workspace nav is per-user — `userWorkspaceId` is nullable, and standard items
   may resolve through a user-workspace join our row does not satisfy.

**How to fix:** create the item through the UI's own "Edit navigation" flow and
diff what extra state it writes, rather than inserting by raw SQL.

**Why it matters:** every future custom surface (`/ads`, `/content`, OpenWA
chat, DataVault query) hits the same mechanism. Fix it once, properly.

## Seven blocking decisions (Phase 0) — owner: Mohammed

All BLOCKED pending owner. Nothing in Phases 1–8 starts until the Phase 0 exit
gate passes (every gate PASS or explicitly BLOCKED with a named owner).

| ID | Decision | Default if unresolved |
| --- | --- | --- |
| `D-SCOPE-01` | Confirm `/ads` and `/content` are views only; all mutation via AI | BLOCKED |
| `D-CRED-01` | Zernio team + key + webhook secret **per environment** | BLOCKED |
| `D-RBAC-01` | **What "manager" means** in Twenty's role model | BLOCKED |
| `D-DATA-01` | Mirror Zernio entities into `core` schema, or fetch live | BLOCKED |
| `D-AI-01` | Twenty's built-in AI chat + MCP, or our own route | BLOCKED |
| `D-COST-01` | Spend cap per ad account, and who may raise it | BLOCKED |
| `D-APPR-01` | Approval model: inline confirm, four-eyes, or both | BLOCKED |

Answer these two first, because they unblock the most:

- **`D-RBAC-01`** — read Twenty's `Role` and `RolePermissionFlag` model before
  designing permissions. Ripgrep found `requirePermission("...")` with
  `manage_integrations` confirmed, but **no dedicated `manage_ads` /
  `manage_content`** — ad/content gating may be role-based elsewhere. **Phase
  6's first task is inspection, not implementation.**
- **`D-DATA-01`** — recommendation: mirror campaigns + daily metric snapshots
  (append-only, wants history for trend/anomaly), but fetch account connection
  state live (a revoked token must show immediately).

## Environment traps still live

- `SIGN_IN_PREFILLED=true` prefills a fictional user → welcome page shows
  "Sign up" only for that email. Consider setting `false` or documenting the
  real dev account.
- Node 24 hard-fails install at `yarn.config.cjs:26`; Node 26 lacks corepack
  (use the committed `.yarn/releases/yarn-4.18.1.cjs`).

## Deliberately not done

- No ads or content feature code — plan only.
- No `nabra-smma` files modified.
- No sh5b deployment (still stopped, 10 volumes intact).
- No production Zernio credentials created.
- No Phase B package renames.