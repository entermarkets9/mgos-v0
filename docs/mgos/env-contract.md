# Environment Contract — Website (MGRE) vs CRM (MGOS)

Single source of truth for variable **names** across the website and the CRM port.
Names only — never put secret values in this file, Git, logs, screenshots, or
command arguments. This closes G17 / T3.4 drift: one contract, one mapping.

Related: `docs/redis-namespaces.md` (Redis prefix matrix), `crm-env.md`
(handoff names-only catalog), `docs/mgos-deployment-plan.md` Session 3.2.1
(CRM-021 / CRM-022 sealed envs).

## Principles

1. **One process, one sealed env.** Website and CRM never share a process env.
   Never copy the whole website environment into a CRM API or worker.
2. **Names are intentional.** Website keeps `DATABASE_URL` / `PAYLOAD_SECRET`.
   CRM uses `PG_DATABASE_URL` / `APP_SECRET`. Never substitute one for the other.
3. **Source secrets vs runtime contract.** Dev/operator `.env` may hold provider
   secrets under historical names (`S3_*`, `UPSTASH_REDIS`). CRM runtime reads
   only the contract names below; a deploy step maps source → contract. No
   dual-name fallbacks inside CRM code paths.
4. **No silent defaults for secrets.** Missing required variables fail fast.
   No hardcoded bucket names, prefixes, or credentials in app paths.
5. **Website media ≠ CRM storage.** Payload `media` uses Replit App Storage
   (`lib/replit-object-storage-adapter.ts`). The S3 names below are for CRM
   attachments only and do not configure website media.

---

## 1. Website (MGRE) — current runtime

| Variable | Role |
| --- | --- |
| `DATABASE_URL` | Payload/Postgres connection (Replit-managed; Neon outside Replit). Owner of the public schema with `push: false`. |
| `PAYLOAD_SECRET` | Payload CMS signing/encryption. Never reuse as CRM `APP_SECRET`. |
| `SESSION_SECRET` | Express-session secret where used. |
| `COOKIE_DOMAIN` | Optional production cookie domain. |
| `PORT` / `NODE_ENV` | Website serve port (`5000`) and mode. |
| *(no bucket env)* | Website media: Replit App Storage via `.replit` config; `disableLocalStorage: true`, prefix `maingate_prod_v2/media`. No `S3_*` or `STORAGE_S3_*` keys configure website media. |
| `PROPERTY_SUBMISSION_MEDIA_DIR` | Optional private submission photo dir (default `storage/property-submissions`). Local; not cloud media. |

Website-only providers (unchanged by this contract): AI, maps, Twilio,
SendGrid, Stripe, RapidAPI, Resend, etc. See `.env.example`.

---

## 2. CRM (MGOS) — sealed runtime contract

API and worker use **identical** values for every shared variable below
(CRM-021). One env file per environment (staging / production); no cross-env
prefix sharing.

### 2.1 Database and identity

| Variable | Role |
| --- | --- |
| `PG_DATABASE_URL` | CRM restricted app-role Postgres URL. Separate database/role from website `DATABASE_URL`. Migration operator URL only in an explicit fixed migration mode. |
| `APP_SECRET` | CRM-generated secret. **Never** `PAYLOAD_SECRET`. |
| `SERVER_URL` | Approved published CRM origin (not a synthetic `127.0.0.1`). |
| `NODE_PORT` | CRM API port (distinct from website `PORT`). |
| `NODE_ENV` | `production` for sealed deploys. |
| `DISABLE_DB_MIGRATIONS` | `true` on app/worker startup paths; migrations are a separate command. |

Optional pool tuning (candidate defaults from preflight, pin explicitly):
`PG_POOL_MAX_CONNECTIONS`, `PG_POOL_IDLE_TIMEOUT_MS`,
`PG_DATABASE_PRIMARY_TIMEOUT_MS`, `PG_POOL_ALLOW_EXIT_ON_IDLE`.

Feature flags (explicit; no ambient defaults in sealed envs):
`IS_BILLING_ENABLED`, `TELEMETRY_ENABLED`, `IS_FDW_ENABLED`,
`IS_CONFIG_VARIABLES_IN_DB_ENABLED`, `IS_SIGN_UP_DISABLED`, `EMAIL_DRIVER`,
`EMAIL_FROM_ADDRESS`, `LOGGER_IS_BUFFER_ENABLED`. Production identity defaults
are not the synthetic preflight values (signup disabled; real email provider,
not `logger`).

### 2.2 Storage — native Backblaze S3 (CRM attachments only)

Contract names consumed by CRM API and worker (CRM-021). **No local, bridge,
or website-storage fallback** for persistent attachments.

Names below are the **exact vendor keys** Twenty reads
(`vendor/crm/packages/twenty-server/src/engine/core-modules/twenty-config/config-variables.ts`,
`STORAGE_CONFIG` group, verified G7/T5.1 partial). API and worker share an
**identical** storage contract: the worker (`src/queue-worker/queue-worker.ts`
→ `QueueWorkerModule` → `CoreEngineModule` → `TwentyConfigModule.forRoot()`)
loads the same `ConfigVariables` class as the API process; both resolve env
through the same `EnvironmentConfigDriver` (`configService.get(key)`), so the
process env names are byte-identical for both roles.

| Contract variable | Meaning |
| --- | --- |
| `STORAGE_TYPE` | Sealed value `S_3` for production/staging CRM attachments. Vendor enum is `LOCAL \| S_3` with default `LOCAL`; the `@CastToUpperSnakeCase()` decorator normalizes inputs (`s3` → `S_3`), but sealed envs must pin the canonical `S_3` explicitly. |
| `STORAGE_S3_NAME` | **Bucket name** (historical probe bucket: `mgre-v2`). Note: the vendor key is `STORAGE_S3_NAME`, **not** `STORAGE_S3_BUCKET`. |
| `STORAGE_S3_ENDPOINT` | Custom S3 endpoint. Required for Backblaze (`https://s3.<region>.backblazeb2.com`); optional for native AWS (SDK resolves from region). |
| `STORAGE_S3_REGION` | Region derived from the endpoint hostname (e.g. `eu-central-003`); pin explicitly in sealed envs. Required when `STORAGE_TYPE=S_3`. |
| `STORAGE_S3_ACCESS_KEY_ID` | S3 access key ID. Optional in vendor schema (AWS credential chain fallback); **required for B2** since B2 has no instance-profile chain. |
| `STORAGE_S3_SECRET_ACCESS_KEY` | S3 secret access key. Required whenever `STORAGE_S3_ACCESS_KEY_ID` is set. |
| `STORAGE_S3_PRESIGNED_URL_ENABLED` | Boolean. `false` (vendor default) proxies uploads/downloads through the server; `true` 302-redirects downloads and issues presigned PUT uploads (needs bucket CORS). |
| `STORAGE_S3_PRESIGNED_URL_BASE` | Optional public base URL for presigned URLs, only when `STORAGE_S3_ENDPOINT` is an internal address (e.g. Docker MinIO). Not applicable to B2 (public endpoint). |
| `STORAGE_S3_PRESIGNED_URL_EXPIRES_IN` | Presigned-URL TTL in **seconds** (vendor default `900`). Acceptance includes expiry and cross-workspace denial tests. |

Notes:

- **There is no `STORAGE_S3_FORCE_PATH_STYLE` env var.** `forcePathStyle: true`
  is hardcoded in the vendor factory
  (`src/engine/core-modules/file-storage/file-storage-driver.factory.ts`).
  Path-style is therefore always on; there is nothing to pin in the env.
- `STORAGE_TYPE=LOCAL` implies `STORAGE_LOCAL_PATH` (vendor default
  `.local-storage`). Local exists only in preflight tooling for **ephemeral
  core assets** (e.g. `…/ephemeral-core-assets`). It is never a production
  attachment target and never a fallback when S3 is unset; sealed envs never
  set `STORAGE_TYPE=LOCAL`.

#### Source → contract mapping (operator `.env` / secret manager → CRM sealed env)

| Source name (`.env`, proof harness) | Contract name (CRM runtime) | Notes |
| --- | --- | --- |
| `S3_ENDPOINT` | `STORAGE_S3_ENDPOINT` | Proof: `experiments/crm-preflight/run-native-s3.mjs` reads `S3_ENDPOINT` / `S3_KEY_ID` / `S3_ACCESS_KEY` directly. Historical only. |
| `S3_KEY_ID` | `STORAGE_S3_ACCESS_KEY_ID` | Despite `KEY_ID`, this is the access key id. |
| `S3_ACCESS_KEY` | `STORAGE_S3_SECRET_ACCESS_KEY` | Despite its name, this is the **secret** component. |
| `S3_BUCKET_NAME` | `STORAGE_S3_NAME` | Historical value `mgre-v2` was hardcoded in proof tooling; sealed envs must set the contract name explicitly. |
| *(derived)* | `STORAGE_S3_REGION` | From endpoint hostname (`s3.<region>.backblazeb2.com` → `<region>`). |
| *(derived, no env)* | `STORAGE_TYPE=S_3` | Pin at seal time. Path-style is hardcoded vendor-side; no contract variable. |

Mapping is performed at deploy/seal time (secret manager or deploy script).
CRM code reads only `STORAGE_*` / `STORAGE_S3_*`. Website media never consumes
either side of this mapping.

#### Acceptance status (G7 / T5.1 — partial)

- ✅ Contract names verified against vendor source (API + worker identical).
- ⚠️ `scripts/probe-b2.mjs` performs a **credential reachability HEAD**
  against the B2 bucket from operator `.env`. It is **not** CRM acceptance.
- ❌ **UAT-C6 is not passed by this probe.** Live acceptance requires T5.1 app
  wiring: CRM API/worker running with sealed `STORAGE_*` envs, attachment
  upload/download through `S3Driver`, presigned-URL expiry, and
  cross-workspace denial tests. Do not mark UAT-C6 or T5.1 acceptance on the
  strength of the probe alone.

---

## 3. Redis — one secret, derived names

Source of truth in operator `.env`: **`UPSTASH_REDIS`** (connection URL).
Never commit, log, or embed the value. Protocol is forced to `rediss://` (TLS)
before use; host must be `*.upstash.io`. No self-hosted fallback.

CRM runtime (API + worker) reads only the derived names, per
`docs/redis-namespaces.md`:

| Derived variable | Value |
| --- | --- |
| `REDIS_URL` | TLS-forced URL for the app's own prefix root (cache, session, rate-limit clients). |
| `REDIS_QUEUE_URL` | TLS-forced URL, shared connection (queue producers and workers). |
| `REDIS_QUEUE_PREFIX` | Braced BullMQ prefix from the namespace matrix, e.g. `{prod:crm:queue}` / `{staging:crm:queue}`. Never a global/shared website key space. |

An environment selects its matrix row; no code path hardcodes a prefix that
contradicts the matrix. Queue roots are immutable once any environment has
accepted work.

---

## 4. CMS admin bootstrap

| Variable | Role |
| --- | --- |
| `CMS_ADMIN_EMAIL` | Payload admin email for authenticated production scripts (e.g. `scripts/assign-production-inventory.ts`). |
| `CMS_ADMIN_PASSWORD` | Matching password. |

Supply via the platform secret manager (Replit Secrets / sealed ops env).
Legacy `ADMIN_EMAIL` / `ADMIN_PASSWORD` placeholders in older `.env.example`
copies are **not** this contract; use `CMS_ADMIN_*` for bootstrap scripts.
Never print these values; scripts must not log request bodies or tokens.

---

## 5. Historical / retired aliases (do not equate silently)

| Name | Status |
| --- | --- |
| `T3`–`T6`, `AWS_accesskey`, `AWS_S3` | Historical handoff labels (`crm-env.md` §3). Not part of the sealed contract; do not invent pairings. |
| `CRM_PREFLIGHT_DATABASE_URL`, `CRM_PREFLIGHT_REDIS_URL` | Descriptive staging intent only; not confirmed secrets. |
| `DATABASE_URL` inside CRM processes | Forbidden; CRM uses `PG_DATABASE_URL`. |
| `PAYLOAD_SECRET` inside CRM processes | Forbidden; CRM uses `APP_SECRET`. |
| `GOOGLE_CLOUD_PROJECT` / `GOOGLE_CLOUD_BUCKET` | Obsolete website-media suggestion; website media is Replit App Storage. CRM storage is native S3 above. |
| `UPSTASH_REDIS` inside CRM app/worker | Not read by CRM runtime; only the mapping step consumes it to mint `REDIS_*`. |

---

## 6. Acceptance checklist (T3.4 seal)

- [ ] Website and CRM process envs are disjoint; no secret reuse across roles
      except intentional mapped values (Redis URL, S3 credential pair).
- [ ] CRM API and worker envs are byte-identical for `PG_*`, `APP_SECRET`,
      `REDIS_*`, `STORAGE_TYPE`, `STORAGE_S3_*`.
- [ ] `STORAGE_TYPE=S_3` and all required `STORAGE_S3_*` set; no local path in
      production.
- [ ] `REDIS_QUEUE_PREFIX` matches the environment's matrix row.
- [ ] `CMS_ADMIN_*` present for bootstrap scripts; values not in Git.
- [ ] No secret values in this doc, `.env.example`, or logs.
