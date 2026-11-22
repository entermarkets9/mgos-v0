# Handoff: Twenty CRM Local UAT → Replit Agent

- created: 2026-10-11T11:30:00Z
- branch: v2
- for: Replit agent takeover
- run: Orca run_7a6d1b75cc82 (mayor orchestration)
- related plan: `.kilo/plans/crm-integration-plan.md`
- related docs: `docs/mayor.target.state.md`, `docs/mgos-deployment-plan.md`

## 1. What we were doing

Prove a self-hosted Twenty CRM fork (`vendor/crm`, gitignored, pin in `docs/uat/source-pin.json`) runs end-to-end so Ateeq can log in for UAT, then later build Property/Listing/Enquiry custom objects + dashboard + investment calculator.

**Goal of this phase (UAT-A):** UI signup → workspace created → `activationStatus=ACTIVE` → CRM app loads.

## 2. Environment facts (verified this session)

| Component | Value |
|-----------|--------|
| Machine | Windows (pwsh), Node via nvm4w |
| Local PG | **PostgreSQL 17.10** on `127.0.0.1:5434` (pg_ctl from `C:\Program Files\PostgreSQL\17\bin`) |
| Local PG data | `C:\codespace\mgre-new\generated-artifacts\pgdata-local` |
| Local PG log | `C:\codespace\mgre-new\generated-artifacts\pg-local.log` |
| Twenty API | `vendor/crm/packages/twenty-server` → `dist/main.js` on **:3000** |
| Twenty SPA server | `scripts/serve-twenty-front.mjs` on **:3001** (proxies `/graphql` `/metadata` `/rest` `/healthz` `/client-config` `/info` `/file` `/api` → :3000) |
| Twenty .env | `vendor/crm/packages/twenty-server/.env` — **PG_DATABASE_URL now points at local PG** (see §5) |
| Neon (legacy/website) | Same host `ep-dark-credit-b44mz5l4...` → DBs `neondb` (Next.js, 51 tables) + `twenty_crm` (remote; abandoned for UAT) |
| Website DATABASE_URL | `neondb` on Neon (Remult) — **not** shared with Twenty |

## 3. Root cause of workspace-activation failures (CONFIRMED)

### 3.1 The smoking gun

Twenty server hardcodes, inside the workspace migration runner transaction:

```ts
// packages/twenty-server/src/engine/workspace-manager/workspace-migration/workspace-migration-runner/services/workspace-migration-runner.service.ts (~line 395)
await queryRunner.query(`SET LOCAL lock_timeout = '8s'`);
```

Every workspace init runs **600+ DDL/metadata actions** under that 8s lock timeout.

### 3.2 Failure chain on remote Neon

1. User signs up → `signUpInNewWorkspace` → `workspaceManagerService.init` starts standard-object install.
2. Neon is remote (us-east-2 from this Windows host). Every lock wait pays network RTT (tens of ms).
3. `create:searchFieldMetadata` hits lock timeout → PostgreSQL **`55P03`** (`canceling statement due to lock timeout`).
4. Migration **partially commits** (roles/tableMetadata exist; fieldMetadata incomplete). No `workspace_*` schema is ever created.
5. Frontend times out → UI shows **“Workspace creation failed”** + Retry.
6. Retry / auto re-entry calls **`activateWorkspace`**, which re-runs `synchronizeTwentyStandardApplicationOrThrow`.
7. Validator compares half-written `core.*` metadata against expected model → **`WorkspaceMigrationBuilderException: Multiple validation errors`** (observed on `thread`, `templateAndResolvedUrlHash` fieldMetadata, etc.).
8. Workspace stuck `ONGOING_CREATION` / `PENDING_CREATION` forever.

### 3.3 Why local Postgres was the right experiment

- Local lock RTT ≪ Neon; 8s budget is fine.
- T4b: `run-instance-commands --force --include-slow` on local PG **completed with 75 core tables** — no `55P03`.
- This **confirms** the fork is not “buggy”; the combination of aggressive 8s `lock_timeout` + remote Postgres + concurrent Retry is what breaks UAT.

### 3.4 Secondary issue still open (local path)

After local migrate succeeded, browser signup (`uat5@maingate.test`) hit:

- GraphQL **`ACCESS_DENIED` / `AuthPrincipalRefusedException`** on `signUpInNewWorkspace` (POST `/metadata`).
- Guard is `AuthPrincipalGuard({ userSession: true, apiKey: false, ... })` — boolean `userSession: true` **should** accept `workspaceAgnostic`.
- Likely causes to investigate on Replit:
  - JWT type is `WORKSPACE_AGNOSTIC` after email signup but `request.user` / `tokenType` not populated (cookie not forwarded, wrong proxy path, or JWT_APP_SECRET mismatch after `.env` edits).
  - SPA proxy vs direct `:3000` cookie domain (`localhost:3001` vs `:3000`).
  - `SERVER_URL` / `FRONTEND_URL` in `.env` still pointing at old values after port switches.

T4b worker was mid-investigation (`classify-auth-principal.util.ts`, `auth.resolver.ts` `signUpInNewWorkspace`) when handoff was requested.

## 4. What is running / safe to kill

| Process | How to identify | Notes |
|---------|-----------------|--------|
| Local PG 17 | `postgres.exe -D ...\generated-artifacts\pgdata-local` port **5434** | Start: `pg_ctl -D pgdata-local -l pg-local.log -o "-p 5434" start` |
| Twenty API | `node dist/main.js` (cwd `vendor/crm/packages/twenty-server`) | Logs: `generated-artifacts/twenty-server.out.log` / `.err.log` |
| SPA proxy | `node scripts/serve-twenty-front.mjs` | Port 3001 |
| Orca workers | terminals under run `run_7a6d1b75cc82` | May still be live; stop via Orca if needed |

## 5. `.env` change made for local UAT (MUST restore for Replit/Neon deploy)

In `vendor/crm/packages/twenty-server/.env`, **only** `PG_DATABASE_URL` was changed to:

```
PG_DATABASE_URL=postgresql://postgres@127.0.0.1:5434/twenty_crm?sslmode=disable
```

Original Neon value (from session history — **do not commit secrets**; read from Replit secrets / backup):

```
PG_DATABASE_URL=postgresql://neondb_owner:***@ep-dark-credit-b44mz5l4.c-6.us-east-2.aws.neon.tech/twenty_crm?sslmode=require&channel_binding=require
```

For **Replit**: use Replit Postgres (not Neon) per product decision. Point `PG_DATABASE_URL` at Replit PG. **Do not** leave local Windows `127.0.0.1:5434` in any shared config.

## 6. Commands that worked (copy-paste)

### Reset + provision Twenty on a Postgres URL

```powershell
# From repo root; PG_DATABASE_URL already set in .env
cd vendor\crm\packages\twenty-server
# optional full reset (destructive):
node C:\codespace\mgre-new\scripts\reset-twenty-db.mjs   # only if pointed at disposable DB

# load .env into process then:
node dist\database\scripts\setup-db.js
node dist\command\command.js run-instance-commands --force --include-slow
```

### Start API + SPA + health

```powershell
# API (same shell as env load):
Start-Process node dist/main.js -WorkingDirectory vendor\crm\packages\twenty-server `
  -RedirectStandardOutput C:\codespace\mgre-new\generated-artifacts\twenty-server.out.log `
  -RedirectStandardError  C:\codespace\mgre-new\generated-artifacts\twenty-server.err.log

# SPA:
Start-Process node scripts/serve-twenty-front.mjs -WorkingDirectory C:\codespace\mgre-new

# Health:
Invoke-WebRequest http://localhost:3000/healthz   # expect 200
Invoke-WebRequest http://localhost:3001/          # expect HTML
```

### Local PG status

```powershell
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -p 5434 -U postgres -d twenty_crm -c '\dt core.*'
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -p 5434 -U postgres -d twenty_crm -c "SELECT \"displayName\",\"activationStatus\" FROM core.workspace;"
```

## 7. Orchestration / plan state

- Orca run: `run_7a6d1b75cc82`
- Tasks: T1 (servers) completed; T2/T2b failed (Neon lock + validation); T4 abandoned (TUI stuck); **T4b in progress** (local PG + signup ACCESS_DENIED).
- Plan file: `.kilo/plans/crm-integration-plan.md` — open_gaps still 10; UAT-A1–A4+E1 were previously green on older Neon partial path; **current local UAT not green**.
- GitNexus: reindex if stale before structural work (`node .gitnexus/run.cjs analyze --index-only`).

## 8. Recommended next steps for Replit agent

1. **Restore `PG_DATABASE_URL`** to Replit Postgres. Do not use Neon for Twenty init (lock_timeout root cause).
2. Run official setup (`setup-db` + `run-instance-commands --force --include-slow`) on a **fresh** Replit DB (or schema). Expect it to take several minutes; **do not** open a second concurrent init.
3. Run API + SPA per §6. Healthz first.
4. UI signup **once**. Do not click Retry on “Workspace creation failed” — check `twenty-server.err.log` for `55P03` / validation errors instead.
5. If activation still fails, fix `activateWorkspace` idempotency (skip re-init when lock is fresh / only reclaim stale `ONGOING_CREATION`) — Twenty source is in `vendor/crm` (gitignored; pin in `docs/uat/source-pin.json`).
6. If ACCESS_DENIED on `signUpInNewWorkspace` repeats on Replit: debug JWT cookie path + `SERVER_URL`/`FRONTEND_URL` + proxy; read `auth-principal.guard.ts` and `classify-auth-principal.util.ts`.
7. Only after ACTIVE: proceed to custom objects / dashboard / calculator plan in `.kilo/plans/crm-integration-plan.md`.

## 9. What NOT to do

- Do not point Twenty at the website’s `neondb` / Remult tables.
- Do not run `run-instance-commands` twice concurrently against the same DB.
- Do not treat `vendor/crm` branding diffs (Twenty → Main Gate) as bugfixes — they are cosmetic.
- Do not enable Hindsight; do not assume Composio MCP.
- PROD promote is `workflow_dispatch` only; never push-trigger prod.

## 10. Files touched / useful paths

| Path | Role |
|------|------|
| `vendor/crm/` | Twenty fork (gitignored) |
| `scripts/serve-twenty-front.mjs` | SPA + API proxy |
| `scripts/reset-twenty-db.mjs` | Drop/recreate `twenty_crm` |
| `generated-artifacts/probe-*.mjs` | DB/schema probes |
| `generated-artifacts/twenty-server.{out,err}.log` | API logs |
| `docs/mayor.target.state.md` | Target state + UAT |
| `docs/mgos-deployment-plan.md` | Canonical MGOS plan |
| `.kilo/plans/crm-integration-plan.md` | Master plan + gaps |

---

**Handoff complete.** Replit agent should start at §8 step 1.
