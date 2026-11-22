# MGOS — build plan (latest Twenty, single VM)

**Repo:** `entermarkets9/mgos` (this repository)
**Upstream base:** `twentyhq/twenty` @ `main` = `4bac2940dcdcbf4bb4c974b628cd5e1b0a2e37e0` (2026-11-22)
**Latest release tag at fork time:** `sdk/v2.59.0` (2026-11-16)
**Runtime target:** one VM — sh5b (`140.82.44.184` / Tailscale `100.74.209.88`),
Ubuntu 24.04.5, 2 vCPU, 1.9 GiB RAM, 8 GiB swap, 21 G free disk
**Scope:** MGOS only. No MGRE, no website, no Payload `/admin`.
**Status:** plan. Owner builds; Vizier does not execute.

---

## 0. What this repository is

A **source fork** of Twenty at a pinned commit, plus the MGOS documentation carried over
from `entermarkets9/mgre-new` (`docs/mgos/`, `docs/uat/`). The fork exists because:

> The published `twentycrm/twenty` Docker image contains only
> `twenty-client-sdk`, `twenty-emails`, `twenty-server`, `twenty-shared`.
> **There is no `twenty-front` source in it.**

So any custom UI — a Calculator sidebar item, a rebrand, a new page — requires owning the
frontend source and building it yourself. That is what this repo is for.

### What was carried over from mgre-new

| File | Origin | Purpose |
| --- | --- | --- |
| `docs/mgos/mgos-deployment-plan-replit-legacy.md` | `docs/mgos-deployment-plan.md` | Superseded Replit plan, kept as evidence/history |
| `docs/mgos/crm-ui-ownership.md` | `.agents/memory/crm-ui-ownership.md` | The product requirement: source-level UI control, not theming |
| `docs/mgos/crm-native-model-contract.md` | `docs/crm-native-model-contract.md` | Domain model contract |
| `docs/mgos/crm-native-runtime-contract.md` | `docs/crm-native-runtime-contract.md` | Runtime contract |
| `docs/mgos/crm-native-services-contract.md` | `docs/crm-native-services-contract.md` | Services contract |
| `docs/mgos/crm-scoped-contracts.md` | `docs/crm-scoped-contracts.md` | Scoped contracts |
| `docs/mgos/crm-scoped-acceptance.md` | `docs/crm-scoped-acceptance.md` | Acceptance criteria |
| `docs/mgos/crm-target-state.md` | `docs/crm-target-state.md` | Target state |
| `docs/mgos/crm-source-audit.md` | `docs/crm-source-audit.md` | Source audit |
| `docs/mgos/crm-pilot-phased-project-plan.md` | `docs/crm-pilot-phased-project-plan.md` | Historical phased plan |
| `docs/mgos/env-contract.md` | `docs/env-contract.md` | Env contract |
| `docs/mgos/datavault-integration-guide.md` | `docs/mgos/datavault-integration-guide.md` | DataVault connector contract |
| `docs/mgos/crm-preflight-README.md` | `experiments/crm-preflight/README.md` | Proven preflight tooling patterns |
| `docs/mgos/crm-preflight-pin.json` | `experiments/crm-preflight/pin.json` | Historical pin (ARCHIVED baseline) |
| `docs/mgos/crm-env-legacy.md` | `crm-env.md` | Legacy env/DB catalog reference |
| `docs/uat/twenty-crm-handoff-replit.md` | `docs/uat/twenty-crm-handoff-replit.md` | Replit UAT handoff (historical) |

---

## 1. Environment reality (measured, 2026-11-22)

| Item | Value | Constraint it imposes |
| --- | --- | --- |
| vCPU | 2 | Builds are slow; do not build here |
| RAM | 1.9 GiB | Twenty needs ~1.4 GiB resident; thin |
| Swap | 8 GiB (~170 Mi used) | Absorbs the gap — tune `vm.swappiness=10` |
| Disk | 61 G, 38 G used, **21 G free** | Enough to run, not to build |
| Containers running | 0 (all stopped, volumes retained) | Clean slate |
| Retained volumes | 10, 8.3 G (openfix 7.6 G is the bulk) | Further 8.2 G reclaimable if you prune |
| Caddy | v2.11.4, sites: openfix / privacy / twenty | `forbrokers.maingate.ae` → `127.0.0.1:3110` works |
| Hostname | static `SH7B`, Tailscale says `SH5B` | Cosmetic; `hostnamectl set-hostname SH5B` optional |

### Build here vs run here

**Build on a machine with resources. Run on sh5b.**

A cold `yarn install --immutable` + `yarn build` on this monorepo needs roughly 8–10 G disk
and 2–4 GiB RAM. On sh5b that will swap hard and likely OOM mid-link. Build on your PC or a
transient VM, then ship the image:

```bash
# on the build host
docker save mgos/server:<SHA> | gzip > mgos-server-<SHA>.tar.gz
scp mgos-server-<SHA>.tar.gz root@140.82.44.184:/opt/mgos/

# on sh5b
docker load < /opt/mgos/mgos-server-<SHA>.tar.gz
```

Or push to a registry and pull by digest. **Tag by commit SHA, never `latest`** — 21 G of
disk holds only two images of this size.

---

## 2. Getting started (clone → build)

```bash
git clone https://github.com/entermarkets9/mgos.git
cd mgos

# Node 24 and the bundled Yarn release
node -v                       # expect v24.x
corepack enable
corepack prepare yarn@4.13.0 --activate

yarn install --immutable

# build order matters
yarn workspace twenty-shared build
yarn workspace twenty-server build
yarn workspace twenty-front build
```

If `yarn build` at the root fails on workspace ordering, the three explicit commands above
are the reliable path.

Record in `docs/mgos/source-pin.md`: the commit SHA, the lockfile hash, Node and Yarn
versions. This makes the rebrand diff reproducible.

---

## 3. Database isolation (still mandatory)

The rev-4 plan's core invariant survives the topology change. **Distinct roles, no
shared-role fallback.**

| Concern | Contract |
| --- | --- |
| Schemas | MGOS owns `core` + `workspace_*`. Nothing else writes there. |
| Roles | `mgos_migrator` (DDL in `core`/workspace only), `mgos_app` (DML, `search_path=core`). Runtime cannot migrate. |
| Migrations | Run once, as `mgos_migrator`, under a Postgres **advisory lock** with timeout. Assert postconditions — expected schemas, object counts, version rows. A zero exit code alone is not success. |
| Bootstrap conflict | Twenty's `scripts/setup-db.ts` creates `public.unaccent_immutable` and extensions. Inventory every object it creates outside `core` before running, and approve each one deliberately. |
| App containers | `DISABLE_DB_MIGRATIONS: "true"` — migrations are a separate step, never on container start. |

The last deployment failed exactly here: migrations logged "Successfully migrated DB!" while
`core` ended up with **0 tables**. Postcondition assertions are the fix, not trust in the exit code.

---

## 4. Compose file (MGOS only)

`/opt/mgos/docker-compose.yml`:

```yaml
name: mgos

services:
  server:
    image: mgos/server:<SHA>
    restart: unless-stopped
    ports: ["127.0.0.1:3110:3000"]
    environment:
      NODE_PORT: 3000
      NODE_OPTIONS: "--max-old-space-size=1024"
      PG_DATABASE_URL: postgres://mgos_app:<pw>@db:5432/default
      REDIS_URL: redis://redis:6379
      SERVER_URL: https://forbrokers.maingate.ae
      STORAGE_TYPE: local
      ENCRYPTION_KEY: <existing>
      APP_SECRET: <existing>
      DISABLE_DB_MIGRATIONS: "true"
      DISABLE_SIGNUP: "true"
    mem_limit: 1100m
    memswap_limit: 2500m
    depends_on:
      db: { condition: service_healthy }
      redis: { condition: service_healthy }
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "3" }
    healthcheck:
      test: curl --fail http://localhost:3000/healthz || exit 1
      interval: 20s
      timeout: 10s
      retries: 20
      start_period: 240s

  worker:
    image: mgos/server:<SHA>
    restart: unless-stopped
    command: ["yarn", "worker:prod"]
    environment:
      NODE_OPTIONS: "--max-old-space-size=384"
      PG_DATABASE_URL: postgres://mgos_app:<pw>@db:5432/default
      REDIS_URL: redis://redis:6379
      SERVER_URL: https://forbrokers.maingate.ae
      STORAGE_TYPE: local
      ENCRYPTION_KEY: <existing>
      APP_SECRET: <existing>
      DISABLE_DB_MIGRATIONS: "true"
    mem_limit: 400m
    memswap_limit: 900m
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "3" }

  db:
    image: postgres:16
    restart: unless-stopped
    volumes: ["mgos-db-data:/var/lib/postgresql/data"]
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: <pw>
      POSTGRES_DB: default
    command: ["postgres", "-c", "shared_buffers=256MB", "-c", "max_connections=60"]
    mem_limit: 512m
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "3" }
    healthcheck:
      test: pg_isready -U postgres -d default
      interval: 10s
      timeout: 5s
      retries: 10

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: ["--maxmemory", "128mb", "--maxmemory-policy", "noeviction"]
    mem_limit: 192m
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "3" }

volumes:
  mgos-db-data:
```

Memory budget: 1100 + 400 + 512 + 192 + ~300 (Caddy/OS) = **2504 m** against 1944 m physical.
Acceptable only because MGRE is gone and 8 G of swap exists. Tune swap:

```bash
sysctl -w vm.swappiness=10
sysctl -w vm.vfs_cache_pressure=50
```

First start:

```bash
docker compose up -d db redis
docker compose run --rm -e NODE_OPTIONS="--max-old-space-size=1400" \
  server yarn database:init:prod        # migrations, once, as migrator
docker compose up -d server worker
docker compose logs -f server           # 3–5 min to healthy
```

---

## 5. The Calculator experiment — three routes

Schema facts from the running instance (verified, not assumed):

```
core."navigationMenuItem".type enum:
  VIEW | FOLDER | LINK | OBJECT | RECORD | PAGE_LAYOUT | AGENT_CHAT_CHANNEL
  | NATIVE_PAGE | WORKFLOW | AGENT | TAB | SECTION
```

Existing tables that form the SDK surface: `core.application`, `core.frontComponent`,
`core.logicFunction`, `core.logicFunctionLayer`, `core.appToken`. `core.application` carries
`frontComponentSharedDependenciesBuiltPath`, `sdkClientCoreChecksum`, `packageJsonFileId`,
`yarnLockChecksum`, `sourcePath`, `sourceType`, `settingsCustomTabFrontComponentId` — a real
build pipeline for third-party front components.

### Route A — `LINK` nav item (fastest proof, no fork needed)

Insert a nav item pointing at your own page:

```sql
insert into core."navigationMenuItem"
  (id, "workspaceId", "type", label, icon, position, link, "createdAt", "updatedAt")
values
  (gen_random_uuid(), '<workspace-id>', 'LINK', 'Calculator',
   'IconCalculator', 100, '/calculator', now(), now());
```

Serve `/calculator` from Caddy (static dir or a tiny nginx container).

**Unknowns to record as the real output of this experiment:**
- Does the SPA intercept internal `link` and render in-app, or open a new tab?
- Is the nav item visible per-role or globally?
- Does the row survive a workspace schema upgrade, or must it be re-inserted?

### Route B — Application + front component (the SDK answer)

Scaffold a Twenty application, build its front component against the shared dependency
layer, register it, bind it to a nav item or `settingsCustomTabFrontComponentId`. This is
Twenty's supported third-party UI surface.

Record the boundary honestly: what the SDK exposes (GraphQL, metadata, settings tabs) and
what it does not (routing, layout control, realtime). That gap is the justification for C.

### Route C — source fork of `twenty-front` (guaranteed)

Add a route and component in `packages/twenty-front/src`, rebuild, ship a new image. Works
unconditionally; costs a merge on every upstream sync. This repo exists so this option is
always available.

**Order: A → B → C.** A proves the sidebar wiring in a day. B tells you where the SDK stops.
C only if B stops short.

---

## 6. Hosting

`/etc/caddy/sites/twenty.caddy` already proxies `forbrokers.maingate.ae` → `127.0.0.1:3110`
with a valid Let's Encrypt cert (verified). Remove the two sites you no longer want:

```bash
rm /etc/caddy/sites/openfix.caddy /etc/caddy/sites/privacy.caddy
caddy validate --config /etc/caddy/Caddyfile && systemctl reload caddy
```

This also stops the `privacy.lnnk.app` ACME NXDOMAIN retries.

---

## 7. Verification

- [ ] `curl -s https://forbrokers.maingate.ae/healthz` → 200
- [ ] Login works at the public hostname
- [ ] Signup refused (`DISABLE_SIGNUP=true`) — attempt it, confirm rejection
- [ ] Sidebar shows **Calculator**; clicking it renders custom UI
- [ ] `core` schema has expected tables (postcondition, not just exit code)
- [ ] Memory after 24 h: swap used under 1 GiB
- [ ] Disk after 24 h: still above 15 G free
- [ ] Reboot returns everything without manual steps

---

## 8. Rollback

```bash
cd /opt/mgos && docker compose down && docker compose up -d   # keeps volumes
```

Legacy stacks (only if you did not prune their volumes):

```bash
cd /opt/openfix    && docker compose start
cd /opt/nabra-smma && docker compose start && systemctl start nabra-smma
```

---

## 9. Decisions still open

| ID | Decision | Default if unresolved |
| --- | --- | --- |
| D-SOURCE-01 | Pin an explicit SHA for the rebrand baseline (this fork starts at `4bac2940`) | Fork stays at `4bac2940` |
| D-LEGAL-01 | AGPL / commercial-module / MIT provenance for this commit | BLOCKED — no rebrand commit |
| D-ROLE-01 | `mgos_migrator` / `mgos_app` created with negative-access proof | STOP |
| D-DISK-01 | Prune the 8.2 G of dead volumes, or resize | 21 G free, tight but workable |
| D-CALC-01 | Route A, B, or C first | A |
