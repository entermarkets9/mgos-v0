# CRM pilot continuation — phased project plan

> **Historical pilot phases:** Use [the scoped roadmap](crm-scoped-delivery-plan.md)
> for locked v2 delivery. Its explicit integration deferral and full feature
> acceptance supersede both broader integration assumptions and narrow pilot exclusions.
> Preserve these phases as history, not the current full-delivery schedule.

**Date:** 2026-10-11

**Structure:** 5 phases → 10 tasks → 19 sessions → numbered actions.

**Status:** Proposed, documentation-only; implementation is not started.

**Exit gate:** MGOS CRM works side by side with the existing website and Payload
without conflicts.

This is the structured execution view of
[the canonical continuation handoff](crm-pilot-continuation.md), not a different
roadmap or recovered original. The canonical handoff retains the detailed
evidence inventory, approval register, acceptance matrix and failure rules.
Task/session identifiers below are document labels, not created project tasks.
Sessions are bounded work units, not time or effort estimates.

## Entry gate — required before Phase 1

**BLOCKED:** The requested `origin/v2` baseline, full identity of `a029c73`,
complete pilot handoff and appended checkpoint have not been inspected.
Earlier source retrieval timed out; this formatting session does not resolve it.

| Prerequisite | Required outcome |
| --- | --- |
| Source access and identity | Main agent resolves full `a029c73`, records `origin/v2` movement, identifies the approved fork URL/full SHA and implementation branch, preserving unrelated work. |
| Pilot authority | Read complete `docs/uat/twenty-crm-handoff-replit.md`, especially §8, and `.kilo/plans/crm-integration-plan.md`. These are missing historical paths, not recovered files. |
| Reconciliation | Compare pilot records with the continuation, target state and older reconstruction. Obtain an explicit decision on conflicts; do not silently revive superseded choices. |
| Execution approval | Assign source/product/database/security/storage/operations/deployment/budget owners and obtain approval before their consequential actions. |

The earlier inspected documentation baseline was
`5498272602a72cc70e5e1026761fcae307d2bc2d` on `main`. The checkout used to format
this file is `0adadc8d0945d88d9cb62aa9794f8af4f4ca2d5e`. **Neither is the requested
pilot baseline.** The archived experiment source
`7e1431c84adbb264db98ab8b8d008a8401b6d4d6` is also not the approved current fork.

The eight-second lock timeout across approximately 600 actions, Neon `55P03` and
partial activation, local PostgreSQL 17/port 5434 with 75 core tables, and T4b
`ACCESS_DENIED` on `signUpInNewWorkspace` remain **historical user reports**,
not fresh root-cause or acceptance evidence.

## Phase 1 — Fresh Replit PostgreSQL and official setup

**Depends on:** Entry gate; approved fresh synthetic target and ownership.
**Owner:** Main agent, with database/source owners.
**Deliverable:** Pinned clean candidate, target/role ledger and setup state.
**Exit:** Official initialization recorded without unexplained partial state;
no account creation or acceptance claim.

### Task 1.1 — Establish a safe fresh recovery target

#### Session 1.1.1 — Approve the target and preservation boundary

1. Identify an approved fresh Replit PostgreSQL resource/logical database accessible
   from this same Repl, with synthetic-only scope, owner, cost limit and expiry.
2. Record target identity through approved platform/secrets flows without printing
   connection values. Confirm the fresh scope is attributable and empty.
3. Preserve existing Payload `DATABASE_URL`, configuration, data, media and
   credentials. Never reset or re-provision Payload to obtain a fresh CRM target.
4. Exclude Neon/T6 and the reported local PostgreSQL URL/5434 from CRM delivery.
5. Stop if a safe fresh target is unavailable here; do not create a second Repl or
   substitute another provider.

#### Session 1.1.2 — Establish controlled migration ownership

1. Assign distinct CRM and Payload runtime identities and separately controlled
   migration ownership.
2. Inspect required schema, extension and helper operations against provider
   permissions; approve any shared `public` object explicitly.
3. Define database-level migration exclusion, bounded waits, lock-loss handling
   and serialized ownership by the main agent.
4. Record backup/recovery arrangements before writes. Restore proof for existing
   Payload/live targets remains a prerequisite; disposable rehearsal is Phase 5.
5. Stop on unsupported ownership/privileges; no shared administrator fallback.

### Task 1.2 — Initialize from the approved fork

#### Session 1.2.1 — Inspect the official setup contract

1. Read initialization, upgrade, instance-command and scheduler scripts at the
   approved immutable fork SHA; include caught/swallowed errors.
2. Record exact commands, roles, targets, transaction boundaries, expected state,
   logs and abort behavior. Command strings remain unresolved until source access.
3. Pin exact compatible toolchains and prepare dependencies under approved limits,
   without replacing the website runtime or installing in its dependency tree.
4. Keep API startup separate from setup, migrations and cron registration.

#### Session 1.2.2 — Perform one controlled clean initialization

1. Main agent runs official setup once on the approved fresh target.
2. Record ordinary setup postconditions and migration/action state; a zero exit or
   table count alone is insufficient. This is bookkeeping, not acceptance testing.
3. Stop on partial initialization and retain sanitized evidence.
4. Do not reset, truncate, click Retry, inflate timeouts arbitrarily or overlap
   setup with Payload migrations, signup, cron registration or other mutations.

## Phase 2 — Database, environment and authorization boundaries

**Depends on:** Phase 1; approved isolation/auth contracts.
**Owner:** Main agent; read-only source investigations may run in parallel.
**Deliverable:** Ownership matrix, sealed environment map, auth decision tree and
synthetic shared-target fixture specification.
**Exit:** Supported boundaries defined; no runtime permission tests yet.

### Task 2.1 — Define safe shared-database coexistence

#### Session 2.1.1 — Inventory schemas, ownership and workspace provisioning

1. Inventory tables, indexes, sequences, triggers, policies, functions, extensions,
   owners and grants, including shared helpers required by the verified fork.
2. Restrict CREATE, role membership, SET ROLE, existing grants and default
   privileges FOR ROLE to their approved owners. Search paths are not security.
3. Define dynamic workspace provisioning through a supported bounded privileged
   mechanism; ordinary API roles must not inherit unrestricted migration authority.
4. Document expected full catalog/schema diffs, not only table names.
5. Block delivery if provider restrictions prevent enforced isolation.

#### Session 2.1.2 — Prepare a synthetic shared-target candidate

1. Design both CRM and synthetic Payload fixture state on the same approved fresh
   database, under distinct runtime identities.
2. Preserve the real Payload connection and data; moving or changing its database
   requires a separate decision.
3. Prepare isolated fixture configuration without real storage, notifications or
   customer data; execute fixtures only in Phase 5.
4. Do not use website post-merge, media migration or seeding as CRM setup.
5. Reconcile managed Replit production Publish policy with existing hooks and
   dynamic CRM DDL before any production consideration; no new production DDL
   startup/build hooks or custom production migrator.

### Task 2.2 — Separate environments and map native authorization

#### Session 2.2.1 — Seal application and worker configuration

1. Prepare independent website, CRM API, worker and migrator environment allowlists.
2. Remove CRM reliance on Neon/local target assumptions and inherited website
   secrets, default database URLs or retired experiment inventories.
3. Audit retained helpers against the actual fork; preserve retirement guards.
4. Use approved secret flows and record variable names only, never their values.
5. Specify per-process database pools and all Redis subsystem namespaces.

#### Session 2.2.2 — Prepare the signup diagnostic decision tree

1. Trace native `signUpInNewWorkspace` bootstrap policy and workspace membership.
2. Map token issuer/audience/type/signing, refresh and revocation.
3. Determine actual cookie versus browser-token transport, HTTPS, Host/Origin,
   trusted proxy headers, CSRF and CORS.
4. Specify host-scoped separate website/CRM sessions, no parent-domain cookie,
   shared signing key, SSO or automatic account linkage.
5. Prepare evidence capture for Phase 5; do not create an account or debug live
   signup in this phase.

## Phase 3 — One coordinated release, storage and worker operation

**Depends on:** Phase 2; approved release/storage/worker contracts.
**Owner:** Main agent integrates non-overlapping same-container implementation.
**Deliverable:** Matching release candidate, ingress/process map and deterministic
storage/queue configuration.
**Exit:** Candidate assembled without public cutover or acceptance testing.

### Task 3.1 — Package and route separate applications together

#### Session 3.1.1 — Assemble matching source-built artifacts

1. Package website, CRM frontend/API and matching worker with source/lockfile
   identities, exact Node/package-manager versions and OS/native ABI.
2. Include production dependencies, shared outputs, assets and generated SDKs.
3. Keep dependency directories/toolchains separate in this same Nix container.
4. Produce matching manifests; compilation/packaging is allowed here, but
   validation suites remain in Phase 5.

#### Session 3.1.2 — Prepare one ingress and supervised startup

1. Prepare one coordinated startup/release with separate internal website/Payload
   and CRM processes on private/loopback ports.
2. Route `maingate.ae` to the website, `maingate.ae/admin` to Payload, and
   `crm.maingate.ae` to the CRM at its root.
3. Define host allowlisting, forwarded-header trust, HTTPS origin reconstruction,
   API/asset/deep-link handling, WebSocket/SSE, limits and readiness/shutdown.
4. Return explicit unknown-host/CRM-unavailable errors; never fall back to another
   application's page.
5. Do not use `/crm`, an iframe, separate task Repls, a second Replit app or an
   independent CRM deployment. Contradictory verified records need a decision.

### Task 3.2 — Make attachments and jobs deterministic

#### Session 3.2.1 — Configure private native CRM storage

1. Prepare approved native Backblaze S3 credentials and environment-specific
   bucket/prefix consistently for CRM API and worker.
2. Preserve Payload on Replit App Storage.
3. Specify attachment authorization before signing, expiry, integrity, replacement,
   deletion/version retention, exact CORS origins or server-mediated transfer.
4. Fail explicitly on provider errors; no local, App Storage or bridge fallback.

#### Session 3.2.2 — Prepare workers and recurring-job ownership

1. Package required native workers and assign one recurring-job registrar separate
   from API replica startup.
2. Define stable schedule/job IDs, bounded retries, durable effect deduplication,
   namespace/retention and restart reconciliation.
3. Isolate queues, caches, sessions and rate-limit keys, not only queue prefixes.
4. Record approved worker placement. Agent execution stays in this same container;
   required external worker activation remains separately approval-gated.
5. Do not reactivate, resize, rebuild or delete retired/user-owned infrastructure.

## Phase 4 — Operations, rollback and final-phase preparation

**Depends on:** Phase 3; approvals and measurable acceptance limits.
**Owner:** Main agent and accountable operational owners.
**Deliverable:** Recovery/approval ledger, budgets and final-phase command plan.
**Exit:** Candidate and evidence protocol ready; no smoke, provider or failure tests.

### Task 4.1 — Establish resource limits and safe recovery

#### Session 4.1.1 — Agree budgets and operational owners

1. Assign migration, scheduler, release, incident, backup and retention owners.
2. Agree latency, readiness, recovery, error, CPU/RSS/disk, cost and queue-lag limits.
3. Budget total website/API/workspace/worker/replica/migrator connections against
   actual provider limits and reserve website headroom.
4. Bound builds, replicas, Redis commands, retained logs and backlog.
5. Do not treat historical 2 GB/headroom results as current capacity approval.

#### Session 4.1.2 — Prepare rollback and stop branches

1. Define compatible prior CRM code/config/artifact recovery and persisted identifier
   transitions without reverting website state.
2. Stop on source drift, unknown target, lock loss, unexpected public/Payload DDL,
   partial state, denied privileges, ambiguous mutations or resource-limit breach.
3. Require owner-controlled coordinated restore before whole-database recovery;
   never use whole-DB restore as default CRM rollback.
4. Limit cleanup to approved inventory-owned synthetic DB/schema/role, Redis and
   Backblaze scope; preserve evidence and the user-owned worker.

### Task 4.2 — Prepare the final acceptance evidence

#### Session 4.2.1 — Specify safe commands, fixtures and sign-off

1. Prepare command/side-effect ledger and approved synthetic target/account names;
   no accounts are created yet.
2. Inspect typecheck, build, routing and other existing suites before selection;
   do not invoke the parallel Project workflow or use incidental production secrets.
3. Separate credential-free checks from DB-changing/provider/restart cases.
4. Classify each CRM-001–CRM-042 review finding as applicable, superseded with a
   replacement safeguard, or outside bounded scope with owner acknowledgment.
5. Prepare privacy-safe compact evidence manifests; keep large generated output
   outside Git and never retain tokens, credentials, signed URLs or customer data.
6. Separate same-container acceptance from publication/DNS/production/soak approvals.

## Phase 5 — All tests, signup diagnosis and final acceptance

**Depends on:** Phase 4; approved test targets and all relevant action approvals.
**Owner:** Main agent serializes mutations and integrates evidence-based fixes.
**Deliverable:** C1–C8 verdict and separately approved L1 verdict.
**Exit:** Required gates have fresh observable evidence; FAIL/BLOCKED is not a pass.

**All implementation test suites, smoke/provider probes, signup attempts,
failure injection and recovery rehearsals are confined to this final phase.**
Repairs invalidate affected results and require those cases to run again.

### Task 5.1 — Prove the clean native signup path

#### Session 5.1.1 — Run final checks and the first clean UI signup

1. Verify synthetic identities, sealed environments and approval/resource limits.
2. Run selected static/build validation and authorized synthetic fixture setup.
3. Capture website/Payload baseline before CRM activity. Historical HTTP-500/font
   and missing-media problems remain failures/blockers unless resolved.
4. Attempt one clean browser UI signup with one synthetic account and the official
   native request chain: **no Retry button, concurrent attempt or replay**.
5. Capture sanitized request/status/token metadata, proxy decisions, server errors
   and action/migration state, without credentials.

#### Session 5.1.2 — Diagnose failures and repair only supported defects

1. Classify `ACCESS_DENIED`: native JWT exchange/verification, transport/cookies,
   trusted Host/Origin/proxy configuration, or bootstrap policy/membership.
2. Correct the specific supported cause; do not weaken guards/signature checks,
   seed SQL membership, force admin, enable wildcard CORS or share cookies.
3. Only after authentication succeeds, investigate activation/migration errors,
   actual lock holders/waits, `55P03`, action ledger and transaction boundaries.
4. If evidence identifies an activation idempotency/resumption defect, repair only
   that defect: retain completed actions, commit markers with effects, serialize
   per workspace and separate retryable lock errors from terminal auth rejection.
5. Do not inflate timeouts arbitrarily, swallow failure, duplicate workspaces or
   reset shared Payload. A new clean signup requires a newly approved attributable
   fresh CRM scope; retain the failed scope, rather than Retry ambiguous state.
6. Update artifact/source identities and re-run affected final cases. Controlled
   recovery/replay fixtures follow only after the clean path passes.

### Task 5.2 — Prove coexistence and publish an honest verdict

#### Session 5.2.1 — Execute positive and negative acceptance

1. **C1 — CRM:** Authenticated native UI/API create, view, edit and delete/archive;
   login/logout/renewal/revocation; reject invalid/expired/cross-workspace access.
2. **C2 — Website/Payload:** Public pages/search/routes/enquiries/media and
   authenticated admin/editor/CRUD remain usable during CRM operation and restart.
3. **C3 — Database:** Same-target setup/upgrade/workspace/recovery and full catalog
   diffs; deny cross-app read/write/DDL/role escalation under ordinary identities.
4. **C4 — Routing/sessions:** Correct hosts/deep links/assets/APIs/realtime; deny
   spoofed/unknown hosts, cross-app cookie/JWT/origin confusion and public access
   to internal ports; CRM failure never returns website content.
5. **C5 — Storage/persistence:** Record/metadata/attachment restart persistence;
   upload/read/replace/delete integrity, worker reads, range/stream/signing expiry,
   origin handling, unauthorized denial and provider failure without fallback.
6. **C6 — Workers:** Required native jobs and once-owned schedules; bounded
   retry/restart/backlog recovery without unintended duplicate visible effects.
7. **C7 — Resource/recovery:** Agreed load/latency/resource/provider limits;
   forced CRM failure, lock/saturation effects, graceful restart and scoped
   rollback/restore rehearsal. Shared outages remain shared failure domains.
8. **C8 — Evidence:** Matching release/provenance, approval/review dispositions,
   ownership, recovery and redacted evidence signed off.
9. **L1 — Live domains, only if separately approved:** Verify actual HTTPS
   hostnames, publication, auth/deep-link/realtime, replicas/cold starts and
   production-safe preservation. Local host simulation cannot pass L1.
10. Record environment/date/source/artifact identities, method, observed result,
    evidence location and owner for every gate; all start BLOCKED.

#### Session 5.2.2 — Issue separate verdicts and operational handoff

1. Report C1–C8 same-container coexistence separately from live-domain L1.
2. Stop the corresponding verdict for every required FAIL/BLOCKED gate, including
   unapproved required worker/storage/provider behavior or missing thresholds.
3. Hand over source/release identity, startup, migrations, schedules, permissions,
   storage, monitoring, backups/restore, rollback and outstanding approvals.
4. Do not label local pilot success as live, production-ready, full target-state
   delivery or multi-instance/soak acceptance.
5. Leave unrelated broker features, provider integrations, SSO, website lead sync,
   admin restyling and real-data migration outside scope and unaccepted.

## Cross-phase execution rules

- One coherent implementation, orchestrated by the main agent in this same
  Repl/Nix container; no separate task-Repl execution.
- At most three lightweight read-only investigations; later disjoint file work
  may run in parallel after shared contracts are approved.
- Main agent owns source baseline, shared config/lockfiles/dependencies, secrets,
  database actions, service integration and signup.
- One dependency install/build and one DB-affecting operation at a time.
  Never overlap setup, migrations, signup, fixture mutations or cron registration.
- Handoffs include SHA, owned paths, approved inputs, expected state, side effects,
  privileges, evidence and blockers.
- Missing approvals/source/support stop the affected action, not trigger silent
  substitution or broadened privileges.

## Supporting documents

- [Canonical continuation handoff and G0–G7 approval register](crm-pilot-continuation.md)
- [Target state — wider completion criteria, not delivered scope](crm-target-state.md)
- [Execution register and preserved historical checkpoint](crm-port-execution.md)
- [Historical reconstruction — not the recovered original](crm-port-project-plan.md)
- [42-finding safety review](.csv/crm-port-plan-review.csv)

This file is a planning deliverable only. Preparing and downloading it performs
none of its implementation actions.
