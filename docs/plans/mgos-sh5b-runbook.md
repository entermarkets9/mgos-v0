# MGOS on sh5b — executable runbook (MGOS only, owner-operated)

**Written for:** Mohammed, executing himself. Vizier does not run any of this.
**Host:** sh5b — `140.82.44.184` / Tailscale `100.74.209.88`, Ubuntu 24.04.5, 2 vCPU,
1.9 GiB RAM, 8 GiB swap.
**Scope:** MGOS (rebranded Twenty) only. **No MGRE.** No website, no Payload, no `/admin`.
**Date:** 2026-11-22

---

## 0. Where the box stands right now

| Item | Value |
| --- | --- |
| Disk | 61 G total, 38 G used, **21 G free (65 %)** — was 14 G free before reclaim |
| RAM | 1.9 GiB total; free with everything stopped |
| Swap | 8 GiB, ~170 Mi used |
| Containers running | **0** (all stopped, none removed) |
| Volumes retained | 10 volumes, 8.3 G |
| Tailscale | online, host `SH5B` |
| Caddy | v2.11.4 active, sites: `openfix.caddy`, `privacy.caddy`, `twenty.caddy` |

### What was freed, and what is still reclaimable

Freed (safe, no data loss): journal 1.0 G, unused images 5.4 G, rotated logs, apt cache.

**Still reclaimable — 8.2 G of volumes belonging to stacks you no longer want.**
These are the single biggest remaining win, but they are **data deletion**, so they are
yours to run, not mine:

```bash
# inspect first — this is the bulk
docker volume ls
du -sh /var/lib/docker/volumes/* | sort -h | tail -5

# take a snapshot of the VM in the Vultr panel BEFORE this step

# openfix stack (7.6 G is inngest-postgres alone)
docker volume rm openfix_inngest-postgres-data openfix_inngest-redis-data \
                 openfix_mongodb-data openfix_api-data

# nabra stack
docker volume rm nabra-smma_nabra-pgdata

# keep these — they are MGOS's
#   twenty_db-data, twenty_server-local-data
```

That takes you from 21 G to roughly **29 G free**. Do it only if you are certain openfix
and nabra-smma are dead on this host.

---

## 1. Decide the two numbers before any build

**D1 — MGOS memory envelope.** With MGRE gone, the budget is real:

| Component | Budget |
| --- | --- |
| Twenty server (Node, `--max-old-space-size=1024`) | 1100 m |
| Twenty worker | 400 m |
| Postgres 16 (`shared_buffers=256MB`, `max_connections=60`) | 512 m |
| Redis 7 (`--maxmemory 128mb`) | 192 m |
| Caddy + OS + sshd + fail2ban | 300 m |
| **Total** | **2504 m** vs 1944 m physical |

Still over physical RAM — but this is now acceptable because **8 G of swap exists and
MGOS is the only workload**. Set `vm.swappiness=10` and `vm.vfs_cache_pressure=50` so
idle app pages are not evicted ahead of cache. Add one 4 G swap file if you want more
headroom; there is disk for it.

**D2 — Fork commit.** Fork `entermarkets9/twenty`, `main` = `d6e8c025` (0 ahead / 2259
behind upstream). Pick an explicit SHA, not `HEAD`, and write it down. Building off a
moving branch means the rebrand diff is unreproducible.

---

## 2. Build elsewhere, run here — non-negotiable

**Do not build Twenty on sh5b.** A cold `yarn install` + `yarn build` on this monorepo
needs roughly 8–10 G disk and 2–4 GiB RAM. Even with 21 G free, the build will swap
hard and likely OOM the box mid-link.

Build on a machine with real resources (your PC, or a transient Vultr instance), then
push images and pull only the images here.

### 2.1 Build host prerequisites

```bash
# Node 24.x, corepack, yarn 4.13.0 (bundled release)
node -v            # expect v24.x
corepack enable
corepack prepare yarn@4.13.0 --activate
```

### 2.2 Clone + pin

```bash
mkdir -p ~/mgos && cd ~/mgos
git clone https://github.com/entermarkets9/twenty.git source
cd source
git checkout <APPROVED_SHA>          # NOT main, NOT HEAD
git rev-parse HEAD                    # record this in docs/rebrand/source-pin.md
```

### 2.3 The critical fact about the frontend

The published Docker image contains **only**:

```
packages/twenty-client-sdk
packages/twenty-emails
packages/twenty-server
packages/twenty-shared
```

There is **no `packages/twenty-front` source in the image**. That means:

- You cannot customise the UI by editing the image.
- A "full fork with custom UI" **requires building `twenty-front` from source**, which is
  exactly what the clone above gives you.
- The server image you build replaces `twentycrm/twenty:latest`.

### 2.4 Install and build

```bash
cd ~/mgos/source
yarn install --immutable
yarn build          # builds shared → server → front
```

Build order matters. If `yarn build` fails on a workspace ordering issue, build
explicitly:

```bash
yarn workspace twenty-shared build
yarn workspace twenty-server build
yarn workspace twenty-front build
```

### 2.5 Produce the images

Twenty ships no production Dockerfile for a forked tree that you can rely on unchanged.
Build the server image with the monorepo's own packaging, then tag by SHA:

```bash
cd ~/mgos/source
docker build -f packages/twenty-docker/twenty/Dockerfile \
  -t registry.example.com/mgos/server:<SHA> .
docker push registry.example.com/mgos/server:<SHA>
```

If you have no registry, save and scp instead (simplest, no infra):

```bash
docker save registry.example.com/mgos/server:<SHA> | gzip > mgos-server-<SHA>.tar.gz
scp mgos-server-<SHA>.tar.gz root@140.82.44.184:/opt/mgos/
ssh root@140.82.44.184 'docker load < /opt/mgos/mgos-server-<SHA>.tar.gz'
```

**Tag by SHA, never `latest`.** With 21 G disk you cannot hold many 1.8 G images — keep
two at most and prune the rest.

---

## 3. Run MGOS on sh5b

### 3.1 Compose file — MGOS only

Replace `/opt/twenty/docker-compose.yml` with a single-stack file. Nothing else runs.

```yaml
name: mgos

services:
  server:
    image: registry.example.com/mgos/server:<SHA>
    restart: unless-stopped
    ports:
      - "127.0.0.1:3110:3000"
    environment:
      NODE_PORT: 3000
      NODE_OPTIONS: "--max-old-space-size=1024"
      PG_DATABASE_URL: postgres://mgos_app:<pw>@db:5432/default
      REDIS_URL: redis://redis:6379
      SERVER_URL: https://forbrokers.maingate.ae
      STORAGE_TYPE: local
      ENCRYPTION_KEY: <keep existing from .env>
      APP_SECRET: <keep existing from .env>
      DISABLE_DB_MIGRATIONS: "true"      # migrations run separately, as migrator
      DISABLE_SIGNUP: "true"             # CRM-022
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
    image: registry.example.com/mgos/server:<SHA>
    restart: unless-stopped
    command: ["yarn", "worker:prod"]
    environment:
      NODE_OPTIONS: "--max-old-space-size=384"
      PG_DATABASE_URL: postgres://mgos_app:<pw>@db:5432/default
      REDIS_URL: redis://redis:6379
      SERVER_URL: https://forbrokers.maingate.ae
      STORAGE_TYPE: local
      ENCRYPTION_KEY: <same>
      APP_SECRET: <same>
      DISABLE_DB_MIGRATIONS: "true"
    mem_limit: 400m
    memswap_limit: 900m
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "3" }

  db:
    image: postgres:16
    restart: unless-stopped
    volumes:
      - mgos-db-data:/var/lib/postgresql/data
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
    healthcheck:
      test: redis-cli ping
      interval: 10s
      timeout: 5s
      retries: 10

volumes:
  mgos-db-data:
```

Two things in this file that matter more than they look:

- **`DISABLE_DB_MIGRATIONS: "true"` on both app containers.** Migrations run once, as the
  migrator identity, not on every container start. This is what caused the migration
  failures last time.
- **`logging` caps on every service.** Uncapped json-file logs on 21 G of disk is a
  time bomb.

### 3.2 Swap tuning

```bash
sysctl -w vm.swappiness=10
sysctl -w vm.vfs_cache_pressure=50
echo 'vm.swappiness=10'        >> /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf
```

### 3.3 First start, migrations as migrator

```bash
cd /opt/mgos
docker compose up -d db redis
# wait for healthy, then run migrations ONCE inside a throwaway container
docker compose run --rm -e NODE_OPTIONS="--max-old-space-size=1400" \
  server yarn database:init:prod
docker compose up -d server worker
```

Watch it with `docker compose logs -f server`. First boot takes 3–5 minutes; the health
endpoint goes 200 only at the end.

---

## 4. Caddy — one hostname, MGOS only

`/etc/caddy/sites/twenty.caddy` already points `forbrokers.maingate.ae` at
`127.0.0.1:3110`. Keep it. **Delete the two sites you no longer want:**

```bash
rm /etc/caddy/sites/openfix.caddy
rm /etc/caddy/sites/privacy.caddy
caddy validate --config /etc/caddy/Caddyfile && systemctl reload caddy
```

This also stops the `privacy.lnnk.app` ACME retry noise (NXDOMAIN every five minutes).

---

## 5. The Calculator experiment — three escalating options

### Option A — `LINK` nav item (fastest visible proof, ~1 day)

Schema already supports it. `core."navigationMenuItem".type` enum:

```
VIEW | FOLDER | LINK | OBJECT | RECORD | PAGE_LAYOUT | AGENT_CHAT_CHANNEL
| NATIVE_PAGE | WORKFLOW | AGENT | TAB | SECTION
```

Current workspace rows: `OBJECT 9`, `NATIVE_PAGE 1`, `FOLDER 2`.

Steps:
1. Serve your calculator UI as static files (a tiny nginx container, or add a route in
   Caddy pointing at a directory).
2. Insert the nav item into the workspace schema:

```sql
-- confirm the workspace schema name first
select nspname from pg_namespace where nspname like 'workspace_%';
```
```sql
insert into core."navigationMenuItem"
  (id, "workspaceId", "type", label, icon, position, link,
   "createdAt", "updatedAt")
values
  (gen_random_uuid(), '<workspace-id>', 'LINK', 'Calculator',
   'IconCalculator', 100, '/calculator', now(), now());
```

3. Reload the app. The sidebar should show **Calculator**, and clicking it should load
   your own page instead of a table view.

**Unknowns to record honestly:** whether the SPA intercepts internal `link` values or
opens a new tab; whether nav items are per-role; whether the row survives a schema
upgrade. Document each result — that is the experiment's actual output.

### Option B — Application + front component (the real SDK answer, ~1 week)

Twenty has a first-class third-party UI surface, and the tables are on this box:

```
core.application       core.frontComponent       core.logicFunction
core.appToken          core.logicFunctionLayer
```

`core.application` columns include `frontComponentSharedDependenciesBuiltPath`,
`sdkClientCoreChecksum`, `packageJsonFileId`, `yarnLockChecksum`, `sourcePath`,
`sourceType`, `settingsCustomTabFrontComponentId`.

That is a pipeline: **Twenty compiles your front component against a shared dependency
layer and serves it inside its own shell.** This is the honest answer to "how far can I
go with the Twenty SDK".

Steps:
1. Scaffold an application (`sourceType`, `package.json`, `yarn.lock`).
2. Build the front component against the shared dependency layer; register it.
3. Bind it to a nav item or `settingsCustomTabFrontComponentId`.
4. Record the boundary: what the SDK exposes (GraphQL, metadata) and what it does not
   (routing, layout, realtime) — that gap is exactly what justifies Option C.

### Option C — source fork of `twenty-front` (guaranteed, needs the Phase 2 build)

Add a real route and component to `packages/twenty-front/src`, rebuild the frontend,
ship a new image. This works unconditionally, which is why you are building from source
in §2. Cost: every upstream sync is a merge.

**Recommended order:** A → proves the sidebar wiring in a day. B → tells you where the
SDK actually stops. C → only if B stops short of what you need. Do not skip to C.

---

## 6. Verification checklist

- [ ] `curl -s https://forbrokers.maingate.ae/healthz` → 200
- [ ] Login works at the public hostname
- [ ] **Signup refused** (`DISABLE_SIGNUP=true`) — try to register, confirm rejection
- [ ] Sidebar shows **Calculator**; clicking it renders custom UI
- [ ] Memory after 24 h: `free -h` swap used under 1 GiB
- [ ] Disk after 24 h: logs capped, `df -h /` still above 15 G free
- [ ] Reboot test: `reboot`, everything returns without manual steps
- [ ] Rollback documented: previous image tag still present

---

## 7. Rollback

```bash
cd /opt/mgos
docker compose down            # keeps volumes
docker compose up -d           # previous images still tagged
```

Legacy stacks, if ever needed again:

```bash
cd /opt/openfix   && docker compose start
cd /opt/nabra-smma && docker compose start
systemctl start nabra-smma
```

Only if you did **not** run the §0 volume deletions.

---

## 8. What I am not doing

Per your instruction: no code edits, no builds, no deploys. This document is the
deliverable. Everything above is copy-paste ready and yours to run.
