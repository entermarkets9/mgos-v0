# MGOS on a single VM — megaplan (sh5b, 2026-11-22)

**Supersedes:** `docs/mgos-deployment-plan.md` rev 4 (Replit, one Autoscale deployment, two
domains, internal gateway). That plan's Replit platform constraints no longer apply.
**New target:** everything on **one VM** — `sh5b` (Vultr, `140.82.44.184` / Tailscale
`100.74.209.88`), serving MGRE + MGOS + worker + Postgres + Redis + object storage.
**Status:** plan. No code edits yet, per instructions.

---

## 0. What changed vs the old plan, and why

| Concern | Old (rev 4, Replit) | New (single VM) |
| --- | --- | --- |
| Hosting | One Autoscale deployment, one public port | One VM, one Caddy, N internal ports |
| Routing | Custom Node gateway, hostname routing, because Replit exposes one port | **Caddy** does hostname routing natively. Gateway spec from rev 4 is obsolete. |
| Scale | Replicas, scale-to-zero, multi-instance acceptance | **Single instance.** No replicas, no cold start. Cost: no HA. |
| Database | One shared Postgres, `core` vs `public` schema split, distinct roles | **Unchanged and still mandatory.** Same invariant applies. |
| Worker | Separate Vultr VM | Same VM, systemd unit. Removes CRM-034 VM adoption entirely. |
| Memory | Autoscale-provided | **Hard 1.9 GiB.** This is the binding constraint of the entire plan. |
| Domain | `crm.maingate.ae` + `maingate.ae` | `forbrokers.maingate.ae` live today; `maingate.ae` optional later |

**Kept from rev 4 because they were right:** the 42-finding response matrix (CRM-001…042)
still governs quality. Specifically: distinct least-privilege DB roles (CRM-001), bootstrap
conflict resolution (CRM-002), full schema-definition verification (CRM-008), advisory-locked
migrations with postconditions (CRM-009), signup disabled in production (CRM-022), staged
rollback before production writes (CRM-004), and privacy/data-lifecycle (CRM-041).

**Dropped from rev 4:** gateway build (Phase 5 Task 5.0), D-TOPO-01 gateway proof,
Replit Autoscale specifics, multi-instance/scale-to-zero tests, and the Vultr worker
adoption task. Caddy replaces the gateway; one VM removes cross-host work.

---

## 1. Measured baseline (evidence, 2026-11-22 18:47 GMT+4)

| Fact | Value | Source |
| --- | --- | --- |
| vCPU | 2 | `nproc` |
| RAM | 1.9 GiB total | `free -h` |
| Swap | 8.0 GiB (was 1.8 GiB used by the old stack) | `free -h` |
| Disk | 61 G total, 44 G used, **14 G available, 77 %** | `df -h /` |
| OS | Ubuntu 24.04.5, kernel 6.8 | `hostnamectl` |
| Hostname | `SH7B` static, but Tailscale identity is **SH5B** — stale script | `hostnamectl` vs `tailscale status` |
| Docker volumes retained | 10 volumes, **8.3 G** | `du -sh /var/lib/docker/volumes` |
| Caddy | v2.11.4 active, imports `/etc/caddy/sites/*.caddy` | `caddy version` |
| Caddy sites | `openfix.caddy`, `privacy.caddy`, `twenty.caddy` | `ls /etc/caddy/sites` |
| Twenty image | `twentycrm/twenty:latest`, server healthy before stop | `docker inspect` |
| Twenty workspace | `Mgre` / subdomain `mgre` / `workspace_1tcut9ckno5ni7ex9k91s1uq8` | `core.workspace` |

### 1.1 Takeover performed (reversible)

All application workloads **stopped, not deleted**:

- Containers stopped: `twenty-{server,worker,db,redis}-1`, `nabra-{redis,postgres}`,
  `openfix-{api,inngest,inngest-postgres,inngest-redis,mongodb}-1`
- `nabra-smma.service` stopped
- All 10 volumes retained (8.3 G). Nothing removed.
- Tailscale untouched and online: host `SH5B` reported by its own daemon.
- Ports still bound: 22, 80, 443 (Caddy), 2019 (Caddy admin), Tailscale.
- RAM freed: 1.2 GiB available, swap dropped from 1.8 GiB to 170 MiB.

**Reversal is one command per stack:** `cd /opt/twenty && docker compose start`, same for
`/opt/openfix` and `/opt/nabra-smma`, plus `systemctl start nabra-smma`. Recorded here so
this is not a one-way door.

### 1.2 The number that decides the plan

**14 G of disk and 1.9 GiB of RAM.** Twenty alone, minimal, needs ~1.4 GiB RSS for
server+worker+db+redis. That leaves ~400 MiB for MGRE (Next.js + Payload), Caddy, and the
OS. It does **not** fit comfortably. MGRE and MGOS therefore must not both be resident at
full size, and building Twenty from source on this box (which needs ~8–10 G of disk and
2–4 GiB for a cold `yarn install` + build) is **not viable inline**.

---

## 2. The three discoveries that reshape the work

### 2.1 The shipped image has no frontend source

```
/app/packages/ = twenty-client-sdk, twenty-emails, twenty-server, twenty-shared
/app/packages/twenty-front/src → does not exist
```

Consequence: **"full fork + custom UI" cannot be done against the Docker image.** A source
fork is mandatory, which means building `twenty-front` yourself and serving your own bundle.
That is a build-environment problem, not a VM problem — see §3.

### 2.2 Twenty's sidebar is a real extension point

`core."navigationMenuItem"` has `type` enum:

```
VIEW | FOLDER | LINK | OBJECT | RECORD | PAGE_LAYOUT | AGENT_CHAT_CHANNEL
| NATIVE_PAGE | WORKFLOW | AGENT | TAB | SECTION
```

plus columns `link`, `icon`, `color`, `position`, `pageLayoutId`, `nativePageKey`,
`workflowId`, `agentId`. Current workspace distribution: `OBJECT 9`, `NATIVE_PAGE 1`, `FOLDER 2`.

Two candidate mechanisms for a "Calculator" sidebar item:

| Mechanism | How | Verdict |
| --- | --- | --- |
| **`LINK` nav item** → external/embedded React page | Insert `navigationMenuItem` with `type=LINK`, `link=/calculator`, serve a custom SPA route | **Experiment A — fastest, no fork.** Proves custom UI immediately. |
| **App + front component** (`core.application`, `core.frontComponent`, `core.settingsCustomTabFrontComponentId`, `core.logicFunction`) | Ship a Twenty application with a front component | **Experiment B — the real SDK answer.** This is Twenty's supported third-party UI surface. |

Both are grounded in tables that exist on the box right now. Neither requires guessing.

### 2.3 The extension surface is richer than the docs suggest

`core.application` carries `frontComponentSharedDependenciesBuiltPath`, `sdkClientCoreChecksum`,
`logicFunctionLayerId`, `packageJsonFileId`, `yarnLockChecksum`, `sourcePath`, `sourceType`.
That is a **build-your-own-front-component** pipeline: Twenty compiles an application's
front component against a shared dependency layer and serves it inside its own shell. That is
the mechanism to "see how far the SDK goes" — and it is the honest answer to your question.

---

## 3. Build strategy — where the fork actually happens

**Do not build Twenty on sh5b.** Disk (14 G) and RAM (1.9 GiB) cannot take a cold
`yarn install` + `yarn build` of a ~2 000-package monorepo without swapping hard and risking
the box.

| Phase | Host | Output |
| --- | --- | --- |
| Fork + rebrand + build | **SH1** (root, 8 vCPU, roomy) or a transient builder VM | OCI image / built artifacts, pushed to a registry |
| Run | **sh5b** | `docker compose up` against prebuilt images |

This is the single most important structural decision in the plan: **build elsewhere, run
here.** It converts a capacity blocker into a pipeline step.

---

## 4. Phases

### Phase 0 — Gates (blocking, unchanged in spirit)

- **D-SOURCE-01**: approve immutable commit SHA from `entermarkets9/twenty` (currently
  `main` = upstream `d6e8c025`, 0 ahead / 2259 behind; fork is pristine). Must be an explicit
  SHA, not HEAD.
- **D-LEGAL-01**: AGPL / commercial-module / MIT provenance for that SHA. Blocks rebrand.
- **D-ROLE-01**: distinct `mgos_migrator` / `mgos_app` / `mgre_app` DB roles, no shared-role
  fallback (CRM-001).
- **D-CAP-01** (new, single-VM specific): memory budget signed off. Proposed allocation:
  Twenty server 800 m, worker 300 m, Postgres 256 m, Redis 96 m, MGRE 400 m, Caddy+OS 300 m
  = **2 152 m** against 1 944 m real → **over budget**. Either MGRE and MGOS never run
  simultaneously, or swap is treated as a first-class design element with
  `vm.swappiness` tuned. **This must be decided before any deploy.**
- **D-DISK-01** (new): 14 G free is insufficient for images + volumes + build cache.
  Requires either volume pruning of the 8.3 G of stopped legacy stacks, or a larger disk.
  **Blocks deployment.**

### Phase 1 — Fork, rebrand, build (on SH1)

1. Clone `entermarkets9/twenty` at the approved SHA to `/srv/mgos-source-<sha>` on SH1.
2. Rebrand inventory: the three CSVs (`twenty-mentions-files`, `-lines`, `-package-names`)
   under `docs/rebrand/`. Upstream remotes and license headers tagged `keep-upstream-ref` /
   `keep-license-notice`; queue names, storage prefixes, metadata keys tagged
   `persisted-identifier` and **not** bulk-renamed.
3. Rename packages, regenerate lockfile with pinned Yarn, `--immutable`.
4. Replace visible branding: product name, logos, favicons, email templates, PWA manifest,
   OpenGraph.
5. Build `twenty-front`, `twenty-server`, worker. Produce a checksummed artifact manifest.
6. Push images to a registry; tag by commit SHA, never `latest`.

**Exit gate:** images exist, are immutable, and are pullable from sh5b by digest.

### Phase 2 — Database isolation on sh5b

1. Existing Postgres must serve `core`/workspace (MGOS) and `public`/`stripe` (MGRE) with
   distinct roles. Create `mgos_migrator`, `mgos_app`, `mgre_app`.
2. Resolve the bootstrap conflict: Twenty's `setup-db.ts` creates
   `public.unaccent_immutable` and extensions. Inventory every object it creates in `public`;
   approve as shared with documented impact, or isolate. **Never run unmodified bootstrap
   against a database holding website tables** (CRM-002).
3. Run migration once as `mgos_migrator` under advisory lock; assert postconditions
   (expected schemas, object counts, version rows). Zero exit alone is not success (CRM-009).
4. Full schema-definition diff before/after for `public` + `stripe`: must be empty (CRM-008).

**Exit gate:** isolation matrix recorded, full-definition diff empty, advisory lock proven.

### Phase 3 — Calculator experiment (the question you actually asked)

Run in this order. Each has a hard acceptance test and can stop the chain.

**Experiment A — `LINK` nav item (proves custom UI, ~1 day)**
1. Serve a static React page at `/calculator` from Caddy (separate small container or file).
2. Insert `core."navigationMenuItem"` row: `type='LINK'`, `label='Calculator'`,
   `link='/calculator'`, `icon='IconCalculator'`, `position` after objects.
3. Verify in the running UI: the sidebar shows **Calculator**; clicking it renders your
   custom UI instead of a table view.
4. **Known gaps to document, not ignore:** does the SPA intercept internal links? Does
   `link` open a new tab? Is the nav item visible per-role? Does the workspace schema need
   the row re-inserted on upgrade?

**Experiment B — Application + front component (the real SDK answer, ~1 week)**
1. Scaffold a Twenty application (`core.application`, `sourceType`, `packageJson`,
   `yarnLock`, `frontComponent`).
2. Build the front component against the shared dependency layer
   (`frontComponentSharedDependenciesBuiltPath`, `sdkClientCoreChecksum`) and register it.
3. Expose it via `settingsCustomTabFrontComponentId` or a nav item bound to the app.
4. Record how far it goes: what the SDK exposes for data (GraphQL/metadata), what it does
   not (routing, layout, real-time), and where a fork is still required.

**Experiment C — only if B falls short:** source-level fork of `twenty-front`, custom route
and component compiled into the bundle. This is the guaranteed path and the reason Phase 1
builds a real fork.

**Decision record:** write `docs/mgos/calculator-experiment.md` with what worked, what the
SDK blocked, and which of A/B/C ships.

### Phase 4 — Custom data models and integrations

Property, Listing, Broker, Enquiry objects mirroring MGRE's `collections/Leads.ts` shape;
DataVault connector per `docs/mgos/datavault-integration-guide.md` (dedicated read-only
role, `DATA_VAULT_*` secrets, separate pool); Nabra inbound webhook with HMAC, replay
protection, tenant-scoped idempotency, DLQ (CRM-024/025). Authorization enforced
server-side per record with cross-broker negative tests across REST, GraphQL, search,
exports, attachments, related records (CRM-005).

### Phase 5 — Hosting on sh5b

1. Caddy site for the MGOS hostname → Twenty server port. TLS via Let's Encrypt (already
   proven on this box for `forbrokers.maingate.ae`).
2. `SERVER_URL` set to the public hostname before first real login.
3. **`DISABLE_SIGNUP=true`** (CRM-022). Our current live instance violates this.
4. Resource caps on every container; `vm.swappiness` tuned; memory watch with an alert.
5. Log rotation capped — 14 G disk will not tolerate unbounded Docker json logs.

### Phase 6 — Verification before calling it done

- Signup disabled and verified (attempt signup → refused).
- Sidebar Calculator renders, screen-recorded.
- Cross-broker negative tests green.
- Full-definition DB diff empty after a MGOS migration.
- Memory and disk headroom recorded under load (5 users, 100 jobs, 30 min).
- Restart resilience: reboot the VM, everything comes back.

### Phase 7 — Handoff

`docs/mgos/operations-handoff.md`: owners, runbooks (deploy, rollback, worker restart,
DB restore, secret rotation), cost worksheet, and the exact reversal commands from §1.1.

---

## 5. Risk register (single-VM specific)

| Risk | Severity | Mitigation |
| --- | --- | --- |
| RAM exhaustion kills MGRE **and** MGOS together | Critical | D-CAP-01 budget; per-container caps; swap tuned; alerting; document that one VM = one failure domain |
| 14 G disk fills (images + logs + volumes) | Critical | D-DISK-01; prune stopped legacy stacks or resize; capped log rotation |
| No HA — VM down = both apps down | High | Accepted explicitly by this topology choice; snapshot schedule; documented RTO |
| Building on the box OOMs it | High | Build on SH1, ship images by digest |
| Stale hostname `SH7B` causes ops confusion | Low | Rename to `SH5B`, pending your approval |
| Legacy volumes (8.3 G) lost if pruned | High | Snapshot before pruning; reversible stop already in place |

---

## 6. What I need from you to proceed

1. **D-DISK-01** — 14 G free is not enough. Prune the 8.3 G of stopped legacy stacks
   (openfix 7.6 G inngest-postgres is the bulk)? Or resize the disk?
2. **D-CAP-01** — confirm MGRE and MGOS will not both run at full size, or accept aggressive
   swap as a design element.
3. **D-SOURCE-01** — name the commit SHA to fork from.
4. **Calculator** — start with Experiment A (`LINK` item, fastest visible proof) or go
   straight to B (application front component, the real SDK answer)?
5. **Signup** — should I close it on the live instance now, ahead of everything else?

Nothing is edited until you answer 1–5.
