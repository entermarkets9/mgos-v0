# MGOS alongside MGRE — phased deployment plan (v2, revision 4)

**Branch:** `v2` · **Prepared:** 2026-10-10 · **Revision:** 4 (single-deployment topology) · **Status:** plan only. Revision 2 resolved all 42 external-review findings; revision 3 closed residual specification gaps and committed durable review evidence; **revision 4 adopts the platform-recommended hosting topology**: one Replit published deployment, two custom domains, an internal hostname-routing gateway. See Appendix A and the revision history.

**Review evidence:** The 42-finding review and its summary are committed at `docs/review/crm-port-plan-review.csv` and `docs/review/crm-port-review-summary.csv`. A later re-delivery of the same review (via `.orca/drops/`, 2026-10-10 evening) was verified byte-identical by SHA-256 (`64735A33…` findings, `97121C67…` summary) and required no new findings.

**Canonical document:** This file (`docs/mgos-deployment-plan.md` on branch `v2`) is the single tracked plan. It supersedes `docs/crm-port-project-plan.md` (the historical reconstruction) for implementation purposes; that file remains as an evidence baseline and is not the execution plan. `crm-env.md` (committed) is the environment handoff; `docs/evid.md` (untracked local copy) is not canonical.

## 0. Objective and architecture

Run the user-owned Twenty CRM source, fully rebranded as **MGOS**, beside the existing
maingate.ae website (**MGRE** — Next.js 16 + Payload CMS 3.88) with this division of labour:

| Surface | Audience | Stack | Host |
| --- | --- | --- | --- |
| `maingate.ae` + `/admin` | Public site + marketing/content team | Next.js + Payload CMS (MGRE) | Internal process, port 5000, **one shared deployment** |
| `crm.maingate.ae` | Real-estate agents (brokers) | MGOS frontend + API | Internal process, port 3001, **same deployment** |
| MGOS worker | Background jobs (queues) | MGOS queue worker | Vultr VM (fresh identity, see §5.2) |

The commercial moat: `/admin` (Payload, marketing) and `crm.maingate.ae` (MGOS, agents)
coexist on shared infrastructure with one Postgres database, isolated by schema ownership
and **distinct least-privilege roles** — not by search_path alone.

### Hosting topology (platform-recommended, revision 4)

Replit's platform constraints, confirmed 2026-10-10, determine how "side by side" is
achievable when published:

| Environment | Constraint | Consequence for this plan |
| --- | --- | --- |
| Development | A single Repl can run multiple processes with independent dependencies and ports in one Nix environment (task #47 ran the website on 5000, MGOS API on 3001/3003 with a separate Node 24 binary). | Local side-by-side (Phase 3) uses this: four processes, distinct ports, one workspace. |
| Autoscale / Reserved VM publishing | **One exposed public port per deployment.** Multiple exposed dev ports do not publish. Replit supports **multiple custom domains attached to one published app**; all domains route to the same deployment. | Published separation inside one deployment requires an internal gateway that selects the target process by request **hostname**. |

**Chosen topology (revision 4):** one Repl, one published Autoscale deployment, two
custom domains, an internal hostname-routing gateway:

```text
Same Repl / published deployment
    │
    └── One public gateway (the single exposed port), routes by hostname
         ├── maingate.ae        → Next.js (port 5000)
         │    └── /admin       → Payload
         └── crm.maingate.ae    → MGOS frontend + API (port 3001)
```

Both apps remain **separate internal processes with independent dependencies**, packaged
into one coordinated release. The gateway is the only process that receives public
traffic; it forwards by `Host` header to loopback. Each custom domain keeps its own
origin, cookie scope and auth callbacks — cookies are scoped to the individual host,
never to `.maingate.ae`.

**Why not two separate deployments (previous revision):** two Autoscale deployments would
work but double the release surface, duplicate database/Redis client configuration, and
split autoscaling decisions that should be joint. One deployment with hostname routing
is the platform's recommended pattern and keeps both apps in one coordinated release.

**Why not `/crm` path prefix:** explicitly **out of scope for v2**. Task #47 did not
establish prefix routing; forwarding is only the first step, because CRM asset URLs, API
base paths, redirects, auth callbacks and realtime endpoints would all need prefix-aware
configuration that has never been built or tested here. The retained experiment README's
own guidance applies: *"Do not assume path support."* Hostname routing sidesteps every
one of those prefix problems because each app believes it owns its entire origin.
Revisit prefix routing only as a separately scoped project.

**Honest status:** task #47 proved separate builds/processes/ports in one Repl
(development). It did **not** verify this exact *published* configuration (gateway +
two domains + one Autoscale deployment). That proof is the explicit job of Phase 5
staging (D-TOPO-01); production cutover in Phase 8 does not proceed without it.

**Database coexistence is independent of this routing choice:** MGOS and MGRE share **one
physical Postgres database** with schema-level ownership (`core`/workspace vs
`public`/`stripe`) and distinct roles, whether the HTTP entry points are one deployment
with two hostnames or two deployments. See the database isolation model below.

**Shared-deployment failure model (new in revision 4):** one deployment means one
release unit. A bad MGOS build can take down `maingate.ae` and vice versa. Mitigations:
the gateway must fail-open per hostname (if one backend is down, the other domain keeps
serving); health checks must cover **both** backends and fail the release only when both
are unhealthy or the gateway itself is; rollback restores the previous release of **both**
apps together; and the Phase 7 safety suite must include a kill-one-backend test proving
the other domain survives. Database saturation and lock interference remain bounded-
shared-resource risks on top of this (CRM-033).

### Gateway specification (new in revision 4 — required before any published routing)

The gateway is the single public entry of the deployment and a new production
component for the website. It must be specified before Phase 5.

| Element | Requirement |
| --- | --- |
| Implementation | A minimal reverse proxy (e.g. a small Node `http-proxy`/`undici` service, or Caddy/nginx as a supervised process) listening on the Replit-assigned public port. No business logic in the gateway. |
| Routing | By `Host` header only: `maingate.ae`/`www.maingate.ae` → `127.0.0.1:5000`; `crm.maingate.ae` → `127.0.0.1:3001`. Unknown hosts → 421/404, never a default backend. |
| Fail-open per hostname | If one backend is unreachable, the gateway returns 502/503 **for that hostname only**; the other domain keeps serving. The gateway itself must never crash because a backend is down. |
| WebSocket / realtime | Upgrade and streaming passthrough verified for both backends (MGOS realtime subscriptions; long-lived responses must not be buffered). |
| Headers | Preserve `Host` (or set the backend-visible host correctly), forward `X-Forwarded-Proto`/`X-Forwarded-For`; strip hop-by-hop headers; do not leak internal ports in responses. |
| Timeouts | Proxy connect/read timeouts tuned above the backends' own idle timeouts; configurable without a gateway rebuild. |
| Health | Gateway exposes an aggregate health endpoint for the platform; per-backend health probes at `/healthz` on each internal port. Platform release health fails only if the **gateway** is down or **both** backends are down. |
| Logs | Per-request hostname + status + latency to stdout/journald; no bodies, no cookies, no Authorization headers. |
| Config | Backend host/port pairs in one environment-driven config, not hardcoded; staging and production differ only in that config. |
| Rollback | The gateway ships inside the coordinated release; releasing the previous artifact restores gateway + both apps together. |

**Website-serving-path change (new risk, revision 4):** `maingate.ae` currently serves
straight from the existing MGRE Autoscale deployment. Under this topology, production
cutover **repoints the website's custom domain** through the new gateway — the website's
production entry path changes for the first time. This is no longer covered by any
"no production DNS changes for maingate.ae" assumption; it is now an explicitly gated
cutover action (Phase 8, Session 8.2.1) with the old deployment kept intact as the
rollback target until the new path is verified.

### Confirmed constraints

1. MGRE keeps Replit App Storage for media (`maingate_prod_v2/media`). Untouched.
2. MGRE keeps its Replit-managed Postgres (`DATABASE_URL`, `public` schema, `push: false`,
   committed migrations). MGOS is added to the **same physical database** in production;
   migrations never overlap.
3. **Staging is fresh.** The retired T6 Neon database, its roles, and the prior worker
   account are not reused. Every staging resource is newly provisioned under fresh
   approval with unique schema/role/Redis/storage scope and a scoped cleanup plan.
   Retirement guards are never bypassed. *(CRM-010)*
4. Full rebrand Twenty → MGOS in UI, backend, packages, namespaces. User owns the
   upstream product; **licensing/provenance is a separate gate** (§Phase 1, D-LEGAL-01) —
   ownership does not by itself settle AGPL notice, commercial-module, or MIT-package
   obligations. *(CRM-012)*
5. MGOS ships custom data models plus two integrations: **DataVault** (property inventory
   pull) and **Nabra** (inbound leads). Both have explicit contracts (§Phase 4) and a
   launch policy for deferral (§Phase 8, D-SCOPE-01). *(CRM-026, CRM-029)*
6. After MGOS is published, Payload `/admin` adopts MGOS design tokens (route group
   `app/(payload)` only; marketing pages unaffected). *(CRM-036)*
7. Worker runs on a **verified-current** Vultr VM under a new production service identity;
   the retired experiment account is not reactivated. Reboot and rebuild are separate
   approvals; rebuild is destructive and never routine. *(CRM-034)*
8. Every billable action — combined-deployment provisioning, builds, Redis commands,
   storage traffic, worker uptime, load tests — is gated on an explicit spend cap,
   duration limit, replica ceiling, and quota-alert owner. Unresolved spending gates
   are BLOCKED, not implicit approvals. *(CRM-035)*
9. **Website baseline is currently failing** (development homepage HTTP 500; Turbopack
   Google-font resolution error; App Storage media-verification failure on last setup
   rerun). These are pre-existing blockers, not caused by this plan. They must be
   resolved or explicitly baselined (recorded as known-failing with owner) before any
   regression comparison can be meaningful. *(CRM-039)*

### Source and runtime pins

| Item | Value | Gate |
| --- | --- | --- |
| Upstream fork | `https://github.com/entermarkets9/twenty` (fork of `twentyhq/twenty`) | D-SOURCE-01 must resolve before clone *(CRM-011)* |
| Approved commit | **Must be an explicitly approved immutable SHA**, not default-branch HEAD. Historical baseline `7e1431c84adbb264db98ab8b8d008a8401b6d4d6` (v2.45.0) is a candidate, not pre-approved. | D-SOURCE-01 |
| MGOS Node | **Exact pinned version** (e.g. `24.19.0`), not a caret range. Builder, API, and worker use the identical binary; verify native ABI matches the worker OS/arch. *(CRM-042)* | Phase 3 |
| MGOS package manager | Yarn `4.13.0` (bundled release). Lockfile regenerated with this exact version, then `--immutable` enforced. *(CRM-016)* | Phase 3 |
| MGRE Node | 20 (`.replit` nix module `nodejs-20`) | Fixed |
| Redis | Upstash TLS (`rediss://`). **Full key isolation**: distinct prefixes for queues, cache, sessions, rate-limits; distinct staging-vs-production prefixes; scoped cleanup permissions; quota budget recorded. *(CRM-020)* | Phase 2 |
| Staging DB | **Fresh** Neon or Replit branch database, newly provisioned, verified empty. Not T6. | Phase 2 |
| Production DB | The website's actual production Postgres, identified by explicit resource identity through the approved secrets flow — not the editor `DATABASE_URL` (which targets development). Read-only connectivity tested from both API host and worker before any write. *(CRM-006)* | Phase 8 |
| CRM attachments | Native Backblaze S3. Exact pinned variable mapping (`STORAGE_S3_*` names, type, bucket, region, endpoint, path-style, transfer model) recorded before deploy; API and worker use identical config; acceptance gate includes authorized upload/read/delete **and cross-broker signed-URL denial tests**. *(CRM-021)* | Phase 4 exit |
| Worker host | Vultr VM, **current ownership/tier/services/SSH trust verified** before adoption. New production service identity, key-based access, scoped sudo. Not the retired `crm-preflight` account. *(CRM-034)* | Phase 5 |

### Database isolation model (the core invariant — revised)

**Distinct least-privilege roles are mandatory. The shared-role fallback is removed.**
If the chosen provider cannot support separate migrator and runtime identities with
enforced negative access, implementation stops and a different topology is brought for
approval. *(CRM-001)*

| Concern | Contract |
| --- | --- |
| Schemas | MGOS owns `core` + workspace schemas. MGRE owns `public` + `stripe`. Neither migrates the other's schemas. |
| Roles | `mgos_migrator` (DDL in `core`/workspace only), `mgos_app` (DML in `core`/workspace only, `search_path=core`), `mgre_app` (existing website role, `search_path=public`). Runtime identities **cannot** migrate. *(CRM-009)* |
| Ownership | Migrations run as `mgos_migrator`; resulting objects are owned by `mgos_migrator`. `ALTER DEFAULT PRIVILEGES IN SCHEMA core FOR ROLE mgos_migrator GRANT ... TO mgos_app` so future objects grant only to the app role. Existing-object grants applied explicitly. Workspace-schema lifecycle (creation, grant, retirement) specified. `SET ROLE` and cleanup privileges verified without widening production access. *(CRM-007)* |
| Bootstrap conflict | Twenty's pinned `scripts/setup-db.ts` creates extensions and `CREATE OR REPLACE FUNCTION public.unaccent_immutable`. This **conflicts** with a zero-DDL-in-`public` invariant. Resolution: inventory every shared helper/extension the bootstrap creates; either (a) approve specific shared objects with documented ownership and website impact, or (b) implement and test an isolated alternative with all dependent references updated. The unmodified bootstrap is **never** run against the website database. *(CRM-002)* |
| Migration execution | Exact named commands for the approved fork, recorded in `docs/mgos/migration-commands.md` once D-SOURCE-01 resolves and before any execution (the command strings cannot be finalized until the fork's actual CLI surface is inspected; naming them earlier would be fabrication). Database-level advisory lock with timeout prevents concurrent publication migrations. Postconditions asserted (expected schemas, object counts, version table). Retry policy defined. Test upgrade boundaries explicit. A zero exit code alone is not success — postconditions must pass. Runtime identities cannot run these commands. *(CRM-009)* |
| Verification | Isolation proven by **full schema-only definitions** (columns, types, defaults, indexes, constraints, triggers, functions, extensions, policies, owners, grants) compared before/after each migration system — not table-name lists. Execution logging and permission-denial tests included. Expected diffs documented for both systems. *(CRM-008)* |
| Connection budget | Calculated worst case, recorded in `docs/db/connection-budget.md`: website pool + MGOS API (replicas × pool) + worker pools + migrator/admin, against the provider's **measured** connection limit (query `SHOW max_connections`; do not assume a provider default), with reserved website headroom (proposed: website keeps ≥40 % of the limit). **Revision 4: one deployment scales both apps together** — replica count is shared, so budget assumes MGRE and MGOS replicas peak simultaneously, not independently. Bounded API replicas configured. Saturation/queueing behaviour tested. The worksheet names every pool, its max, its owner, and the environment it applies to. *(CRM-019)* |

### Rollback and recovery model (new — required before production writes)

A shared physical database means a failed MGOS migration or restore can damage the
website and payment integration. The following must exist and be **rehearsed** before
the first production write. *(CRM-004)*

| Item | Requirement |
| --- | --- |
| Backup | Provider backup/PITR capability confirmed for the production database; backup schedule and retention recorded. |
| RPO/RTO | Explicit Recovery Point and Recovery Time objectives agreed with the owner. |
| Restore rehearsal | A restore into an isolated scratch database is executed and timed at least once before production migration. |
| Scoped rollback | MGOS schema-only rollback (down migrations or schema-restore of `core`/workspace only) defined and tested. A whole-database restore is **never** the rollback path — it would silently revert website data. |
| Version compatibility | Schema-version compatibility window defined: which MGOS versions can run against which database schema states; mixed-version restrictions documented. |
| Coordinated policy | Database-level lock/timeout policy prevents concurrent migration + restore races. |

### Authorization model (new — required before exposing lead records)

Broker-only access is enforced **server-side per record**, not by filtered UI lists.
Standard workspace membership must not expose other brokers' leads through REST,
GraphQL, search, exports, attachments, or related records. *(CRM-005)*

| Decision | Contract |
| --- | --- |
| Workspace topology | **D-AUTH-01**: either one shared workspace with proven per-record field-level permissions, or separate per-broker workspaces with explicit manager aggregation. Chosen before Phase 4. |
| Identity mapping | CRM-user-to-broker mapping defined: website `team_members` (assignedTo) is a staff profile, not a CRM login. A separate mapping table or field links CRM users to broker identities. Reassignment and unassigned-lead handling specified. *(CRM-027)* |
| Negative tests | Cross-broker negative tests across **every** access path: REST list/detail, GraphQL, search, export endpoints, attachment signed-URLs, related-record expansion. Each must deny cross-broker reads. |
| Cookies and origins | **Revision 4:** both hostnames serve from one deployment but remain distinct origins. Cookies are scoped to the individual host (`maingate.ae` or `crm.maingate.ae`), never to `.maingate.ae`. MGOS auth callbacks, CORS allowed-origins and redirect URLs are configured for `https://crm.maingate.ae`; MGRE keeps its existing `maingate-cms` prefix and host scope. No credential or session is shared across the two hostnames. |

### Webhook security contract (new — required before deploying inbound endpoint)

Shared-secret or HMAC alone is not a complete contract. *(CRM-024, CRM-025)*

| Element | Requirement |
| --- | --- |
| Signature | Chosen algorithm (e.g. HMAC-SHA256), raw-body canonicalization specified, timestamp tolerance window, nonce/replay prevention, secret rotation procedure. |
| Transport | Body size limit, content-type allowlist, rate limit, trusted tenant/source mapping, explicit response/status codes. Route verified not to conflict with native MGOS API routing. |
| Delivery | Tenant/source-scoped unique key (not bare externalId). Transactional idempotency or outbox so concurrent retries cannot duplicate leads and a crash between create-and-ack cannot repeat effects. Retryable vs terminal responses distinguished. DLQ access, retention, and redaction defined. Raw unauthorized payloads are not retained by default. *(CRM-025)* |
| Privacy | Minimum retained fields, PII redaction in logs/DLQ, deletion propagation, consent basis, audit access — defined before real leads are received. Production data never enters disposable staging or source-controlled evidence. *(CRM-041)* |

### Inventory connector contract (new — required before connector is "complete")

*(CRM-026)*

| Element | Requirement |
| --- | --- |
| API | Endpoint, schema, version, credentials resolved through the approved integration flow (D-DATAVAULT-01). |
| Sync semantics | Cursor/checkpoint stored transactionally; pagination strategy; rate limits; timeout/retry/backoff; deletion/tombstone handling; stale-status policy; currency/units; edit precedence (broker edits vs upstream overwrite); idempotent overlapping-sync behaviour. |
| Identifiers | Environment/source-qualified external IDs with unique constraints. Buy/rent/off-plan and project-versus-property references resolved with explicit nullable states and status enums. *(CRM-027)* |

---

## Phase 0 — Pre-implementation gates (new)

**Goal:** Resolve every blocking decision and establish safety preconditions before any
source clone, resource provision, or billable action.

### Task 0.1 — Owner assignment

**Session 0.1.1 — Name accountable owners**
- Action: Assign named owners for: source/maintainer, legal/provenance, product,
  database, storage/security, integration, deployment, worker/resource, budget, on-call.
  Recorded in `docs/mgos/owners.md` **before** their first action — not deferred to
  final handoff. *(CRM-040)*
- Action: Define FAIL/BLOCKED as stop states for each owner; a declined gate is not
  silently rescoped.

### Task 0.2 — Source and legal gates

**Session 0.2.1 — Resolve D-SOURCE-01 and D-LEGAL-01**
- Action: Approve the exact immutable commit SHA from `entermarkets9/twenty` as the
  MGOS baseline. Choose the authorized working branch (not direct-to-main). Record
  clean-tree and lockfile hashes. *(CRM-011)*
- Action: Obtain the licensing/provenance decision for the exact commit and every
  module in use: AGPL baseline notices, commercially marked enterprise files, MIT
  packages. Preserve required notices and any source-offer obligations. Approve a
  narrowly defined legal-provenance exception to branding removal where needed.
  Zero-name branding is not the only acceptance check. *(CRM-012)*
- Action: Audit retained experiment tooling (`runtime-config.mjs`, `candidate.mjs`,
  `package-worker.sh`, `build-source.sh`, `prepare-source.sh`) for hardcoded historical
  source paths, package names, runtime binary paths, and staging guards. Parameterize
  against the approved fork. Do not assume changing `pin.json` alone makes them work;
  do not label all experiment tooling production-ready. *(CRM-014)*

### Task 0.3 — Spending and safety preconditions

**Session 0.3.1 — Spend cap, baseline, rollback readiness**
- Action: Set explicit spend limits for: new Autoscale app provisioning, build duration,
  Redis command budget, storage traffic, worker uptime, and each load/soak test. Record
  maximum API replicas, provider quota alerts, and the accountable budget owner. Any
  unresolved spending gate is BLOCKED. *(CRM-035)*
- Action: Resolve or explicitly baseline the existing website failures (HTTP 500 homepage,
  font resolution, media verification) with a named owner. Regression comparison is
  meaningless until the baseline is green or the failures are recorded as known. *(CRM-039)*
- Action: Confirm backup/PITR capability, RPO/RTO, and schedule a restore rehearsal for
  the target production database. No production write proceeds without these. *(CRM-004)*

**Exit gate:** All owners named; D-SOURCE-01, D-LEGAL-01, D-COST-01 resolved; spend
caps recorded; website baseline green or baselined; rollback preconditions confirmed.
No clone, provision, or billable action before this gate.

---

## Phase 1 — Source acquisition, rebrand inventory, MGOS fork

**Goal:** A locally cloned, fully rebranded MGOS source tree with a complete
Twenty-mention inventory (CSVs), a persisted-identifier compatibility map, and an
approved immutable commit.

### Task 1.1 — Clone and pin the fork

**Session 1.1.1 — Acquire source**
- Action: `git clone https://github.com/entermarkets9/twenty` into an **external**
  temp directory (e.g. `/tmp/mgos-source-<commit>`). Authoritative Git metadata stays
  outside the MGRE workspace (Replit checkpointing strips nested `.git`). *(CRM-011)*
- Action: Explicitly checkout the **approved SHA** from D-SOURCE-01 (not HEAD).
  Verify with `git --git-dir=... rev-parse HEAD`. Record commit, lockfile hash,
  Node/Yarn versions in `docs/mgos-source-pin.md`.

**Session 1.1.2 — Twenty-mention inventory (CSVs)**
- Action: Full-text sweep for case-insensitive `twenty` and affiliation strings
  (`twentyhq`, `Twenty`, `TWENTY`, `twenty-`, `/twenty`, `@twenty`).
- Action: Produce three CSVs under `docs/rebrand/`:
  - `twenty-mentions-files.csv` — per file: path, count, type, excerpt.
  - `twenty-mentions-lines.csv` — per match: path, line, column, text, 80-char
    context, proposed MGOS replacement, risk tag (`safe-rename` / `review` /
    `keep-license-notice` / `keep-upstream-ref` / `persisted-identifier`).
  - `twenty-package-names.csv` — every package with `twenty` in the name, current
    name, intended MGOS name, internal/external, published/private.
- Action: License headers, `LICENSE` files, third-party attribution → `keep-license-notice`.
  Upstream git remotes, changelog refs → `keep-upstream-ref`. Queue names, storage
  prefixes, integration keys, SDK references, stored metadata keys → `persisted-identifier`
  (handled by Session 1.1.4, not bulk-renamed). *(CRM-013)*
- Action: Run GitNexus `analyze` on the cloned tree for the symbol-level dependency map
  of the top-20 highest-frequency Twenty-named symbols; save to
  `docs/rebrand/gitnexus-twenty-impact.md`. **GitNexus is an aid, not a required
  dependency**: pin and validate the installed version and command interface first;
  define its coverage limitations; a compiler-aware alternative (exhaustive grep +
  `tsc` + test suite) is the acceptance gate, not the call graph alone. *(CRM-015)*
- Action: Audit CSV outputs for private identities, secrets, or customer data before
  committing. Use synthetic/redacted excerpts, neutral filenames, and a bounded
  provenance allowlist. Large generated outputs stay outside Git with compact tracked
  manifests. *(CRM-037)*

**Session 1.1.3 — Rebrand execution (Twenty → MGOS)**
- Action: Rename workspace-internal packages per `twenty-package-names.csv`. **Regenerate
  the lockfile** with the pinned Yarn version (not manual replacement), then enforce
  `--immutable` installs. *(CRM-016)*
- Action: Rename source directories, file basenames, symbols per `safe-rename` rows.
  Use GitNexus `rename` where validated; scripted bulk rename only for config/docs
  strings. Acceptance is compile + exhaustive-reference check + test suite, not the
  call graph. *(CRM-015)*
- Action: Replace user-visible branding: product name "MGOS", logos, favicons, email
  templates, error pages, meta titles, PWA manifest, OpenGraph strings.
- Action: Re-run the inventory sweep. Target: zero `twenty` matches outside
  `keep-license-notice`, `keep-upstream-ref`, and `persisted-identifier` rows. Commit
  the residual list as the legal-provenance appendix.

**Session 1.1.4 — Persisted-identifier compatibility map (new)**
- Action: Inventory every identifier persisted outside source: queue names/prefixes,
  integration keys, application IDs, stored metadata keys, SDK references, storage
  prefixes. *(CRM-013)*
- Action: For each: define new-install behaviour vs upgrade behaviour, alias/backfill
  plan, mixed-version restrictions, migration order, rollback. Do **not** bulk-replace
  historical IDs or third-party dependency names. The Redis prefix change orphans jobs —
  if the prefix changes, draining/aliasing is mandatory.

**Session 1.1.5 — Fork baseline approval**
- Action: Commit rebranded tree to the authorized branch. Record the new immutable
  commit SHA. Update `pin.json`: status `SOURCE_FORK_APPROVED`, real repository URL,
  exact commit. Runtime/build guards updated to match (Session 0.2.1 audit applied).

**Exit gate:** CSVs + persisted-ID map committed (audited for privacy); GitNexus impact
map saved (or compiler-aware alternative documented); zero unapproved `twenty` matches;
license notices intact; new pin approved; lockfile regenerated and immutable.

---

## Phase 2 — Fresh staging environment and database isolation proof

**Goal:** Prove MGOS migrations and MGRE migrations coexist in one Postgres database
with distinct roles and zero cross-schema DDL — on **fresh** staging, before touching
production.

### Task 2.1 — Fresh staging provisioning

**Session 2.1.1 — Provision staging resources**
- Action: Obtain fresh approval, new staging identities/resources, scoped credentials,
  owner/TTL/cap/cleanup records. Verified target identity and emptiness. Unique
  schema/role/Redis/storage scope. Never bypass retirement guards; never reuse T6,
  its roles, or the prior worker account. *(CRM-010)*
- Action: Provision the staging database (new Neon branch or Replit database branch).
  Create roles: `mgos_migrator` (DDL), `mgos_app` (DML), and confirm the MGRE
  connection uses `public` only. Apply `ALTER DEFAULT PRIVILEGES IN SCHEMA core FOR
  ROLE mgos_migrator ...` and explicit existing-object grants. Record the full
  privilege matrix to `docs/db/isolation-matrix-staging.md`. *(CRM-007)*

**Session 2.1.2 — Bootstrap conflict resolution**
- Action: Inventory every object Twenty's pinned `setup-db.ts` creates outside `core`
  (extensions, `public.unaccent_immutable`, any helpers). For each: approve as a
  documented shared object with website-impact note, or implement an isolated
  alternative with dependent references updated. The unmodified bootstrap is never
  run against a database that contains website tables. *(CRM-002)*
- Action: Run the approved bootstrap/migration once against staging as `mgos_migrator`.
  Verify it creates only `core.*` + workspace schemas + the approved shared objects —
  zero unapproved DDL in `public` or `stripe`.

**Session 2.1.3 — MGRE migration compatibility and interleaving**
- Action: Export MGRE migration state (committed `migrations/index.ts` names) and the
  staging `public` table list. Run `npx payload migrate` against staging in a scratch
  checkout. Verify zero DDL in `core`.
- Action: Interleave: one MGOS migration step, then one MGRE migration step, three
  times. After each, run the **full schema-only definition comparison** (columns,
  types, defaults, indexes, constraints, triggers, functions, extensions, policies,
  owners, grants) for both schemas. Table-name lists are insufficient. Record the
  interleaving log and expected-diff register. *(CRM-008)*
- Action: Verify migration locking: two concurrent migration attempts — the second
  must block/fail on the advisory lock, not run. Postconditions asserted (expected
  schemas, object counts, version rows); a zero exit alone is not success. *(CRM-009)*
- Action: Record the exact initialization and upgrade command strings for the approved
  fork in `docs/mgos/migration-commands.md`, including the lock acquisition, timeout,
  postcondition assertions, and retry policy for each. These commands are the only
  permitted way to run MGOS migrations in any environment after this session. *(CRM-009)*

**Exit gate:** Fresh staging provisioned with distinct roles; bootstrap conflict resolved;
both migration systems coexist with zero unapproved cross-schema DDL (full-definition
proof); interleaving log green; locking and postconditions verified.

---

## Phase 3 — MGOS build and local side-by-side

**Goal:** MGOS frontend, API, and worker build reproducibly and run locally beside MGRE
with correct env contracts, no port collisions, and a defined frontend-serving model.

### Task 3.1 — Reproducible MGOS build

**Session 3.1.1 — Toolchain**
- Action: Provision the **exact pinned** Node binary (same for builder, API, worker).
  Verify native ABI matches the worker target OS/arch. Use bundled Yarn 4.13.0;
  `YARN_ENABLE_GLOBAL_CACHE=false`, `YARN_ENABLE_MIRROR=false`. *(CRM-042)*
- Action: `yarn install --immutable` against the regenerated lockfile. Record lockfile hash.

**Session 3.1.2 — Build artifacts and manifest**
- Action: Build frontend, API, worker. Produce a **complete checksummed manifest**
  (`docs/mgos-artifact-manifest.json`): archive layout, production workspace
  dependencies, generated SDKs, native modules, frontend assets, worker entrypoint,
  exact Node version, target OS/architecture, SHA-256 per artifact. A single
  `dist/main.js` file is not a deployable worker. *(CRM-016)*
- Action: Specify the **frontend-serving contract**: how the built frontend is included
  and served (the pinned `FrontendModule` serves from a server-relative `front/`
  directory — preserve this layout after renaming). Injected client configuration
  (API origin), SPA fallback, cache policy. Tests: root load, deep-link reload, asset
  fetch, API routing on the single published port. *(CRM-017)*

### Task 3.2 — Local side-by-side runtime

**Session 3.2.1 — Env contract**
- Action: Author `mgos.env.example` documenting every variable with its exact pinned
  name: `PG_DATABASE_URL` (staging app-role URL), `REDIS_URL`/`REDIS_QUEUE_URL`/full
  prefix set (queues, cache, sessions, rate-limits), `APP_SECRET` (freshly generated,
  never `PAYLOAD_SECRET`), `SERVER_URL`/`NODE_PORT`, exact `STORAGE_S3_*` mapping
  (type, bucket, region, endpoint, path-style, credentials), `DISABLE_DB_MIGRATIONS=true`,
  feature flags. **Production identity defaults are not synthetic defaults**: signup
  disabled, real email delivery provider (not `EMAIL_DRIVER=logger`), cookie/auth
  transport matching the native mechanism. Synthetic defaults are staging-only and
  labelled as such. *(CRM-021, CRM-022)*
- Action: Never copy MGRE's whole environment into MGOS processes. Document shared-by-
  coincidence vs intentionally-separate variables.

**Session 3.2.2 — Local processes and command side-effects**
- Action: Start MGRE (port 5000), MGOS API, MGOS frontend, MGOS worker. Confirm no
  port collision with MGRE's configured mappings.
- Action: **Document every test/integration command's database and provider side
  effects** in a command contract table (`docs/mgos/command-side-effects.md`).
  Enforce verified synthetic targets with sealed environments. Credential-free unit
  checks stay separate from integration fixtures. Website post-merge seeding and media
  validators are never run as MGOS setup. *(CRM-032)*
- Action: Smoke: MGRE `/` renders (once baseline is green); MGRE `/admin` renders;
  MGOS frontend loads and authenticates; worker picks up a synthetic job. Run MGRE
  `test:enquiry-routing` + `test:routing-migration` against the sealed staging target.

**Exit gate:** Artifacts manifest + frontend-serving contract committed; env contract
documented with production-identity distinctions; command side-effects table committed;
all four processes run locally; MGRE tests green against sealed target.

---

## Phase 4 — Custom data models and integrations

**Goal:** MGOS carries the real-estate domain model and two production integrations with
full authorization, contract, and privacy definitions.

### Task 4.1 — Authorization model and custom data models

**Session 4.1.1 — Authorization topology (blocks data model)**
- Action: Resolve **D-AUTH-01**: shared workspace with proven per-record permissions,
  or per-broker workspaces with manager aggregation. Implement the chosen server-side
  permission model. Define CRM-user-to-broker mapping (separate from website
  `team-members`), role assignment, reassignment, unassigned-lead handling. *(CRM-005)*
- Action: Define MGOS custom objects: Property (DataVault fields + `externalId` with
  environment/source-qualified unique constraint), Listing (buy/rent/off-plan with
  explicit project-vs-property reference resolution and nullable states), Broker,
  Enquiry (mirroring MGRE `leads` shape: fullName, phone, email, propertyType, intent,
  status, assignedTo, sourceKind, listingRef/projectRef, followUpDate). *(CRM-027)*
- Action: Select the **exact supported custom-object mechanism** for the approved fork
  (metadata API vs standard objects vs application objects). Specify workspace
  provisioning, upgrades, metadata-cache invalidation, generated-SDK changes, reversible
  migration behaviour. Do not conflate source-defined standard objects with workspace
  metadata customization. *(CRM-028)*
- Action: Commit the model + authorization spec to `docs/mgos/domain-model.md`.

**Session 4.1.2 — Schema realization**
- Action: Implement custom objects per the chosen mechanism. Generate and run the MGOS
  migration on fresh staging as `mgos_migrator`. Verify full-definition zero-DDL in
  `public`.

### Task 4.2 — DataVault integration (property inventory pull)

**Session 4.2.1 — Connector**
- Action: Resolve **D-DATAVAULT-01**: endpoint, schema, version, credentials through
  the approved integration flow. The connection-layer contract (dedicated read-only
  role, secret names `DATA_VAULT_*`, TLS/CA, separate pool from the application
  database, read-only transactions) is specified in `docs/mgos/datavault-integration-guide.md`;
  follow it for the pool and secrets, then add the connector semantics below on top.
  *(CRM-026)*
- Action: Implement the scheduled pull worker per the inventory connector contract
  (§0): transactional cursor/checkpoint, pagination, rate limits, timeout/retry/backoff,
  tombstones, stale-status policy, edit precedence, idempotent overlap. Key on
  qualified `externalId`.
- Action: DataVault credentials are MGOS-only env vars. Never reuse MGRE's
  `RAPID_API`/`PROP_AI_API_KEY`. API errors: bounded retry + dead-letter; never silently
  delete local records when upstream is unreachable.

**Session 4.2.2 — Inventory read path**
- Action: Expose Property search/list on MGOS API under the authorization model.
- Action: MGRE-side read bridge is out of scope for v2 (logged as future decision).

### Task 4.3 — Nabra leads integration

**Session 4.3.1 — Inbound lead webhook**
- Action: Implement `POST /api/leads/inbound` per the webhook security contract (§0):
  HMAC signature + raw-body canonicalization + timestamp tolerance + nonce/replay +
  secret rotation; body/content-type limits; rate limit; tenant mapping; explicit
  status codes; route verified against native MGOS API routing. *(CRM-024)*
- Action: Transactional idempotency (tenant-scoped unique key, outbox or equivalent)
  so concurrent retries and crash-between-create-and-ack cannot duplicate leads.
  Retryable vs terminal responses. DLQ with access, retention, redaction. No raw
  unauthorized payload retention. *(CRM-025)*
- Action: Define the Nabra payload contract in `docs/mgos/nabra-lead-contract.md`.

**Session 4.3.2 — Agent-facing lead views and privacy**
- Action: Build agent lead list/detail under the authorization model. Cross-broker
  negative tests across REST, GraphQL, search, exports, attachments, related records —
  each must deny cross-broker reads. *(CRM-005)*
- Action: Define data lifecycle: minimum retained fields, PII redaction in logs/DLQ,
  deletion propagation, consent basis, audit access, DLQ expiry, backup retention.
  Production data never enters staging or source-controlled evidence. *(CRM-041)*

**Exit gate:** Authorization model implemented with cross-broker negative tests green;
custom objects migrated (full-definition proof); DataVault connector complete per
contract (or D-DATAVAULT-01 recorded BLOCKED with scope-reduction approval);
Nabra webhook complete per contract; privacy lifecycle defined; storage acceptance
(authorized upload/read/delete + cross-broker signed-URL denial) passed.

---

## Phase 5 — Staging deployment: combined gateway topology (explicitly not production)

**Goal:** The **combined** deployment (gateway + MGRE + MGOS) proven on **staging**
hostnames; worker running on a **verified-current** Vultr VM under a new service
identity. This phase is the missing proof task #47 never ran: one published Autoscale
deployment routing two hostnames to two internal apps. **No production domain, no
production database, no production cutover in this phase.** *(CRM-003, CRM-030, D-TOPO-01)*

### Task 5.0 — Gateway build (blocks everything in this phase)

**Session 5.0.1 — Gateway implementation**
- Action: Implement the gateway per the §0 specification (hostname routing, fail-open
  per hostname, WebSocket passthrough, header handling, timeouts, health, logging,
  env-driven backend config). Unit-test routing table: known host → correct backend;
  unknown host → 421; backend-down → 502 on that host only.
- Action: Package the gateway as the public-port process in the release artifact;
  MGRE and MGOS become supervised internal processes. Update the release/run config
  accordingly (the previous single-app `npm run start` on the public port is replaced
  by the gateway; each app binds loopback only).

### Task 5.1 — Combined staging deployment

**Session 5.1.1 — Staging combined app scaffolding**
- Action: Create a **staging** Replit Autoscale deployment containing gateway + MGRE
  + MGOS. Build step: MGRE build, MGOS build, gateway build; MGOS migrations run once
  via the single migrator (staging DB) **before** runtime start
  (`DISABLE_DB_MIGRATIONS=true` for the API process). Attach **staging hostnames**
  (e.g. `maingate-staging.example` and `crm.maingate-staging.example` or Replit
  preview domains) — never `crm.maingate.ae` or `maingate.ae`. *(CRM-003)*
- Action: Configure allowed origins / CORS for both staging hostnames. Cookies scoped
  to each individual staging host with `Secure`, `SameSite=Lax` — never a parent
  domain. MGRE's `maingate-cms` prefix untouched.
- Action: Verify production-identity settings are **not** the synthetic defaults:
  signup disabled, real or explicitly-staged email provider, cookie/auth transport
  matching the native mechanism. Test on the staging CRM hostname. *(CRM-022)*

**Session 5.1.2 — Gateway acceptance on staging (D-TOPO-01 proof)**
- Action: Verify hostname routing: website staging hostname serves MGRE (`/` and
  `/admin`); CRM staging hostname serves MGOS frontend + API; unknown host rejected.
- Action: **Kill-one-backend test:** stop the MGOS process — website hostname keeps
  serving; CRM hostname returns 502/503; gateway stays up. Restart MGOS; reverse:
  stop MGRE — CRM hostname keeps serving. This is the shared-deployment fail-open
  proof. *(CRM-033)*
- Action: WebSocket/realtime passthrough verified on both backends; streaming
  responses not buffered; proxy timeouts behave under a slow backend.
- Action: Multi-instance: verify migrations do not run per-instance start; sessions/
  caches work across ≥2 deployment instances (externalized state in Redis); scale-to-
  zero recovery works for **both** hostnames simultaneously (cold start brings
  gateway + both apps healthy). *(CRM-023)*
- Action: Assign **one recurring-job registrar** (not API replicas). Exact native +
  custom registration commands, stable schedule IDs, database-level locks,
  reconciliation/removal policy, reboot-recovery test. *(CRM-018)*
- Action: Record the topology verdict: D-TOPO-01 PASS only if every routing, fail-open,
  WebSocket, multi-instance and cold-start check above is green on staging. FAIL sends
  the plan back to the two-deployment fallback (previously revision-3 topology) with
  a fresh gate review — do not limp into production with a partially working gateway.

### Task 5.2 — Vultr staging worker

**Session 5.2.1 — Worker deployment**
- Action: **Verify current VM ownership, tier, services, and SSH trust** without
  exposing credentials. If the prior host is unusable, provision a new approved VM.
  Do not reactivate the retired experiment account. *(CRM-034)*
- Action: Provision a new production/staging service identity, key-based access,
  scoped sudo. Deploy the worker artifact via checksum-verified transfer. Systemd unit
  with `Restart=on-failure`, journald, protected `worker.env` (0600).
- Action: Configure worker with full Redis prefix isolation (queues, cache, sessions).
  Reboot test: worker resumes. Log retrieval and restart via restricted management
  channel proven. Reboot ≠ rebuild; rebuild/resize are separate destructive approvals.
  *(CRM-034)*

### Task 5.3 — Cross-app boundaries (staging)

**Session 5.3.1 — Auth and communication**
- Action: Inventory any v2 MGRE→MGOS calls (none mandatory). If added: server-to-
  server with service token, never browser-direct with user cookies. No shared
  cookies/sessions between the two hostnames. *(CRM-005, §0 cookie scope)*
- Action: Both staging hostnames serve TLS. Add **database saturation, long-lock, and
  provider-outage recovery tests** — independence is process independence plus bounded
  shared-resource interference, not absolute fault isolation. *(CRM-033)*

**Exit gate:** Combined staging deployment live with gateway routing both staging
hostnames; D-TOPO-01 PASS recorded; kill-one-backend fail-open proven; staging worker
live on verified VM; multi-instance + recurring-job + scale-to-zero tests green;
shared-resource interference tests green; production database and **both** production
domains untouched.

---

## Phase 6 — Design-token unification (Payload `/admin`)

**Goal:** Payload admin UI adopts MGOS design tokens via the supported override
mechanism, scoped to `app/(payload)` only.

### Task 6.1 — Token extraction and mapping

**Session 6.1.1 — Extract and map**
- Action: Extract MGOS design tokens (colors, typography, spacing, radii, shadows)
  from theme source; export as `docs/mgos/design-tokens.json`. Capture computed CSS
  custom properties from a rendered MGOS page if available.
- Action: Map to Payload 3 admin theming via the **supported override mechanism**
  (Payload `admin.css` / CSS custom properties). Use **explicit admin-scoped
  selectors** — global selectors, fonts, or favicon overrides that leak to marketing
  pages are defects. Decide **D-DESIGN-01**: `/admin` logo becomes MGOS or stays
  MainGate (default: stay MainGate).

**Session 6.1.2 — Regression check**
- Action: Screenshot `/admin` before/after with **stable fixtures and tolerances**
  (not exact-pixel equality — timestamps and dynamic content vary). Test dark/light,
  focus states, contrast, rich-text editors, overlays, drawers. Authenticated browser
  verification; do not weaken auth for screenshots. *(CRM-036)*
- Action: Verify public marketing pages (`app/(app)`) unaffected: CSS import scope and
  shared assets inspected; authenticated browser check confirms no leakage.
- Action: Audit committed screenshots for private identities/secrets before committing;
  large outputs outside Git. *(CRM-037)*
- Action: `npx tsc --noEmit` + `npm run build`.

**Exit gate:** `/admin` uses MGOS tokens via supported mechanism, admin-scoped only;
marketing pages unaffected (fixture-based check); accessibility states verified;
build + typecheck green; screenshots audited.

---

## Phase 7 — Safety suite on staging (before any production write)

**Goal:** Full bidirectional regression, multi-instance, load, and soak evidence on
staging. **No production write, DNS change, or cutover until this gate passes.**
*(CRM-030)*

### Task 7.1 — MGRE regression (staging)

**Session 7.1.1 — Existing suites**
- Action: Run and record against the **sealed synthetic staging target** (never
  production credentials): `test:enquiry-routing`, `test:routing-migration`,
  `test:leads-csv`, `test:off-plan`, `test:property-finder`, `npx tsc --noEmit`,
  `npm run build`. All green. *(CRM-032)*

**Session 7.1.2 — Payload/admin smoke**
- Action: Browser check: `/admin` loads, login works, leads list renders, lead detail
  opens. Media upload still hits Replit App Storage.

**Session 7.1.3 — DB non-interference (corrected)**
- Action: **DDL check**: full schema-only definitions for `public` + `stripe` before
  and after a full MGOS migration + one DataVault sync. Diff must be empty for
  MGRE-owned schemas. *(CRM-008)*
- Action: **Data check** (staging only, synthetic tables): for each MGOS-touched
  staging table, compute a deterministic content hash — `md5(string_agg(row_hash, ','
  ORDER BY id))` where `row_hash = md5(row_to_json(t)::text)` — before and after the
  MGOS migration + one DataVault sync; hashes must match. This is executable SQL, not
  a metadata proxy. Production verification (Phase 8) instead tolerates legitimate
  website writes: compare full DDL definitions only (the DDL check above), plus
  targeted row assertions on MGOS-owned tables (existence/count by external ID), and
  never copies private data. `information_schema` row-count/max-time is not a checksum
  and is not used as one. *(CRM-031)*

### Task 7.2 — MGOS safety (staging)

**Session 7.2.1 — MGOS smoke + schema purity**
- Action: MGOS frontend loads, auth works, custom-object CRUD round-trip, queue job
  completes, worker heartbeat present, recurring jobs registered once.
- Action: After MGRE `payload migrate` on staging: full-definition zero new/changed
  objects in `core`/workspace; MGOS API still starts and serves. *(CRM-008)*

### Task 7.3 — Load and soak (approval-gated)

**Session 7.3.1 — Bounded load**
- Action: With explicit spend cap + duration + replica ceiling + quota alerts active
  (Phase 0): 5 concurrent synthetic MGOS users, 100 stable job IDs, 30-minute burst
  on the staging worker. Record RSS, host memory, queue lag, job outcomes, Redis
  command counts, swap status. Acceptance: no OOM, no unexplained restarts, ≥20 %
  peak headroom (measurement method defined), all 100 jobs exactly one durable effect
  (deduplication under forced retries proven). *(CRM-035, CRM-042)*

**Session 7.3.2 — Soak (separately approval-gated)**
- Action: 24-hour idle/active soak with fresh spending/duration approval. Same
  thresholds. Unresolved approval = BLOCKED, not implicit go.

**Exit gate:** Both regression suites green on sealed staging; DDL non-interference
proven (full definitions); kill-one-backend fail-open re-proven on the combined
deployment; load test passes; soak passes or explicitly BLOCKED with reason and
scope-reduction approval. **No production write has occurred.**

---

## Phase 8 — Production provisioning, cutover, acceptance, handoff

**Goal:** First (approval-gated) production database provisioning with rollback ready,
then combined production deployment, gated domain cutover for both hostnames,
acceptance, and operational handoff.
*(CRM-003: this phase — not Phase 5 — is the first production write. Revision 4: this
phase also performs the supervised `maingate.ae` repoint through the gateway.)*

### Task 8.1 — Production database provisioning (first production write)

**Session 8.1.1 — Connection and rollback readiness**
- Action: Record the production database **resource identity** through the approved
  secrets flow (not the editor `DATABASE_URL`). Test **read-only connectivity** from
  both the MGOS API host and the worker. Verify TLS and minimum grants. Explicitly
  distinguish development / staging / production connections. *(CRM-006)*
- Action: Confirm backup/PITR active; RPO/RTO recorded; **restore rehearsal completed**
  (Phase 0 precondition re-verified). Scoped MGOS rollback (schema-only) tested.
  Whole-database restore is not the rollback path. *(CRM-004)*

**Session 8.1.2 — Production isolation and migration**
- Action: On the production DB, run the full isolation matrix check (schemas, roles,
  default privileges, existing-object grants). This is the **first and only** production
  write for MGOS — gated on explicit approval. *(CRM-001)*
- Action: Resolve the bootstrap conflict for production (approved shared objects or
  isolated alternative — Phase 2 decision applied). Run MGOS production migration once
  via `mgos_migrator` under the advisory lock. Assert postconditions. Verify `public`
  + `stripe` full definitions unchanged. *(CRM-002, CRM-008, CRM-009)*
- Action: Verify connection budget against actual provider limit with website headroom
  reserved. Populate `docs/db/connection-budget.md` with every pool (website, MGOS API
  replicas, worker, migrator), its max, its owner, and the measured `max_connections`;
  the sum with headroom must fit before the migration runs, not after. *(CRM-019)*

### Task 8.2 — Production deployment and cutover

**Session 8.2.1 — Production combined deployment and domain cutover**
- Action: Deploy the **combined production release** (gateway + MGRE + MGOS) to a new
  Autoscale deployment. Build-time: MGOS migration already run (Session 8.1.2);
  runtime starts gateway + both apps with `DISABLE_DB_MIGRATIONS=true`. Attach
  `crm.maingate.ae` to the new deployment first and verify CRM-only traffic on the new
  path before touching the website domain. Deploy production worker to the verified VM
  under the production service identity. Full Redis/storage prefixes distinct from
  staging. *(CRM-020)*
- Action: **Website domain cutover (gated, rollbackable):** repoint `maingate.ae`
  (and `www`) custom domain from the existing MGRE deployment to the new combined
  deployment. **Before repointing:** the existing deployment stays intact and healthy
  as the rollback target; a timed rollback procedure (re-point domain back) is written
  down and the rollback rehearsed on staging hostnames. **After repointing:** run the
  full website smoke (`/`, `/admin`, enquiry submission, media render) plus the
  kill-one-backend test on production. If any check fails, execute the domain rollback
  immediately and record a BLOCKED verdict — do not iterate on live traffic.
- Action: Post-deploy smoke on production: MGOS auth, one CRUD, one queue job, worker
  heartbeat, hostname routing for both domains, WebSocket passthrough. MGRE production
  regression (enquiry flow, `/admin`, media).

**Session 8.2.2 — Acceptance register**
- Action: Walk every gate with PASS/FAIL/BLOCKED + environment + date + evidence link:
  fork approved + CSVs + persisted-ID map; licensing notices intact; migration isolation
  (staging + production full-definition proof); MGOS published at `crm.maingate.ae`;
  worker live + load-tested; design tokens applied; both regression suites green;
  DataVault + Nabra functional **or** explicitly deferred under D-SCOPE-01 with
  owner-approved scope reduction and risk acceptance. *(CRM-029)*
- Action: **Launch policy**: a gate marked BLOCKED is a no-go unless the owner
  explicitly rescopes it as optional deferred work with recorded risk acceptance.
  Core MVP gates (authorization, migration isolation, worker stability, MGRE
  non-interference) are never deferrable. *(CRM-029)*

### Task 8.3 — Operational handoff

**Session 8.3.1 — Handoff document**
- Action: Commit `docs/mgos/operations-handoff.md`: owners (all roles from Phase 0,
  current assignments), runbooks (deploy, rollback, worker restart, DB restore, secret
  rotation), cost worksheet (Autoscale usage, Vultr, Upstash, Backblaze) with cap and
  alert thresholds, private resource inventory location (outside Git), data-retention
  and deletion runbook (leads, DLQs, logs, backups). *(CRM-041)*
- Action: Confirm cleanup ownership: worker VM retirement, T3/T4/T5 rotation, staging
  resource teardown. Reboot vs destructive rebuild approvals documented.

**Exit gate:** Acceptance register complete; production isolation + rollback proven;
handoff committed; explicit launch decision recorded. BLOCKED core gates = no-go.

---

## Open decision gates

| ID | Decision | Needed by | Default if unresolved |
| --- | --- | --- | --- |
| D-SOURCE-01 | Approve exact fork URL + immutable commit SHA + authorized branch | Phase 0 | BLOCKED — no clone |
| D-LEGAL-01 | Licensing/provenance decision for exact commit and modules (AGPL, commercial, MIT) | Phase 0 | BLOCKED — no rebrand |
| D-COST-01 | Spend cap, duration, replica ceiling, quota alerts, budget owner | Phase 0 | BLOCKED — no billable action |
| D-DB-01 | **Distinct roles required** (no shared-role fallback). Provider must support migrator + app identities. | Phase 2 | STOP — different topology if unsupported *(CRM-001)* |
| D-AUTH-01 | Shared workspace with per-record permissions vs per-broker workspaces | Phase 4 | BLOCKED — no data model |
| D-DESIGN-01 | `/admin` logo: MGOS or MainGate | Phase 6 | Stay MainGate |
| D-DATAVAULT-01 | DataVault endpoint/schema/credentials via approved flow | Phase 4 | BLOCKED — connector unproven; defer under D-SCOPE-01 |
| D-NABRA-01 | Nabra payload contract + auth scheme finalized | Phase 4 | BLOCKED — webhook stubbed; contract doc is deliverable |
| D-WORKER-01 | Fresh approval for load/soak (spending + duration) | Phase 7 | BLOCKED — no load run |
| D-TOPO-01 | Combined-gateway topology proven on staging (routing, fail-open, WebSocket, multi-instance, cold start) | Phase 5 exit | BLOCKED — no production cutover; fall back to two-deployment topology with fresh gate review *(revision 4)* |
| D-SCOPE-01 | Core MVP vs optional deferred work; every deferral needs owner-approved scope reduction + risk acceptance | Phase 8 | BLOCKED core gates are no-go *(CRM-029)* |

## Explicit non-goals (v2)

- Website-to-CRM lead delivery (MGRE `leads` → MGOS) — future phase.
- SSO between `maingate.ae` and `crm.maingate.ae`.
- Replacing MGRE's Replit App Storage or moving Payload media to Backblaze.
- `/crm` path-prefix routing on a single origin (hostname routing is the chosen
  mechanism; prefix support has never been built or tested here).
- Full broker-portal feature parity with commercial CRMs.
- Deleting or resizing the Vultr VM beyond the approved tier; rebuild is never routine.
- Reusing T6, its roles, or the retired worker account.
- Running the unmodified Twenty bootstrap against the website database.
- *(Revision 4 change: the previous "no production DNS changes for maingate.ae" goal
  is **replaced** by the gated, rollbackable domain cutover in Phase 8 Session 8.2.1 —
  repointing `maingate.ae` through the gateway is required by the single-deployment
  topology and is explicitly supervised, not incidental.)*

---

## Appendix A — Review response matrix (CRM-001 … CRM-042)

| ID | Severity | Resolution in this revision |
| --- | --- | --- |
| CRM-001 | Critical | Shared-role fallback **removed**. D-DB-01 requires distinct `mgos_migrator` + `mgos_app` roles; provider inability = STOP. Negative-access tests required. §0 DB model, Phase 2, Phase 8. |
| CRM-002 | Critical | Bootstrap `public.unaccent_immutable`/extensions conflict inventoried and resolved (approved shared objects or isolated alternative) before any shared-DB migration. Unmodified bootstrap never run on website DB. §0, Phase 2 Session 2.1.2, Phase 8 Session 8.1.2. |
| CRM-003 | Critical | **Phase 5 is staging-only** (staging hostnames, staging DB, no production domain). Production provisioning (first write) moved to Phase 8, before production startup/cutover. Each phase's DB target named. Revision 4: Phase 5 proves the combined gateway topology (D-TOPO-01) on staging hostnames. |
| CRM-004 | Critical | Rollback/recovery model added (§0): PITR, RPO/RTO, restore rehearsal, scoped schema-only rollback, version compatibility, coordinated lock policy — all rehearsed before first production write. Phase 0 precondition, re-verified Phase 8. Revision 4 adds a rehearsed domain-cutover rollback for the `maingate.ae` repoint. |
| CRM-005 | Critical | Authorization model added (§0): D-AUTH-01 workspace topology, CRM-user-to-broker mapping, cross-broker negative tests across REST/GraphQL/search/exports/attachments/related records. Phase 4 Session 4.1.1 + 4.3.2. |
| CRM-006 | High | Production DB resource identity via approved secrets flow; read-only connectivity tested from API host and worker; dev/staging/prod explicitly distinguished. Phase 8 Session 8.1.1. |
| CRM-007 | High | Ownership/grants specified: migration owner, `FOR ROLE` default privileges, existing-object grants, workspace-schema lifecycle, `SET ROLE`/cleanup verification without widening production. §0, Phase 2 Session 2.1.1. |
| CRM-008 | High | Full schema-only definition comparison (columns, indexes, triggers, functions, extensions, policies, owners, grants) replaces table-list checks. Expected diffs documented. Phase 2 Session 2.1.3, Phase 7 Sessions 7.1.3 + 7.2.1, Phase 8 Session 8.1.2. |
| CRM-009 | High | Exact named migration commands, advisory lock with timeout, postconditions (not zero-exit alone), retry policy, runtime identities cannot migrate. Command strings recorded in `docs/mgos/migration-commands.md` after D-SOURCE-01, before any execution. §0, Phase 2 Session 2.1.3, Phase 8 Session 8.1.2. |
| CRM-010 | High | T6/roles/worker account **not reused**. Fresh staging with new approval, verified emptiness, unique scope, cleanup plan. Retirement guards never bypassed. §0 constraint 3, Phase 2 Session 2.1.1. |
| CRM-011 | High | D-SOURCE-01 resolved in Phase 0 before clone; explicit SHA checkout (not HEAD); authorized branch chosen; clean-tree/lockfile hashes recorded; rebranded commit approved before guard update. Phase 0, Phase 1 Sessions 1.1.1 + 1.1.5. |
| CRM-012 | High | D-LEGAL-01 licensing/provenance gate in Phase 0; notices and source-offer obligations preserved; narrowly defined legal exception to branding removal; zero-name branding not the only check. Phase 0 Session 0.2.1, Phase 1 Session 1.1.2. |
| CRM-013 | High | Persisted-identifier compatibility map (Session 1.1.4): queue names, keys, prefixes, SDK refs inventoried; new-install vs upgrade, aliases, mixed-version, rollback defined; no bulk historical-ID replacement. |
| CRM-014 | High | Retained experiment tooling audited and parameterized (Phase 0 Session 0.2.1); hardcoded paths/package names/binary paths fixed; updated contracts tested; not all tooling labelled production-ready. |
| CRM-015 | Medium | GitNexus demoted to validated aid: pin + validate version/interface, define coverage; compiler-aware alternative (grep + tsc + tests) is the acceptance gate. Phase 1 Session 1.1.2. |
| CRM-016 | High | Lockfile regenerated with pinned Yarn (not manual), `--immutable` enforced; complete checksummed manifest (deps, SDKs, native modules, assets, OS/arch). Phase 1 Session 1.1.3, Phase 3 Session 3.1.2. |
| CRM-017 | High | Frontend-serving contract specified: `FrontendModule` `front/` layout preserved, client config injection, SPA fallback, cache policy; root/deep-link/asset/API tests. Phase 3 Session 3.1.2. |
| CRM-018 | High | One recurring-job registrar (not API replicas); exact registration commands, stable schedule IDs, locks, reconciliation, reboot-recovery test. Phase 5 Session 5.1.2. |
| CRM-019 | High | Connection budget with Autoscale replica counts and all pools; worst-case calculation with website headroom (≥40 % of measured `max_connections`); every pool named in `docs/db/connection-budget.md`; saturation tested. §0, Phase 8 Session 8.1.2. |
| CRM-020 | High | Full Redis key isolation: prefixes for queues/cache/sessions/rate-limits; staging-vs-production separation; scoped cleanup; quota budget. §0 pins, Phase 5 Session 5.2.1, Phase 8 Session 8.2.1. |
| CRM-021 | High | Exact `STORAGE_S3_*` variable mapping (type, bucket, region, endpoint, path-style, transfer model); identical API/worker config; acceptance gate includes cross-broker signed-URL denial. §0, Phase 3 Session 3.2.1, Phase 4 exit. |
| CRM-022 | High | Production identity lifecycle: signup disabled, real email provider, invitations/verification/reset, cookie/auth transport matching native mechanism, tested on final origin. Synthetic defaults staging-only and labelled. Phase 3 Session 3.2.1, Phase 5 Session 5.1.1. |
| CRM-023 | High | Multi-instance acceptance: real replicas, scale-to-zero, GraphQL/REST/realtime, cache invalidation, token rotation, uploads across instances, proxy timeouts, graceful shutdown. Phase 5 Sessions 5.1.2 + 5.3.1. |
| CRM-024 | High | Webhook security contract (§0): HMAC + raw-body canonicalization + timestamp tolerance + nonce/replay + secret rotation + body limits + tenant mapping + status codes + native-route conflict check. Phase 4 Session 4.3.1. |
| CRM-025 | High | Atomic lead delivery: tenant-scoped unique key, transactional idempotency/outbox, retryable vs terminal, DLQ access/retention/redaction, no raw unauthorized payload retention. §0, Phase 4 Session 4.3.1. |
| CRM-026 | High | Inventory connector contract (§0): API/schema/version, cursor/checkpoint, pagination, rate limits, tombstones, stale-status, edit precedence, idempotent overlap. Connection layer per `docs/mgos/datavault-integration-guide.md` (dedicated read-only role, `DATA_VAULT_*` secrets, separate pool). Phase 4 Sessions 4.2.1–4.2.2. |
| CRM-027 | High | Domain/external-ID design: qualified unique constraints, broker-vs-CRM-user mapping, project-vs-property resolution, status enums, follow-up fields aligned with `collections/Leads.ts`. Phase 4 Session 4.1.1. |
| CRM-028 | High | Exact supported custom-object mechanism selected for the approved fork; workspace provisioning, upgrades, metadata-cache invalidation, SDK changes, reversible migration. Phase 4 Session 4.1.1. |
| CRM-029 | High | Launch policy: BLOCKED core gates (authorization, isolation, worker stability, MGRE non-interference) are never deferrable; optional deferrals need D-SCOPE-01 owner-approved scope reduction + risk acceptance. §0, Phase 8 Session 8.2.2. |
| CRM-030 | High | Safety suite (Phase 7) runs **before** production write (Phase 8). Phase 5 staging-only and proves D-TOPO-01. Post-deploy smoke is additional, not the primary gate. Domain cutover is itself gated on rollback rehearsal. |
| CRM-031 | High | `information_schema` row-count/max-time removed as a checksum. DDL = full schema definitions; data (staging, synthetic tables) = executable deterministic content hash (`md5` over ordered `row_to_json` per row); production verification = DDL definitions + targeted MGOS-owned row assertions, tolerating legitimate writes. Phase 7 Session 7.1.3. |
| CRM-032 | High | Command side-effects table (`docs/mgos/command-side-effects.md`); sealed synthetic targets enforced; credential-free unit checks separate from integration fixtures; post-merge/media validators never run as MGOS setup. Phase 3 Session 3.2.2, Phase 7 Session 7.1.1. |
| CRM-033 | High | Independence = process independence + bounded shared-resource interference. Revision 4: shared deployment adds per-hostname fail-open in the gateway; kill-one-backend tests on staging (Phase 5) and production (Phase 8); database saturation, long-lock, provider-outage, and recovery tests added. |
| CRM-034 | High | VM verified current (ownership/tier/services/SSH) before adoption; new production service identity, key-based SSH, scoped sudo; reboot ≠ rebuild; rebuild/resize separate destructive approvals; atomic release switch + rotated secrets. Phase 5 Sessions 5.2.1–5.2.2. |
| CRM-035 | High | Explicit spend caps, duration, replica ceilings, quota alerts, budget owner in Phase 0; load/soak gated on D-WORKER-01; unresolved spending = BLOCKED. §0 constraint 8, Phase 0 Session 0.3.1, Phase 7 Session 7.3.1. |
| CRM-036 | Medium | Supported Payload override mechanism + explicit admin-scoped selectors; dark/light/focus/contrast/editors/overlays tested; fixture-based (not exact-pixel) comparison; auth not weakened for screenshots. Phase 6 Sessions 6.1.1–6.1.2. |
| CRM-037 | Medium | CSV/screenshot outputs audited for PII/secrets; synthetic/redacted; neutral filenames; large outputs outside Git with tracked manifests. Phase 1 Session 1.1.2, Phase 6 Session 6.1.2. |
| CRM-038 | Medium | This file is the single tracked canonical plan on `v2`; explicitly supersedes `docs/crm-port-project-plan.md` (retained as evidence baseline). `crm-env.md` is the committed handoff; `docs/evid.md` is not canonical. The 42-finding review itself is committed at `docs/review/crm-port-plan-review.csv` + `docs/review/crm-port-review-summary.csv` so references do not depend on user-local paths or expiring shares. Branch `v2` is the intended implementation branch. |
| CRM-039 | High | Website baseline failures (HTTP 500, font, media) recorded as pre-existing; must be resolved or baselined with owner before regression comparison. Phase 0 Session 0.3.1. |
| CRM-040 | Medium | Owners named in Phase 0 **before** their first action (not deferred to handoff); FAIL/BLOCKED = stop states. Phase 0 Session 0.1.1. |
| CRM-041 | High | Privacy/data lifecycle: retention, redaction, deletion propagation, consent, audit, DLQ expiry, backup retention defined before real leads. Production data never in staging/evidence. §0 webhook contract, Phase 4 Session 4.3.2, Phase 8 Session 8.3.1. |
| CRM-042 | Medium | Exact pinned Node version (not caret); matching builder/API/worker binaries; native ABI verified; headroom measurement, queue-lag thresholds, restart recovery, durable-effect deduplication under forced retries defined. §0 pins, Phase 3 Session 3.1.1, Phase 7 Session 7.3.1. |

---

## Reference index

| Document / path | Role in this plan |
| --- | --- |
| `docs/mgos-deployment-plan.md` (this file, `v2`) | **Canonical implementation plan** |
| `docs/crm-port-project-plan.md` | Historical reconstruction / evidence baseline (superseded for execution) |
| `crm-env.md` (committed) | Environment handoff: credential map (names only), DB catalog, worker contract |
| `experiments/crm-preflight/` | Proven tooling patterns: schema isolation, runtime env, worker install, native S3 |
| `experiments/crm-preflight/staging-db.mjs` | Role/schema pattern reused (extended with `FOR ROLE`, distinct migrator) |
| `experiments/crm-preflight/runtime-config.mjs` | `verifiedPGURL` guard; env defaults (staging-only, not production) |
| `experiments/crm-preflight/pin.json` | Historical pin to replace with approved MGOS commit |
| `.agents/memory/isolated-source-checkouts.md` | External Git metadata + Yarn mirror rules |
| `.agents/memory/vultr-experiment-baseline.md` | Worker sizing, Upstash confirmation, disposable-services consent |
| `.agents/memory/crm-storage-topology.md` | Backblaze for MGOS, App Storage for MGRE, no fallback |
| `.agents/memory/staging-role-ownership.md` | CREATEROLE ≠ object-management; verify ownership before cleanup |
| `.agents/memory/crm-ui-ownership.md` | Source-level rebrand requirement |
| `lib/enquiry-service.ts`, `lib/lead-notifications.ts`, `collections/Leads.ts` | MGRE lead model MGOS Enquiry mirrors |
| `payload.config.ts` | MGRE admin config, storage plugin, `push: false` contract |
| `.replit` | MGRE deployment target, ports, build step |
| `docs/mgos/datavault-integration-guide.md` | DataVault connection contract (read-only role, `DATA_VAULT_*` secrets, TLS) |
| `docs/review/crm-port-plan-review.csv` | 42-finding external review (input to revisions 2–3) |
| `docs/review/crm-port-review-summary.csv` | Review summary (verdict, coverage, evidence hashes) |

## Revision history

| Rev | Date | Change |
| --- | --- | --- |
| 1 | 2026-10-10 | Initial 8-phase plan committed (`5455f86`). |
| 2 | 2026-10-10 | Full rewrite resolving all 42 external-review findings (`2af1068`): Phase 0 gates inserted; Phase 5 made staging-only; first production write moved to Phase 8; shared-role fallback removed; rollback/recovery and authorization models added; Appendix A response matrix added. |
| 3 | 2026-10-10 | Post-review re-audit (`docs/review/` committed as durable evidence): DataVault guide cross-referenced (CRM-026); migration commands and connection budget named as tracked deliverables (`docs/mgos/migration-commands.md`, `docs/db/connection-budget.md`); executable data-check SQL specified (CRM-031); reference index moved from user-local Downloads paths to tracked repo paths (CRM-038); hosting topology section added confirming `crm.maingate.ae` as a separate Autoscale deployment is platform-compatible (one public port per deployment) and `/crm` prefix routing remains out of scope. |
| 4 | 2026-10-10 | Single-deployment topology adopted per Replit platform guidance: one published Autoscale deployment, two custom domains, internal hostname-routing gateway. Gateway specification added (§0); shared-deployment failure model with per-hostname fail-open and kill-one-backend tests; Phase 5 reworked to prove the combined gateway on staging (D-TOPO-01); Phase 8 gains a gated, rollbackable `maingate.ae` domain cutover (previous "no DNS changes" non-goal replaced); cookies scoped per hostname, never `.maingate.ae`; connection budget assumes joint replica peaks; two-deployment topology retained as the documented fallback if D-TOPO-01 fails. |
