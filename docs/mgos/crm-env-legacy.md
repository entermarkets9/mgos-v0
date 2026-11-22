# Twenty CRM port — external environment handoff

Prepared: 2026-10-10. Intended recipient: the engineer taking over the Twenty CRM
port alongside this website. This file is self-contained, including a development
database catalog appendix. It contains environment **names**, not secret values.
Treat it as an internal handoff: it includes a user-supplied infrastructure IP
and schema details, and is not intended for public publication.

## 1. Identity, scope and evidence

- **User-confirmed:** The source product to be ported is **Twenty CRM**. Earlier
  project-owned experiment paths use neutral `crm` names intentionally. They are
  historical tooling labels, not proof that renamed Twenty packages exist.
- **User-supplied worker IP:** `64.177.53.107`. This was the Vultr worker VM used
  for the Twenty worker. Its current reachability, ownership/tier and running
  services have **not** been rechecked for this handoff.
- **Scope:** Externalize the implementation handoff, not implement or deploy the
  port. Do not provision, resize/delete the VM, reactivate staging, publish,
  migrate records or start spending merely because you received this document.
- **Current source/configuration:** Inspectable website and experiment code.
  Database appendix: read-only **development** catalog snapshot, not production.
- **Historical results:** Reported by `experiments/crm-preflight/README.md`;
  missing raw logs/report bodies were not recovered or remeasured.
- **Unknown:** Production schema parity, current provider inventories/billing,
  published CRM acceptance and actual approved privately branded source fork.
- **Planning:** `docs/crm-port-project-plan.md` is the Git-tracked reconstruction
  with proposed 10 phases/35 sessions. It is not the missing original or an effort
  guarantee. Its original neutral naming rule is not a denial of Twenty's identity.

Product work requires a maintained source fork with granular frontend/component
control, not an iframe or runtime-theme-only wrapper. Cover visible identity,
company attribution, backend/package/build/SDK namespaces and persisted identifier
transitions. Preserve truthful legal provenance and required license notices.
No new broker feature suite, SSO, real DataVault integration, website-to-CRM lead
delivery or real lead/contact migration is approved by this handoff.

## 2. Replit and current website runtime

### Repository and framework

- Website: Main Gate real-estate Next.js App Router + Payload CMS, React and
  TypeScript; package manager for this website is npm.
- Configured Nix modules: `nodejs-20`, `web`, `python-3.11`, `postgresql-16`;
  channel `stable-24_05`. Database server version was not inferred from this module.
- Declared dependency ranges: Next `^16.3.1`, React/React DOM `^19.2.8`,
  Payload and its Postgres/Next/storage/UI/editor packages `^3.88.0`,
  TypeScript `^7.0.2`, `@replit/object-storage` `^1.0.0`.
  These are package.json ranges, not a measured installed-version report.
- `package.json` uses `"type": "module"`; Payload CLI/Next integration relies on it.
- Marketing pages and Payload use separate root route groups:
  `app/(app)` and `app/(payload)`. Do not recreate one shared `app/layout.tsx`.
- `collections/`, `globals/`, `payload.config.ts`, `payload-types.ts`,
  `migrations/`, `lib/` and `components/` are the main implementation boundaries.
- The older `replit.md` includes obsolete "empty/not used" database and old layout
  notes. The inspected configuration and catalog in this handoff take precedence.

### Commands and workflow

| Purpose | Current configured command |
| --- | --- |
| Website development | `npm run dev` → `next dev -p 5000` |
| Website production process | `npm run start` → `next start -p 5000` |
| Build | `npm run build` → `next build` |
| Type check | `npx tsc --noEmit` |
| Enquiry routing checks | `npm run test:enquiry-routing && npm run test:routing-migration` |
| Additional existing checks | `test:leads-csv`, `test:off-plan`, `test:property-finder` npm scripts; inspect targets before running |

The `.replit` run-button workflow `Project` runs Start application, typecheck,
enquiry-routing and build in parallel. Website serves port 5000; `PORT=5000`.
Configured local→external port mappings: `3000→3002`, `3001→3003`, `3002→4200`,
`3003→5000`, `5000→80`, `5001→3000`, `5002→3001`. These are configuration,
not evidence that every service is listening. The experimental API workflow is gone.

The website deployment target is **Replit Autoscale**. Current configured build
command is `npx payload migrate && npm run build`; runtime is `npm run start`.
Do not treat the existing deployment hook as authorization to apply new DDL.
`scripts/post-merge.sh` also contains Payload migration/repair logic. It is not
a safe generic Twenty staging/bootstrap script and must not be run for the port.

Replit manages separate development and production databases for managed projects;
the production schema must be independently checked before moving it. Official
managed-database publishing guidance uses the Publish schema-diff flow. This
repository also has historical committed Payload migrations and build/post-merge
hooks: document and reconcile the actual migration target/ownership before any
future publish or external migration. Do not blindly add startup-time DDL.

### Preview/origins and externalization

Replit preview is a proxied iframe, not direct localhost browsing.
`next.config.mjs` permits `127.0.0.1`, `localhost`, `*.replit.dev`, `*.repl.co`
and concrete `REPLIT_DEV_DOMAIN` / comma-separated `REPLIT_DOMAINS`.
Those variables identify development origins, **not** the published production URL.
Production URL is not verified here; `.replit`'s configured production
`CUSTOM_DOMAIN` is not proof of published routing.

Keep same-project browser API calls relative. Outside Replit, explicitly configure
the approved origin/ingress and secure cookie behavior, bind the platform-required
port/interface and replace any Replit-only runtime identity dependency. Do not copy
the website's whole environment into a Twenty process or worker.

Useful official documentation:
- https://docs.replit.com/features/publishing/overview
- https://docs.replit.com/features/publishing/deployment-types
- https://docs.replit.com/core-concepts/project-editor/app-setup/secrets
- https://docs.replit.com/features/data-and-storage/sql-database
- https://docs.replit.com/features/data-and-storage/development-and-production
- https://docs.replit.com/features/data-and-storage/object-storage

## 3. Credential-variable map — names only

Secret presence was checked without retrieving values. Presence is not proof of
validity, access scope or current account ownership. Transfer authorized values
separately through the destination's secret manager; never put them in this file,
Git, command arguments, screenshots, logs or a public handoff.

| Existing variable | Meaning / consumer | Boundary |
| --- | --- | --- |
| `T3` | **User-confirmed Vultr API key**; historical provider lifecycle tooling | Provider credential; never use without fresh resource/spending approval |
| `T4` | **User-confirmed Redis connection credential/URL**; historical dedicated Upstash service | Runtime helpers convert/use verified TLS `rediss://`; not REST/plaintext fallback |
| `T5` | **User-confirmed root SSH password for the Vultr worker VM** at `64.177.53.107` | Bootstrap credential, not Twenty application password; transfer securely, never embed |
| `T6` | **User-confirmed disposable Neon PostgreSQL connection URL** used by the experiment | Retired/disposable staging only; not website DATABASE_URL or approved production DB |
| `T1`, `T2` | Exist; roles not established for this handoff | Do not guess or use as fallback |
| `DATABASE_URL` | Website Payload PostgreSQL connection, runtime-managed in Replit | Never substitute for T6/Twenty staging; securely provision explicit target outside Replit |
| `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD` | Replit runtime-managed PostgreSQL names | Not read/exported here; do not rely on their availability outside Replit |
| `PAYLOAD_SECRET` | Payload CMS signing/encryption secret | Preserve securely for website continuity; not Twenty APP_SECRET |
| `SESSION_SECRET` | Existing secret; not referenced by the inspected Payload config | Do not assume it signs Twenty or Payload sessions |
| `S3_KEY_ID` | Native Backblaze S3 access key ID; mapped by proof to `accessKeyId` | CRM storage credential; see section 4 |
| `S3_ACCESS_KEY` | Native Backblaze S3 secret access key; mapped to `secretAccessKey` | Despite its name, this is the secret component |
| `S3_ENDPOINT` | Backblaze S3 endpoint, held as a secret | Value deliberately omitted; proof accepts direct HTTPS Backblaze endpoint |
| `AWS_accesskey`, `AWS_S3` | Other existing secret names | No assumed pairing/role; not website media or CRM automatic fallback |

Other confirmed-present names, not required to run the isolated Twenty worker:
`RESEND_API_KEY`, `TWILIO_ACCOUNT_SID`, `TWILIO_API_KEY`,
`TWILIO_API_KEY_SECRET`, `GOOGLE_API_KEY`, `GOOGLE_MAPS_API_KEY`,
`PROP_AI_API_KEY`, `RAPID_API`, `AI_INTEGRATIONS_OPENAI_API_KEY`,
`AI_INTEGRATIONS_OPENAI_BASE_URL`, `AI_INTEGRATIONS_GEMINI_API_KEY`,
`AI_INTEGRATIONS_GEMINI_BASE_URL`. Inspect each website feature's consumer before
copying or omitting it. Replit-managed AI endpoints may need a different approved
provider/credential outside Replit; variable presence does not grant portability.
Do not send website/provider secrets to dependency install/build subprocesses.

Descriptive names in early instructions such as `CRM_PREFLIGHT_DATABASE_URL` and
`CRM_PREFLIGHT_REDIS_URL` describe desired isolated staging configuration, not
confirmed extra secrets. Do not silently equate every historical alias.

## 4. S3 and other storage boundaries

### Selected CRM backend: native Backblaze S3

`experiments/crm-preflight/run-native-s3.mjs` directly consumes:

| Source value/name | Proof interpretation |
| --- | --- |
| `S3_ENDPOINT` | HTTPS endpoint; host must match `s3.<region>.backblazeb2.com`; region derived from hostname |
| `S3_KEY_ID` | S3 `accessKeyId` |
| `S3_ACCESS_KEY` | S3 `secretAccessKey` |
| Historical bucket | `mgre-v2`, hardcoded in proof tooling, **not** a confirmed `S3_BUCKET` environment variable |
| Historical proof namespace | Random `crm-preflight/s3-<UUID>/`, retired; not a production attachment prefix |

This is a proof harness mapping, not certification of the final owned fork's
native environment contract. Obtain the actual approved Twenty fork's storage
variable names, region/path-style/public-URL settings and factory/attachment
configuration before deploying; do not invent a final upstream variable mapping.

Native transfer/streams/ranges/metadata, private access, signing/expiry and copy
preconditions were historically reported as passing on Replit and the worker.
Browser CORS was absent: configure exact approved origins or native server-mediated
transfer. Prove workspace/record authorization before issuing signed URLs and deny
anonymous/cross-workspace access. Prove full upload/read/replace/delete/restart and
object-version cleanup in the real application, not only its storage driver.
No automatic fallback to local files, a bridge or website storage.

### Website media: Replit App Storage, not these S3 keys

`payload.config.ts` registers `lib/replit-object-storage-adapter.ts` for the `media`
collection with `disableLocalStorage: true`, prefix `maingate_prod_v2/media`.
The SDK uses `.replit`'s configured default bucket and Replit runtime access.
The bucket ID can be obtained from that configuration by the authorized operator;
it is not needed to understand the schema and is not duplicated here.

Outside Replit, design an explicit website storage migration/access strategy.
Copying S3 secrets does **not** make `@replit/object-storage` or website media work.
Retain object keys/metadata and authorized media URLs; do not replace Payload
storage as part of the CRM port. Historical App Storage CRM bridge tooling is an
incomplete alternative spike, not the selected production driver.

### Private owner-submission photos: separate local-storage gap

`collections/PropertySubmissionPhotos.ts` has authenticated read/create/update/delete
and JPEG/PNG/WebP uploads with a review derivative. Its configured directory is
`PROPERTY_SUBMISSION_MEDIA_DIR` or `storage/property-submissions`; it is not registered
in the inspected cloud-storage plugin. Do not conflate these private photos with
public `media` or Twenty attachments. Inspect persistent volume/backup/authorization
behavior before external hosting; do not expose the directory as public static media.

## 5. Website database and application constraints

### Target and schema ownership

The read-only catalog snapshot appended below is from **Replit development**,
2026-10-10. No business rows, contact records, hashes, session tokens or secret
values were selected. Production schema/data was not queried.
Payload uses `DATABASE_URL`, the Postgres adapter, `push: false` and default
`public` schema. Do not move Payload into Twenty's `core` or workspace schemas.

The snapshot has `public` CMS/application tables and a separate `stripe` schema.
The Stripe schema is observed integration-managed material, not Twenty's schema
and not proof that the website uses every payment capability. Do not edit its
tables directly or merge its objects into the CRM database.
Installed extensions observed: `plpgsql`, `pg_trgm`.
No Twenty `core` or workspace tables were observed in this website snapshot.

The disposable Neon experiment is a different database: historical setup created
`core`, a separate CRM role/search path and a Payload fixture role using `public`.
Migrations were operator-owned, not API-startup-owned. Its cleaned/retired current
schema is not inspected here. Replit managed-provider helper/extension/ownership
support cannot be inferred from the Neon experiment.

### Domain and important relationships

| Collection/global | Website role |
| --- | --- |
| `admins`, `admins_sessions` | Payload accounts/authentication; super-admin/editor roles and sessions |
| `media`, `property_submission_photos` | Public marketing metadata vs private owner-submission upload metadata |
| `team_members` | People, active/broker eligibility and listing/lead assignment |
| `areas`, `listing_topologies` | Admin-managed community/location and topology filter references |
| `properties` + array/relation tables | First-party buy/rent inventory, area, agent, media, amenities/views |
| `off_plan_projects` + array/relation tables | Off-plan inventory, assigned broker, topology, payment/spec rows and images |
| `leads`, `leads_rels`, `leads_notification_attempts` | Enquiries, inventory references, recipient/routing and delivery-attempt history |
| `blog_posts`, `_blog_posts_v` and tag tables | Articles, draft/published version history and tags |
| `hero_slides`, `stat_cards`, `services`, `faqs`, `quick_actions`, `referral_steps`, `testimonials` | CMS marketing content |
| `page_contents`, `shared_ctas` | Shared route framing/CTA content |
| `site_settings`, `about_section`, `team_section`, `blog_section` + children | Singleton global content/settings and array rows |
| `payload_*` | Payload migrations, preferences, locks, KV and relationship internals |

The appendix lists all actual SQL tables, including children, not just collections.
Relationship FKs, deletion actions and indexes are authoritative as observed;
app-level required fields are not necessarily SQL NOT NULL, especially draft/version
records. Unique **indexes** matter even when `pg_constraint` lists no UNIQUE constraint.

### Constraints that must survive an external move

- Copy columns/types/nullability/defaults, primary/FK/check constraints, enum labels,
  unique/expression/partial/search indexes, sequences and user triggers. Do not
  flatten Payload arrays/relations or replace IDs without a mapped migration.
- `public.properties_broker_guard` and `public.off_plan_broker_guard` run before
  insert/update; source migration requires a published listing's assigned team
  member to be active, broker-tagged and have a valid email.
- `public.team_broker_guard` runs before insert/update/delete; source requires valid
  email for broker-tagged members and prevents deletion/loss of eligibility while
  published inventory still depends on the person. Reassign/unpublish deliberately.
- Trigger entrypoints are `maingate_inventory_broker_guard()` and
  `maingate_team_broker_guard()`. Definitions shown in the appendix are observed
  trigger bindings; their behavior above is from committed migration source.
  Copy the actual approved function definitions during a schema-only export,
  not guessed replacements. `migrations/20261006_151000_broker_enquiry_routing.ts`
  contains their source; do not replay its data reconciliation against unrelated IDs.
- `migrations/20261006_153200_confirmed_broker_records.ts` includes environment-specific
  operator-confirmed people/ID reconciliation. Production and development rosters
  differ; do not copy/substitute identities or treat those IDs as a new CRM roster.
- Preserve lead submission deduplication, notification attempt/history semantics,
  routing/assignment safeguards and no stale listing auto-publication.
- All inspected tables have SQL RLS disabled. Authorization lives largely in Payload
  access rules/hooks, authenticated endpoints and the guards above; direct DB access
  bypasses application authorization. Do not present absence of RLS as public access.
- Payload admin config uses `maingate-cms` cookie prefix, SameSite Lax and secure
  cookies in production. Only super-admins can create/delete accounts/change roles;
  editors can read accounts and update their own account without elevating role.
- Preserve existing hook validation/filter behavior in `collections/`, endpoint
  authorization and notification integration contract; this SQL catalog is not a
  substitute for application permission logic.
- Legacy enum labels involving holiday-home services remain in schema/history.
  They are compatibility data, not authorization to revive the retired service.

### Migration/export boundary

Use committed `migrations/index.ts` and migrations as source context; compare with
actual target catalog before applying anything. A catalog appendix is descriptive,
**not** executable restore DDL: it omits function bodies, sequence settings/current
values, grants/owners, views/policies and provider administration capabilities.
A future authorized export needs schema-only artifacts plus separately secured
data/sequence/roles/grants and storage migration plans, target-specific compatibility
review and tested restore/rollback. Do not dump data or credentials into this file.

Sharing a website DB with Twenty remains an unapproved design option. Prefer a
clearly isolated candidate until actual schema/extension/function/role ownership,
connection capacity and restore/cleanup boundaries are proven. Role creation alone
does not grant object-drop/SET privileges. Never run Twenty truncate/reset, website
seeding, post-merge or broad DROP commands as staging setup.

## 6. Twenty source/build/runtime and historical worker

### Historical baseline, not approved fork

| Item | Retained value |
| --- | --- |
| Source product | Twenty CRM, user-confirmed |
| Historical release | `v2.45.0` |
| Historical immutable commit | `7e1431c84adbb264db98ab8b8d008a8401b6d4d6` |
| CRM runtime requirement | Node `^24.5.0` (website remains Node 20) |
| Package manager | Yarn `4.13.0` |
| Current experiment pin repository | `null` |
| Current pin status | `ARCHIVED_BASELINE_REQUIRES_REBRANDED_FORK` |
| Required future input | Real approved owned fork + immutable commit and truthful license/provenance approval |

`prepare-source.sh`, `build-source.sh` and `runtime-config.mjs` deliberately fail
closed without `SOURCE_FORK_APPROVED` and a repository. Do not bypass the guard
or invent a source URL. Historical renamed package targets such as `crm-server`
are not a working upstream/fork build recipe until reconciled with approved source.

Build off the small worker; keep authoritative downloaded Git metadata outside
the workspace and verify using explicit `--git-dir` so parent website HEAD cannot
masquerade as the source commit. Disable Yarn's global mirror as well as isolate
cache; use compressed cache/bounded concurrency and avoid duplicate source trees.
Build independently matching frontend/API/worker bundles, production dependencies,
shared outputs, native ABI, assets and SDKs with commit/lockfile/artifact hashes.

### Worker host and service contract

User-supplied host: `64.177.53.107`, Vultr. `T5` is its root bootstrap password;
`T3` is the provider API key. Historical OS: Ubuntu 24.04, 1 vCPU; historical
1 GB host was upgraded one tier to 2 GB, reported as $10/month. Current size,
invoice, address attachment, services and kernel/SSH state are unverified.

Retained install tooling describes nonroot account `crm-preflight`,
`/opt/crm-preflight`, protected `/opt/crm-preflight/worker.env`,
systemd `crm-preflight-worker.service`, restart-on-failure, journal namespace,
restricted sudo and checksum-verified off-host artifact transfer.
The synthetic extension entrypoint is
`dist/queue-worker/preflight-worker.js`; native baseline worker is
`dist/queue-worker/queue-worker.js`. API uses `dist/main.js`.
Historical worker Node binary in installer: `node-v24.19.0-linux-x64`.
These are tooling expectations, **not** verification that they exist/run now.

Root/password access was bootstrap only. Production requires verified host keys,
restricted management and a nonroot worker. Tooling uses password via an anonymous
file descriptor and credentials via encrypted stdin/protected runtime config,
not command arguments/logs. Never send Replit runtime identity to the worker.
The user-owned host must not be automatically deleted by experiment cleanup.
The README reports services disabled and staging retired; “worker VM” does not mean
the Twenty worker is currently running.

### Observed historical candidate environment names

From `runtime-config.mjs`, not a complete final fork contract:

| Names | Purpose / historical setting |
| --- | --- |
| `PG_DATABASE_URL` | CRM restricted app URL; intentional migration operator URL only for fixed migration mode |
| `PG_POOL_MAX_CONNECTIONS` | `3` candidate pool limit |
| `PG_POOL_IDLE_TIMEOUT_MS`, `PG_DATABASE_PRIMARY_TIMEOUT_MS` | `30000`, `15000` |
| `PG_POOL_ALLOW_EXIT_ON_IDLE` | `true` |
| `REDIS_URL`, `REDIS_QUEUE_URL` | Dedicated TLS Redis from T4 |
| `REDIS_QUEUE_PREFIX` | Braced isolated namespace, not global/shared website keys |
| `APP_SECRET` | Separately generated CRM secret, never PAYLOAD_SECRET |
| `SERVER_URL`, `NODE_PORT` | Historical local API `http://127.0.0.1:3001`, `3001`; api2 uses `3003`; replace with approved published origin |
| `NODE_ENV`, `HOME`, `PATH` | Sealed runtime environment, production and worker-local directories/toolchain |
| `DISABLE_DB_MIGRATIONS` | `true`: startup must not run migrations |
| `IS_BILLING_ENABLED`, `TELEMETRY_ENABLED`, `IS_FDW_ENABLED`, `IS_CONFIG_VARIABLES_IN_DB_ENABLED` | `false` in synthetic experiment |
| `IS_SIGN_UP_DISABLED` | `false` in synthetic fixture, not approved public sign-up policy |
| `EMAIL_DRIVER`, `EMAIL_FROM_ADDRESS` | `logger`, synthetic invalid address; not real mail delivery |
| `LOGGER_IS_BUFFER_ENABLED` | `false` |
| `STORAGE_TYPE`, `STORAGE_LOCAL_PATH` | Temporary local **core assets only** in candidate; not persistent attachments or S3 fallback |
| `PREFLIGHT_NODE`, `PREFLIGHT_RUNTIME_NODE` | Isolated builder/runtime executable overrides in tooling |

Migration/setup, API startup and `cron:register:all` are separate fixed command
modes. Assign one migration runner and one recurring-job registrar/recovery owner;
do not use Docker's error-tolerant entrypoint as a substitute or disable schedules
to obtain a pass. Outside Replit use explicit least-privilege envs per process.

### Historical results and remaining gates

- Early build fetching hit quota; later README entries report source frontend/API/
  worker build completion. “No artifact built” is superseded as a final conclusion.
- **1 GB full baseline FAIL:** Four V8 heap OOMs, two failed native SDK jobs and
  below 20% peak host headroom. All 100 lookup jobs had one stored effect; that
  alone did not pass the full baseline or prove general exactly-once delivery.
- **2 GB bounded follow-up PASS:** No worker OOMs, no swap, 29.54% minimum headroom,
  100 lookup jobs and both native SDK-generation jobs passed. Not universal
  minimum sizing, production readiness or completed 24-hour acceptance.
- Five-user native membership/workload tooling exists; initial expired-token run
  failures and later successful renewal/recovery probe are separate. Full
  authenticated acceptance remains a gate.
- Isolated runtime used disposable Neon/T6 plus dedicated TLS Redis/T4. Published
  Autoscale, cold starts, two published instances, full scheduling recovery,
  same-ingress/path routing and shared managed DB privileges are not proven.
- Staging historically retired: services disabled, synthetic objects/roles/credentials
  cleaned, user VM retained. Billing reportedly continued; no fresh billing check.

Before launch: approved fork/legal identity; isolated chosen DB/Redis/storage and
named owners; fresh spending/TTL; published five-user auth/renewal/workspace tests;
CRUD/custom-object restart persistence; private attachments/expiry/denials; 100
stable job IDs with durable effects and retry/restart evidence; 30-minute burst;
freshly approved 24-hour idle/active soak; draining queue; at least 20% measured peak
host headroom without swap; recurring work preserved; intentional one-time migrations;
tested restore/rollback/cleanup and website/Payload regressions. Mark each result
PASS/FAIL/BLOCKED with environment; historical success does not close these gates.
Keep tests and final verification at the end of implementation.

## 7. Handoff source pointers and unavailable artifacts

Useful tracked paths, to accompany this file when handing over source:
`docs/crm-port-project-plan.md`, `payload.config.ts`, `collections/`, `globals/`,
`payload-types.ts`, `migrations/`, `lib/replit-object-storage-adapter.ts`,
`docs/enquiry-routing.md`, `.replit`, `package.json`, package lock and
`experiments/crm-preflight/README.md` plus guarded tooling.

The original plan and measured report bodies are unavailable locally. Registered
historical report sizes: feasibility 63,360 bytes; gotchas 10,276 bytes; native
storage 6,288 bytes; original plan 35,952 bytes latest / 35,689 bytes earlier.
The alternative storage report is also missing. Raw retained archive
`/tmp/crm-retained-preflight` is absent; bundles/manifests are not available.

Original plan recovery reference: output `yzQWVRAHxgb24GiFvR8m2`,
asset `174c23b3-23ef-4066-ab2f-51ef8487cbac`,
SHA-256 `2de08251637e6ce20ef91462c875c4593f201db5cc8ee082f2ab0f328c04cb0b`.
This is metadata for later comparison, not a verified accessible original.

External handoff approval checklist: approved source/access; secure credential
transfer by the owner; schema-only export/grants/function review and isolated
restore target; media object/authorization migration only if website move is in scope;
fresh resource owner/TTL/budget; routing/domain/auth policy and operator sign-off.
No secret values, user records or provider mutations were needed to prepare this file.

## 8. Complete observed development catalog

The following appendix is generated from read-only PostgreSQL catalog metadata.
It lists every observed non-system table's columns/types/nullability/defaults,
table constraints and indexes, plus enum types, installed extensions, user trigger
bindings and RLS flags. It is not a data dump or an executable restoration script.
Function bodies, ownership/grants, views, sequences' settings/current values,
policies, production parity and provider privileges need a separately authorized
export/inspection. Constraint/index names and SQL definitions are retained exactly.


### Catalog summary

Observed: **80 tables, 1260 columns, 182 table constraints, 317 indexes, 33 enum types and 3 non-internal triggers**.

| Schema | Tables | Columns | Constraints | Indexes |
| --- | ---: | ---: | ---: | ---: |
| public | 51 | 592 | 125 | 253 |
| stripe | 29 | 668 | 57 | 64 |

Extensions: `plpgsql`, `pg_trgm`.

### Enum types and accepted labels

| Schema | Type | Labels (catalog order) |
| --- | --- | --- |
| public | enum__blog_posts_v_version_category | market-insights, buying-guide, renting-guide, off-plan, legal-finance, lifestyle, company-news |
| public | enum__blog_posts_v_version_status | draft, published |
| public | enum_admins_role | super-admin, editor |
| public | enum_blog_posts_category | market-insights, buying-guide, renting-guide, off-plan, legal-finance, lifestyle, company-news |
| public | enum_blog_posts_status | draft, published |
| public | enum_faqs_category | buying, renting, off-plan, legal, general |
| public | enum_hero_slides_default_tab | buy, rent, off-plan |
| public | enum_leads_intent | Buy, Sell, Rent (long-term), Holiday home, Property management, Off-plan launch info |
| public | enum_leads_notification_attempts_result | pending, accepted, failed, unconfigured |
| public | enum_leads_notification_status | pending, accepted, failed, unconfigured |
| public | enum_leads_property_type | Apartment, Villa, Townhouse, Penthouse, Off-plan, Holiday home, Studio, Retail, Office, Warehouse, Plot, Hotel Apartment, Other |
| public | enum_leads_source_kind | general, owner, first-party, partner, legacy |
| public | enum_leads_status | New, Contacted, Qualified, Closed, Spam |
| public | enum_off_plan_projects_currency | AED, USD, GBP |
| public | enum_off_plan_projects_status | upcoming, launched, under-construction, completed |
| public | enum_properties_amenities | pool, gym, parking, security, concierge, kids-play, tennis, squash, sauna, steam, jacuzzi, bbq, beach-access, retail, metro-nearby |
| public | enum_properties_area_unit | sqft, sqm |
| public | enum_properties_completion_status | ready, under-construction, completed |
| public | enum_properties_currency | AED, USD, GBP |
| public | enum_properties_furnishing_status | furnished, unfurnished, semi-furnished |
| public | enum_properties_price_frequency | annual, monthly, total |
| public | enum_properties_property_type | apartment, villa, townhouse, penthouse, studio, retail, office, warehouse, plot, hotel-apartment |
| public | enum_properties_status | for-sale, for-rent, off-plan |
| public | enum_properties_views | sea, burj, canal, golf, city, pool, park, community |
| public | enum_shared_ctas_variant | banner, light |
| public | enum_team_members_languages | english, arabic, russian, french, hindi, chinese, urdu, other |
| public | enum_team_members_specialisations | villas, apartments, off-plan, commercial, holiday-homes, property-management |
| public | enum_testimonials_source | google, trustpilot, direct, whatsapp |
| stripe | invoice_status | draft, open, paid, uncollectible, void, deleted |
| stripe | pricing_tiers | graduated, volume |
| stripe | pricing_type | one_time, recurring |
| stripe | subscription_schedule_status | not_started, active, completed, released, canceled |
| stripe | subscription_status | trialing, active, canceled, incomplete, incomplete_expired, past_due, unpaid, paused |

### User trigger bindings

```sql
-- public.properties
CREATE TRIGGER properties_broker_guard BEFORE INSERT OR UPDATE ON properties FOR EACH ROW EXECUTE FUNCTION maingate_inventory_broker_guard();
-- public.off_plan_projects
CREATE TRIGGER off_plan_broker_guard BEFORE INSERT OR UPDATE ON off_plan_projects FOR EACH ROW EXECUTE FUNCTION maingate_inventory_broker_guard();
-- public.team_members
CREATE TRIGGER team_broker_guard BEFORE INSERT OR DELETE OR UPDATE ON team_members FOR EACH ROW EXECUTE FUNCTION maingate_team_broker_guard();
```

### Tables, columns, constraints and indexes

NOT NULL reports SQL nullability, not all Payload required-field validation. A dash in Default means no catalog default. SQL declarations below describe existing objects; do not execute them as a restore script.

#### public._blog_posts_v

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('_blog_posts_v_id_seq'::regclass) |
| parent_id | integer | no | — |
| version_title | character varying | no | — |
| version_slug | character varying | no | — |
| version_category | enum__blog_posts_v_version_category | no | — |
| version_featured_image_id | integer | no | — |
| version_summary | character varying | no | — |
| version_body | jsonb | no | — |
| version_author_id | integer | no | — |
| version_read_time_minutes | numeric | no | — |
| version_published_at | timestamp(3) with time zone | no | — |
| version_published | boolean | no | false |
| version_updated_at | timestamp(3) with time zone | no | — |
| version_created_at | timestamp(3) with time zone | no | — |
| version__status | enum__blog_posts_v_version_status | no | 'draft'::enum__blog_posts_v_version_status |
| created_at | timestamp(3) with time zone | yes | now() |
| updated_at | timestamp(3) with time zone | yes | now() |
| latest | boolean | no | — |
| version_external_image_url | character varying | no | — |
| version_external_image_alt | character varying | no | — |

Constraints:

```sql
CONSTRAINT "_blog_posts_v_parent_id_blog_posts_id_fk" FOREIGN KEY (parent_id) REFERENCES blog_posts(id) ON DELETE SET NULL
CONSTRAINT "_blog_posts_v_pkey" PRIMARY KEY (id)
CONSTRAINT "_blog_posts_v_version_author_id_team_members_id_fk" FOREIGN KEY (version_author_id) REFERENCES team_members(id) ON DELETE SET NULL
CONSTRAINT "_blog_posts_v_version_featured_image_id_media_id_fk" FOREIGN KEY (version_featured_image_id) REFERENCES media(id) ON DELETE SET NULL
```

Indexes:

```sql
CREATE INDEX _blog_posts_v_created_at_idx ON public._blog_posts_v USING btree (created_at);
CREATE INDEX _blog_posts_v_latest_idx ON public._blog_posts_v USING btree (latest);
CREATE INDEX _blog_posts_v_parent_idx ON public._blog_posts_v USING btree (parent_id);
CREATE UNIQUE INDEX _blog_posts_v_pkey ON public._blog_posts_v USING btree (id);
CREATE INDEX _blog_posts_v_updated_at_idx ON public._blog_posts_v USING btree (updated_at);
CREATE INDEX _blog_posts_v_version_version__status_idx ON public._blog_posts_v USING btree (version__status);
CREATE INDEX _blog_posts_v_version_version_author_idx ON public._blog_posts_v USING btree (version_author_id);
CREATE INDEX _blog_posts_v_version_version_created_at_idx ON public._blog_posts_v USING btree (version_created_at);
CREATE INDEX _blog_posts_v_version_version_featured_image_idx ON public._blog_posts_v USING btree (version_featured_image_id);
CREATE INDEX _blog_posts_v_version_version_slug_idx ON public._blog_posts_v USING btree (version_slug);
CREATE INDEX _blog_posts_v_version_version_updated_at_idx ON public._blog_posts_v USING btree (version_updated_at);
```

#### public._blog_posts_v_version_tags

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | integer | yes | nextval('_blog_posts_v_version_tags_id_seq'::regclass) |
| tag | character varying | no | — |
| _uuid | character varying | no | — |

Constraints:

```sql
CONSTRAINT "_blog_posts_v_version_tags_parent_id_fk" FOREIGN KEY (_parent_id) REFERENCES _blog_posts_v(id) ON DELETE CASCADE
CONSTRAINT "_blog_posts_v_version_tags_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX _blog_posts_v_version_tags_order_idx ON public._blog_posts_v_version_tags USING btree (_order);
CREATE INDEX _blog_posts_v_version_tags_parent_id_idx ON public._blog_posts_v_version_tags USING btree (_parent_id);
CREATE UNIQUE INDEX _blog_posts_v_version_tags_pkey ON public._blog_posts_v_version_tags USING btree (id);
```

#### public.about_section

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('about_section_id_seq'::regclass) |
| image_id | integer | no | — |
| external_image_url | character varying | no | — |
| image_alt | character varying | yes | — |
| badge | character varying | yes | — |
| eyebrow | character varying | yes | — |
| heading_line1 | character varying | yes | — |
| heading_line2 | character varying | yes | — |
| body_primary | character varying | yes | — |
| body_secondary | character varying | yes | — |
| cta_label | character varying | yes | — |
| cta_href | character varying | yes | — |
| updated_at | timestamp(3) with time zone | no | — |
| created_at | timestamp(3) with time zone | no | — |

Constraints:

```sql
CONSTRAINT "about_section_image_id_media_id_fk" FOREIGN KEY (image_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "about_section_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX about_section_image_idx ON public.about_section USING btree (image_id);
CREATE UNIQUE INDEX about_section_pkey ON public.about_section USING btree (id);
```

#### public.about_section_signatures

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | character varying | yes | — |
| name | character varying | yes | — |
| role | character varying | yes | — |

Constraints:

```sql
CONSTRAINT "about_section_signatures_parent_id_fk" FOREIGN KEY (_parent_id) REFERENCES about_section(id) ON DELETE CASCADE
CONSTRAINT "about_section_signatures_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX about_section_signatures_order_idx ON public.about_section_signatures USING btree (_order);
CREATE INDEX about_section_signatures_parent_id_idx ON public.about_section_signatures USING btree (_parent_id);
CREATE UNIQUE INDEX about_section_signatures_pkey ON public.about_section_signatures USING btree (id);
```

#### public.admins

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('admins_id_seq'::regclass) |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |
| email | character varying | yes | — |
| reset_password_token | character varying | no | — |
| reset_password_expiration | timestamp(3) with time zone | no | — |
| salt | character varying | no | — |
| hash | character varying | no | — |
| login_attempts | numeric | no | 0 |
| lock_until | timestamp(3) with time zone | no | — |
| role | enum_admins_role | yes | 'editor'::enum_admins_role |

Constraints:

```sql
CONSTRAINT "admins_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX admins_created_at_idx ON public.admins USING btree (created_at);
CREATE UNIQUE INDEX admins_email_idx ON public.admins USING btree (email);
CREATE UNIQUE INDEX admins_pkey ON public.admins USING btree (id);
CREATE INDEX admins_updated_at_idx ON public.admins USING btree (updated_at);
```

#### public.admins_sessions

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | character varying | yes | — |
| created_at | timestamp(3) with time zone | no | — |
| expires_at | timestamp(3) with time zone | yes | — |

Constraints:

```sql
CONSTRAINT "admins_sessions_parent_id_fk" FOREIGN KEY (_parent_id) REFERENCES admins(id) ON DELETE CASCADE
CONSTRAINT "admins_sessions_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX admins_sessions_order_idx ON public.admins_sessions USING btree (_order);
CREATE INDEX admins_sessions_parent_id_idx ON public.admins_sessions USING btree (_parent_id);
CREATE UNIQUE INDEX admins_sessions_pkey ON public.admins_sessions USING btree (id);
```

#### public.areas

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('areas_id_seq'::regclass) |
| name | character varying | yes | — |
| slug | character varying | yes | — |
| district_label | character varying | no | — |
| cover_image_id | integer | no | — |
| short_count | character varying | no | — |
| description | jsonb | no | — |
| gps_lat | numeric | no | — |
| gps_lng | numeric | no | — |
| map_zoom_level | numeric | no | — |
| order | numeric | no | 0 |
| active | boolean | no | true |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |
| external_image_url | character varying | no | — |
| external_image_alt | character varying | no | — |

Constraints:

```sql
CONSTRAINT "areas_cover_image_id_media_id_fk" FOREIGN KEY (cover_image_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "areas_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX areas_cover_image_idx ON public.areas USING btree (cover_image_id);
CREATE INDEX areas_created_at_idx ON public.areas USING btree (created_at);
CREATE UNIQUE INDEX areas_pkey ON public.areas USING btree (id);
CREATE UNIQUE INDEX areas_slug_idx ON public.areas USING btree (slug);
CREATE INDEX areas_updated_at_idx ON public.areas USING btree (updated_at);
```

#### public.blog_posts

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('blog_posts_id_seq'::regclass) |
| title | character varying | no | — |
| slug | character varying | no | — |
| category | enum_blog_posts_category | no | — |
| featured_image_id | integer | no | — |
| summary | character varying | no | — |
| body | jsonb | no | — |
| author_id | integer | no | — |
| read_time_minutes | numeric | no | — |
| published_at | timestamp(3) with time zone | no | — |
| published | boolean | no | false |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |
| _status | enum_blog_posts_status | no | 'draft'::enum_blog_posts_status |
| external_image_url | character varying | no | — |
| external_image_alt | character varying | no | — |

Constraints:

```sql
CONSTRAINT "blog_posts_author_id_team_members_id_fk" FOREIGN KEY (author_id) REFERENCES team_members(id) ON DELETE SET NULL
CONSTRAINT "blog_posts_featured_image_id_media_id_fk" FOREIGN KEY (featured_image_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "blog_posts_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX blog_posts__status_idx ON public.blog_posts USING btree (_status);
CREATE INDEX blog_posts_author_idx ON public.blog_posts USING btree (author_id);
CREATE INDEX blog_posts_created_at_idx ON public.blog_posts USING btree (created_at);
CREATE INDEX blog_posts_featured_image_idx ON public.blog_posts USING btree (featured_image_id);
CREATE UNIQUE INDEX blog_posts_pkey ON public.blog_posts USING btree (id);
CREATE UNIQUE INDEX blog_posts_slug_idx ON public.blog_posts USING btree (slug);
CREATE INDEX blog_posts_updated_at_idx ON public.blog_posts USING btree (updated_at);
```

#### public.blog_posts_tags

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | character varying | yes | — |
| tag | character varying | no | — |

Constraints:

```sql
CONSTRAINT "blog_posts_tags_parent_id_fk" FOREIGN KEY (_parent_id) REFERENCES blog_posts(id) ON DELETE CASCADE
CONSTRAINT "blog_posts_tags_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX blog_posts_tags_order_idx ON public.blog_posts_tags USING btree (_order);
CREATE INDEX blog_posts_tags_parent_id_idx ON public.blog_posts_tags USING btree (_parent_id);
CREATE UNIQUE INDEX blog_posts_tags_pkey ON public.blog_posts_tags USING btree (id);
```

#### public.blog_section

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('blog_section_id_seq'::regclass) |
| home_eyebrow | character varying | yes | — |
| home_title | character varying | yes | — |
| home_description | character varying | yes | — |
| home_read_all_label | character varying | yes | — |
| directory_eyebrow | character varying | yes | — |
| directory_title | character varying | yes | — |
| directory_description | character varying | yes | — |
| directory_all_articles_label | character varying | yes | — |
| directory_count_suffix_singular | character varying | yes | — |
| directory_count_suffix_plural | character varying | yes | — |
| detail_back_label | character varying | yes | — |
| detail_aside_eyebrow | character varying | yes | — |
| detail_advisor_cta_label | character varying | yes | — |
| empty_title | character varying | yes | — |
| empty_body | character varying | yes | — |
| empty_cta_label | character varying | yes | — |
| updated_at | timestamp(3) with time zone | no | — |
| created_at | timestamp(3) with time zone | no | — |

Constraints:

```sql
CONSTRAINT "blog_section_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX blog_section_pkey ON public.blog_section USING btree (id);
```

#### public.faqs

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('faqs_id_seq'::regclass) |
| question | character varying | yes | — |
| answer | jsonb | yes | — |
| category | enum_faqs_category | no | 'general'::enum_faqs_category |
| order | numeric | yes | 0 |
| active | boolean | no | true |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "faqs_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX faqs_created_at_idx ON public.faqs USING btree (created_at);
CREATE UNIQUE INDEX faqs_pkey ON public.faqs USING btree (id);
CREATE INDEX faqs_updated_at_idx ON public.faqs USING btree (updated_at);
```

#### public.hero_slides

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('hero_slides_id_seq'::regclass) |
| background_image_id | integer | no | — |
| alt_text | character varying | yes | — |
| heading_override | character varying | no | — |
| default_tab | enum_hero_slides_default_tab | yes | 'buy'::enum_hero_slides_default_tab |
| caption | character varying | no | — |
| cta_label | character varying | no | — |
| cta_href | character varying | no | — |
| order | numeric | yes | 0 |
| active | boolean | no | true |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |
| external_image_url | character varying | no | — |

Constraints:

```sql
CONSTRAINT "hero_slides_background_image_id_media_id_fk" FOREIGN KEY (background_image_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "hero_slides_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX hero_slides_background_image_idx ON public.hero_slides USING btree (background_image_id);
CREATE INDEX hero_slides_created_at_idx ON public.hero_slides USING btree (created_at);
CREATE UNIQUE INDEX hero_slides_pkey ON public.hero_slides USING btree (id);
CREATE INDEX hero_slides_updated_at_idx ON public.hero_slides USING btree (updated_at);
```

#### public.leads

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('leads_id_seq'::regclass) |
| full_name | character varying | yes | — |
| phone | character varying | yes | — |
| email | character varying | yes | — |
| property_type | enum_leads_property_type | yes | — |
| intent | enum_leads_intent | yes | — |
| message | character varying | no | — |
| property_ref_id | integer | no | — |
| source_page | character varying | no | — |
| utm_source | character varying | no | — |
| utm_medium | character varying | no | — |
| utm_campaign | character varying | no | — |
| status | enum_leads_status | no | 'New'::enum_leads_status |
| assigned_to_id | integer | no | — |
| follow_up_date | timestamp(3) with time zone | no | — |
| private_notes | character varying | no | — |
| ip_address | character varying | no | — |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |
| project_ref_id | integer | no | — |
| listing_title | character varying | no | — |
| listing_reference | character varying | no | — |
| assigned_operator | character varying | no | — |
| source_kind | enum_leads_source_kind | no | — |
| needs_assignment | boolean | no | — |
| partner_context | character varying | no | — |
| recipient_email | character varying | no | — |
| submission_key | character varying | no | — |
| submission_fingerprint | character varying | no | — |
| notification_status | enum_leads_notification_status | no | — |
| notification_started_at | timestamp(3) with time zone | no | — |

Constraints:

```sql
CONSTRAINT "leads_assigned_to_id_team_members_id_fk" FOREIGN KEY (assigned_to_id) REFERENCES team_members(id) ON DELETE SET NULL
CONSTRAINT "leads_pkey" PRIMARY KEY (id)
CONSTRAINT "leads_project_ref_id_fkey" FOREIGN KEY (project_ref_id) REFERENCES off_plan_projects(id) ON DELETE SET NULL
CONSTRAINT "leads_property_ref_id_properties_id_fk" FOREIGN KEY (property_ref_id) REFERENCES properties(id) ON DELETE SET NULL
```

Indexes:

```sql
CREATE INDEX leads_assigned_to_idx ON public.leads USING btree (assigned_to_id);
CREATE INDEX leads_created_at_idx ON public.leads USING btree (created_at);
CREATE INDEX leads_needs_assignment_idx ON public.leads USING btree (needs_assignment);
CREATE INDEX leads_notification_status_idx ON public.leads USING btree (notification_status);
CREATE UNIQUE INDEX leads_pkey ON public.leads USING btree (id);
CREATE INDEX leads_project_ref_idx ON public.leads USING btree (project_ref_id);
CREATE INDEX leads_property_ref_idx ON public.leads USING btree (property_ref_id);
CREATE INDEX leads_source_kind_idx ON public.leads USING btree (source_kind);
CREATE UNIQUE INDEX leads_submission_key_idx ON public.leads USING btree (submission_key);
CREATE INDEX leads_updated_at_idx ON public.leads USING btree (updated_at);
```

#### public.leads_notification_attempts

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | character varying | yes | — |
| attempted_at | timestamp(3) with time zone | yes | — |
| recipient | character varying | no | — |
| result | enum_leads_notification_attempts_result | yes | — |
| provider_i_d | character varying | no | — |
| http_status | numeric | no | — |
| error | character varying | no | — |

Constraints:

```sql
CONSTRAINT "leads_notification_attempts__parent_id_fkey" FOREIGN KEY (_parent_id) REFERENCES leads(id) ON DELETE CASCADE
CONSTRAINT "leads_notification_attempts_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX leads_notification_attempts_order_idx ON public.leads_notification_attempts USING btree (_order);
CREATE INDEX leads_notification_attempts_parent_id_idx ON public.leads_notification_attempts USING btree (_parent_id);
CREATE UNIQUE INDEX leads_notification_attempts_pkey ON public.leads_notification_attempts USING btree (id);
```

#### public.leads_rels

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('leads_rels_id_seq'::regclass) |
| order | integer | no | — |
| parent_id | integer | yes | — |
| path | character varying | yes | — |
| property_submission_photos_id | integer | no | — |

Constraints:

```sql
CONSTRAINT "leads_rels_parent_fk" FOREIGN KEY (parent_id) REFERENCES leads(id) ON DELETE CASCADE
CONSTRAINT "leads_rels_pkey" PRIMARY KEY (id)
CONSTRAINT "leads_rels_property_submission_photos_fk" FOREIGN KEY (property_submission_photos_id) REFERENCES property_submission_photos(id) ON DELETE CASCADE
```

Indexes:

```sql
CREATE INDEX leads_rels_order_idx ON public.leads_rels USING btree ("order");
CREATE INDEX leads_rels_parent_idx ON public.leads_rels USING btree (parent_id);
CREATE INDEX leads_rels_path_idx ON public.leads_rels USING btree (path);
CREATE UNIQUE INDEX leads_rels_pkey ON public.leads_rels USING btree (id);
CREATE INDEX leads_rels_property_submission_photos_id_idx ON public.leads_rels USING btree (property_submission_photos_id);
```

#### public.listing_topologies

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('listing_topologies_id_seq'::regclass) |
| label | character varying | yes | — |
| slug | character varying | yes | — |
| bedrooms | numeric | yes | — |
| order | numeric | no | 0 |
| active | boolean | no | true |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "listing_topologies_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX listing_topologies_bedrooms_idx ON public.listing_topologies USING btree (bedrooms);
CREATE INDEX listing_topologies_created_at_idx ON public.listing_topologies USING btree (created_at);
CREATE UNIQUE INDEX listing_topologies_pkey ON public.listing_topologies USING btree (id);
CREATE UNIQUE INDEX listing_topologies_slug_idx ON public.listing_topologies USING btree (slug);
CREATE INDEX listing_topologies_updated_at_idx ON public.listing_topologies USING btree (updated_at);
```

#### public.media

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('media_id_seq'::regclass) |
| alt | character varying | yes | — |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |
| url | character varying | no | — |
| thumbnail_u_r_l | character varying | no | — |
| filename | character varying | no | — |
| mime_type | character varying | no | — |
| filesize | numeric | no | — |
| width | numeric | no | — |
| height | numeric | no | — |
| focal_x | numeric | no | — |
| focal_y | numeric | no | — |
| caption | character varying | no | — |
| sizes_thumb_url | character varying | no | — |
| sizes_thumb_width | numeric | no | — |
| sizes_thumb_height | numeric | no | — |
| sizes_thumb_mime_type | character varying | no | — |
| sizes_thumb_filesize | numeric | no | — |
| sizes_thumb_filename | character varying | no | — |
| sizes_card_url | character varying | no | — |
| sizes_card_width | numeric | no | — |
| sizes_card_height | numeric | no | — |
| sizes_card_mime_type | character varying | no | — |
| sizes_card_filesize | numeric | no | — |
| sizes_card_filename | character varying | no | — |
| sizes_hero_url | character varying | no | — |
| sizes_hero_width | numeric | no | — |
| sizes_hero_height | numeric | no | — |
| sizes_hero_mime_type | character varying | no | — |
| sizes_hero_filesize | numeric | no | — |
| sizes_hero_filename | character varying | no | — |
| prefix | character varying | no | 'maingate_prod_v2/media'::character varying |

Constraints:

```sql
CONSTRAINT "media_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX media_created_at_idx ON public.media USING btree (created_at);
CREATE UNIQUE INDEX media_filename_idx ON public.media USING btree (filename);
CREATE UNIQUE INDEX media_pkey ON public.media USING btree (id);
CREATE INDEX media_sizes_card_sizes_card_filename_idx ON public.media USING btree (sizes_card_filename);
CREATE INDEX media_sizes_hero_sizes_hero_filename_idx ON public.media USING btree (sizes_hero_filename);
CREATE INDEX media_sizes_thumb_sizes_thumb_filename_idx ON public.media USING btree (sizes_thumb_filename);
CREATE INDEX media_updated_at_idx ON public.media USING btree (updated_at);
```

#### public.off_plan_projects

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('off_plan_projects_id_seq'::regclass) |
| title | character varying | yes | — |
| slug | character varying | no | — |
| developer_name | character varying | yes | — |
| developer_logo_id | integer | no | — |
| status | enum_off_plan_projects_status | yes | — |
| featured_image_id | integer | no | — |
| brochure_p_d_f_id | integer | no | — |
| area_id | integer | no | — |
| address | character varying | no | — |
| gps_lat | numeric | no | — |
| gps_lng | numeric | no | — |
| lede | character varying | no | — |
| description | jsonb | no | — |
| starting_price | numeric | no | — |
| currency | enum_off_plan_projects_currency | no | 'AED'::enum_off_plan_projects_currency |
| price_on_application | boolean | no | false |
| handover_date | timestamp(3) with time zone | no | — |
| handover_quarter | character varying | no | — |
| cta_label | character varying | no | — |
| featured | boolean | no | false |
| published | boolean | no | false |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |
| project_type | character varying | no | — |
| master_community | character varying | no | — |
| nearby_landmarks | character varying | no | — |
| total_units | numeric | no | — |
| completion_percentage | numeric | no | — |
| estimated_roi | numeric | no | — |
| service_charge_per_sqft | numeric | no | — |
| dld_project_number | character varying | no | — |
| rera_registration_number | character varying | no | — |
| payment_plan_summary | character varying | no | — |
| launch_date | timestamp(3) with time zone | no | — |
| brochure_url | character varying | no | — |
| sync_source | character varying | no | 'manual'::character varying |
| last_synced_at | timestamp(3) with time zone | no | — |
| external_project_id | character varying | no | — |
| developer_external_id | character varying | no | — |
| developer_logo_url | character varying | no | — |
| min_unit_area_sqft | numeric | no | — |
| max_unit_area_sqft | numeric | no | — |
| developer_name_normalized | character varying | yes | — |
| agent_id | integer | no | — |
| routing_issue | character varying | no | — |

Constraints:

```sql
CONSTRAINT "off_plan_projects_agent_id_fkey" FOREIGN KEY (agent_id) REFERENCES team_members(id) ON DELETE SET NULL
CONSTRAINT "off_plan_projects_area_id_areas_id_fk" FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE SET NULL
CONSTRAINT "off_plan_projects_brochure_p_d_f_id_media_id_fk" FOREIGN KEY (brochure_p_d_f_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "off_plan_projects_developer_logo_id_media_id_fk" FOREIGN KEY (developer_logo_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "off_plan_projects_featured_image_id_media_id_fk" FOREIGN KEY (featured_image_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "off_plan_projects_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX off_plan_projects_agent_idx ON public.off_plan_projects USING btree (agent_id);
CREATE INDEX off_plan_projects_area_idx ON public.off_plan_projects USING btree (area_id);
CREATE INDEX off_plan_projects_brochure_p_d_f_idx ON public.off_plan_projects USING btree (brochure_p_d_f_id);
CREATE INDEX off_plan_projects_created_at_idx ON public.off_plan_projects USING btree (created_at);
CREATE INDEX off_plan_projects_developer_logo_idx ON public.off_plan_projects USING btree (developer_logo_id);
CREATE UNIQUE INDEX off_plan_projects_external_project_id_idx ON public.off_plan_projects USING btree (external_project_id) WHERE (external_project_id IS NOT NULL);
CREATE INDEX off_plan_projects_featured_image_idx ON public.off_plan_projects USING btree (featured_image_id);
CREATE UNIQUE INDEX off_plan_projects_pkey ON public.off_plan_projects USING btree (id);
CREATE INDEX off_plan_projects_public_area_idx ON public.off_plan_projects USING btree (area_id, created_at DESC) WHERE (published = true);
CREATE INDEX off_plan_projects_public_developer_key_idx ON public.off_plan_projects USING btree (developer_name_normalized, created_at DESC) WHERE (published = true);
CREATE INDEX off_plan_projects_public_developer_normalized_idx ON public.off_plan_projects USING btree (lower(regexp_replace(btrim((developer_name)::text), '\s+'::text, ' '::text, 'g'::text)), created_at DESC) WHERE (published = true);
CREATE INDEX off_plan_projects_public_filter_idx ON public.off_plan_projects USING btree (area_id, starting_price, min_unit_area_sqft, max_unit_area_sqft, created_at DESC) WHERE (published = true);
CREATE INDEX off_plan_projects_public_price_idx ON public.off_plan_projects USING btree (starting_price, created_at DESC) WHERE (published = true);
CREATE INDEX off_plan_projects_public_project_type_idx ON public.off_plan_projects USING btree (project_type, created_at DESC) WHERE (published = true);
CREATE INDEX off_plan_projects_public_size_max_idx ON public.off_plan_projects USING btree (max_unit_area_sqft, created_at DESC) WHERE (published = true);
CREATE INDEX off_plan_projects_public_size_min_idx ON public.off_plan_projects USING btree (min_unit_area_sqft, created_at DESC) WHERE (published = true);
CREATE UNIQUE INDEX off_plan_projects_slug_idx ON public.off_plan_projects USING btree (slug);
CREATE INDEX off_plan_projects_updated_at_idx ON public.off_plan_projects USING btree (updated_at);
```

#### public.off_plan_projects_payment_plan_rows

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | character varying | yes | — |
| milestone | character varying | yes | — |
| percentage | numeric | yes | — |
| timing | character varying | no | — |

Constraints:

```sql
CONSTRAINT "off_plan_projects_payment_plan_rows_parent_id_fk" FOREIGN KEY (_parent_id) REFERENCES off_plan_projects(id) ON DELETE CASCADE
CONSTRAINT "off_plan_projects_payment_plan_rows_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX off_plan_projects_payment_plan_rows_order_idx ON public.off_plan_projects_payment_plan_rows USING btree (_order);
CREATE INDEX off_plan_projects_payment_plan_rows_parent_id_idx ON public.off_plan_projects_payment_plan_rows USING btree (_parent_id);
CREATE UNIQUE INDEX off_plan_projects_payment_plan_rows_pkey ON public.off_plan_projects_payment_plan_rows USING btree (id);
```

#### public.off_plan_projects_rels

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('off_plan_projects_rels_id_seq'::regclass) |
| order | integer | no | — |
| parent_id | integer | yes | — |
| path | character varying | yes | — |
| media_id | integer | no | — |
| listing_topologies_id | integer | no | — |

Constraints:

```sql
CONSTRAINT "off_plan_projects_rels_listing_topologies_fk" FOREIGN KEY (listing_topologies_id) REFERENCES listing_topologies(id) ON DELETE CASCADE
CONSTRAINT "off_plan_projects_rels_media_fk" FOREIGN KEY (media_id) REFERENCES media(id) ON DELETE CASCADE
CONSTRAINT "off_plan_projects_rels_parent_fk" FOREIGN KEY (parent_id) REFERENCES off_plan_projects(id) ON DELETE CASCADE
CONSTRAINT "off_plan_projects_rels_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX off_plan_projects_public_topology_idx ON public.off_plan_projects_rels USING btree (listing_topologies_id, parent_id) WHERE ((path)::text = 'topologies'::text);
CREATE INDEX off_plan_projects_rels_listing_topologies_id_idx ON public.off_plan_projects_rels USING btree (listing_topologies_id);
CREATE INDEX off_plan_projects_rels_media_id_idx ON public.off_plan_projects_rels USING btree (media_id);
CREATE INDEX off_plan_projects_rels_order_idx ON public.off_plan_projects_rels USING btree ("order");
CREATE INDEX off_plan_projects_rels_parent_idx ON public.off_plan_projects_rels USING btree (parent_id);
CREATE INDEX off_plan_projects_rels_path_idx ON public.off_plan_projects_rels USING btree (path);
CREATE UNIQUE INDEX off_plan_projects_rels_pkey ON public.off_plan_projects_rels USING btree (id);
```

#### public.off_plan_projects_spec_rows

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | character varying | yes | — |
| label | character varying | yes | — |
| value | character varying | yes | — |

Constraints:

```sql
CONSTRAINT "off_plan_projects_spec_rows_parent_id_fk" FOREIGN KEY (_parent_id) REFERENCES off_plan_projects(id) ON DELETE CASCADE
CONSTRAINT "off_plan_projects_spec_rows_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX off_plan_projects_spec_rows_order_idx ON public.off_plan_projects_spec_rows USING btree (_order);
CREATE INDEX off_plan_projects_spec_rows_parent_id_idx ON public.off_plan_projects_spec_rows USING btree (_parent_id);
CREATE UNIQUE INDEX off_plan_projects_spec_rows_pkey ON public.off_plan_projects_spec_rows USING btree (id);
```

#### public.page_contents

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('page_contents_id_seq'::regclass) |
| slug | character varying | yes | — |
| title | character varying | yes | — |
| h1 | character varying | yes | — |
| h2 | character varying | yes | — |
| published | boolean | no | true |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "page_contents_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX page_contents_created_at_idx ON public.page_contents USING btree (created_at);
CREATE UNIQUE INDEX page_contents_pkey ON public.page_contents USING btree (id);
CREATE UNIQUE INDEX page_contents_slug_idx ON public.page_contents USING btree (slug);
CREATE INDEX page_contents_updated_at_idx ON public.page_contents USING btree (updated_at);
```

#### public.page_contents_rels

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('page_contents_rels_id_seq'::regclass) |
| order | integer | no | — |
| parent_id | integer | yes | — |
| path | character varying | yes | — |
| shared_ctas_id | integer | no | — |

Constraints:

```sql
CONSTRAINT "page_contents_rels_parent_fk" FOREIGN KEY (parent_id) REFERENCES page_contents(id) ON DELETE CASCADE
CONSTRAINT "page_contents_rels_pkey" PRIMARY KEY (id)
CONSTRAINT "page_contents_rels_shared_ctas_fk" FOREIGN KEY (shared_ctas_id) REFERENCES shared_ctas(id) ON DELETE CASCADE
```

Indexes:

```sql
CREATE INDEX page_contents_rels_order_idx ON public.page_contents_rels USING btree ("order");
CREATE INDEX page_contents_rels_parent_idx ON public.page_contents_rels USING btree (parent_id);
CREATE INDEX page_contents_rels_path_idx ON public.page_contents_rels USING btree (path);
CREATE UNIQUE INDEX page_contents_rels_pkey ON public.page_contents_rels USING btree (id);
CREATE INDEX page_contents_rels_shared_ctas_id_idx ON public.page_contents_rels USING btree (shared_ctas_id);
```

#### public.payload_kv

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('payload_kv_id_seq'::regclass) |
| key | character varying | yes | — |
| data | jsonb | yes | — |

Constraints:

```sql
CONSTRAINT "payload_kv_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX payload_kv_key_idx ON public.payload_kv USING btree (key);
CREATE UNIQUE INDEX payload_kv_pkey ON public.payload_kv USING btree (id);
```

#### public.payload_locked_documents

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('payload_locked_documents_id_seq'::regclass) |
| global_slug | character varying | no | — |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "payload_locked_documents_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX payload_locked_documents_created_at_idx ON public.payload_locked_documents USING btree (created_at);
CREATE INDEX payload_locked_documents_global_slug_idx ON public.payload_locked_documents USING btree (global_slug);
CREATE UNIQUE INDEX payload_locked_documents_pkey ON public.payload_locked_documents USING btree (id);
CREATE INDEX payload_locked_documents_updated_at_idx ON public.payload_locked_documents USING btree (updated_at);
```

#### public.payload_locked_documents_rels

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('payload_locked_documents_rels_id_seq'::regclass) |
| order | integer | no | — |
| parent_id | integer | yes | — |
| path | character varying | yes | — |
| admins_id | integer | no | — |
| media_id | integer | no | — |
| blog_posts_id | integer | no | — |
| team_members_id | integer | no | — |
| areas_id | integer | no | — |
| testimonials_id | integer | no | — |
| hero_slides_id | integer | no | — |
| stat_cards_id | integer | no | — |
| services_id | integer | no | — |
| faqs_id | integer | no | — |
| quick_actions_id | integer | no | — |
| referral_steps_id | integer | no | — |
| properties_id | integer | no | — |
| off_plan_projects_id | integer | no | — |
| leads_id | integer | no | — |
| property_submission_photos_id | integer | no | — |
| listing_topologies_id | integer | no | — |
| shared_ctas_id | integer | no | — |
| page_contents_id | integer | no | — |

Constraints:

```sql
CONSTRAINT "payload_locked_documents_rels_admins_fk" FOREIGN KEY (admins_id) REFERENCES admins(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_areas_fk" FOREIGN KEY (areas_id) REFERENCES areas(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_blog_posts_fk" FOREIGN KEY (blog_posts_id) REFERENCES blog_posts(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_faqs_fk" FOREIGN KEY (faqs_id) REFERENCES faqs(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_hero_slides_fk" FOREIGN KEY (hero_slides_id) REFERENCES hero_slides(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_leads_fk" FOREIGN KEY (leads_id) REFERENCES leads(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_listing_topologies_fk" FOREIGN KEY (listing_topologies_id) REFERENCES listing_topologies(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_media_fk" FOREIGN KEY (media_id) REFERENCES media(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_off_plan_projects_fk" FOREIGN KEY (off_plan_projects_id) REFERENCES off_plan_projects(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_page_contents_fk" FOREIGN KEY (page_contents_id) REFERENCES page_contents(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_parent_fk" FOREIGN KEY (parent_id) REFERENCES payload_locked_documents(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_pkey" PRIMARY KEY (id)
CONSTRAINT "payload_locked_documents_rels_properties_fk" FOREIGN KEY (properties_id) REFERENCES properties(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_property_submission_photos_fk" FOREIGN KEY (property_submission_photos_id) REFERENCES property_submission_photos(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_quick_actions_fk" FOREIGN KEY (quick_actions_id) REFERENCES quick_actions(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_referral_steps_fk" FOREIGN KEY (referral_steps_id) REFERENCES referral_steps(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_services_fk" FOREIGN KEY (services_id) REFERENCES services(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_shared_ctas_fk" FOREIGN KEY (shared_ctas_id) REFERENCES shared_ctas(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_stat_cards_fk" FOREIGN KEY (stat_cards_id) REFERENCES stat_cards(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_team_members_fk" FOREIGN KEY (team_members_id) REFERENCES team_members(id) ON DELETE CASCADE
CONSTRAINT "payload_locked_documents_rels_testimonials_fk" FOREIGN KEY (testimonials_id) REFERENCES testimonials(id) ON DELETE CASCADE
```

Indexes:

```sql
CREATE INDEX payload_locked_documents_rels_admins_id_idx ON public.payload_locked_documents_rels USING btree (admins_id);
CREATE INDEX payload_locked_documents_rels_areas_id_idx ON public.payload_locked_documents_rels USING btree (areas_id);
CREATE INDEX payload_locked_documents_rels_blog_posts_id_idx ON public.payload_locked_documents_rels USING btree (blog_posts_id);
CREATE INDEX payload_locked_documents_rels_faqs_id_idx ON public.payload_locked_documents_rels USING btree (faqs_id);
CREATE INDEX payload_locked_documents_rels_hero_slides_id_idx ON public.payload_locked_documents_rels USING btree (hero_slides_id);
CREATE INDEX payload_locked_documents_rels_leads_id_idx ON public.payload_locked_documents_rels USING btree (leads_id);
CREATE INDEX payload_locked_documents_rels_listing_topologies_id_idx ON public.payload_locked_documents_rels USING btree (listing_topologies_id);
CREATE INDEX payload_locked_documents_rels_media_id_idx ON public.payload_locked_documents_rels USING btree (media_id);
CREATE INDEX payload_locked_documents_rels_off_plan_projects_id_idx ON public.payload_locked_documents_rels USING btree (off_plan_projects_id);
CREATE INDEX payload_locked_documents_rels_order_idx ON public.payload_locked_documents_rels USING btree ("order");
CREATE INDEX payload_locked_documents_rels_page_contents_id_idx ON public.payload_locked_documents_rels USING btree (page_contents_id);
CREATE INDEX payload_locked_documents_rels_parent_idx ON public.payload_locked_documents_rels USING btree (parent_id);
CREATE INDEX payload_locked_documents_rels_path_idx ON public.payload_locked_documents_rels USING btree (path);
CREATE UNIQUE INDEX payload_locked_documents_rels_pkey ON public.payload_locked_documents_rels USING btree (id);
CREATE INDEX payload_locked_documents_rels_properties_id_idx ON public.payload_locked_documents_rels USING btree (properties_id);
CREATE INDEX payload_locked_documents_rels_property_submission_photos_idx ON public.payload_locked_documents_rels USING btree (property_submission_photos_id);
CREATE INDEX payload_locked_documents_rels_quick_actions_id_idx ON public.payload_locked_documents_rels USING btree (quick_actions_id);
CREATE INDEX payload_locked_documents_rels_referral_steps_id_idx ON public.payload_locked_documents_rels USING btree (referral_steps_id);
CREATE INDEX payload_locked_documents_rels_services_id_idx ON public.payload_locked_documents_rels USING btree (services_id);
CREATE INDEX payload_locked_documents_rels_shared_ctas_id_idx ON public.payload_locked_documents_rels USING btree (shared_ctas_id);
CREATE INDEX payload_locked_documents_rels_stat_cards_id_idx ON public.payload_locked_documents_rels USING btree (stat_cards_id);
CREATE INDEX payload_locked_documents_rels_team_members_id_idx ON public.payload_locked_documents_rels USING btree (team_members_id);
CREATE INDEX payload_locked_documents_rels_testimonials_id_idx ON public.payload_locked_documents_rels USING btree (testimonials_id);
```

#### public.payload_migrations

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('payload_migrations_id_seq'::regclass) |
| name | character varying | no | — |
| batch | numeric | no | — |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "payload_migrations_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX payload_migrations_created_at_idx ON public.payload_migrations USING btree (created_at);
CREATE UNIQUE INDEX payload_migrations_pkey ON public.payload_migrations USING btree (id);
CREATE INDEX payload_migrations_updated_at_idx ON public.payload_migrations USING btree (updated_at);
```

#### public.payload_preferences

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('payload_preferences_id_seq'::regclass) |
| key | character varying | no | — |
| value | jsonb | no | — |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "payload_preferences_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX payload_preferences_created_at_idx ON public.payload_preferences USING btree (created_at);
CREATE INDEX payload_preferences_key_idx ON public.payload_preferences USING btree (key);
CREATE UNIQUE INDEX payload_preferences_pkey ON public.payload_preferences USING btree (id);
CREATE INDEX payload_preferences_updated_at_idx ON public.payload_preferences USING btree (updated_at);
```

#### public.payload_preferences_rels

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('payload_preferences_rels_id_seq'::regclass) |
| order | integer | no | — |
| parent_id | integer | yes | — |
| path | character varying | yes | — |
| admins_id | integer | no | — |

Constraints:

```sql
CONSTRAINT "payload_preferences_rels_admins_fk" FOREIGN KEY (admins_id) REFERENCES admins(id) ON DELETE CASCADE
CONSTRAINT "payload_preferences_rels_parent_fk" FOREIGN KEY (parent_id) REFERENCES payload_preferences(id) ON DELETE CASCADE
CONSTRAINT "payload_preferences_rels_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX payload_preferences_rels_admins_id_idx ON public.payload_preferences_rels USING btree (admins_id);
CREATE INDEX payload_preferences_rels_order_idx ON public.payload_preferences_rels USING btree ("order");
CREATE INDEX payload_preferences_rels_parent_idx ON public.payload_preferences_rels USING btree (parent_id);
CREATE INDEX payload_preferences_rels_path_idx ON public.payload_preferences_rels USING btree (path);
CREATE UNIQUE INDEX payload_preferences_rels_pkey ON public.payload_preferences_rels USING btree (id);
```

#### public.properties

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('properties_id_seq'::regclass) |
| reference_number | character varying | yes | — |
| title | character varying | yes | — |
| slug | character varying | no | — |
| status | enum_properties_status | yes | — |
| price | numeric | no | — |
| currency | enum_properties_currency | no | 'AED'::enum_properties_currency |
| price_frequency | enum_properties_price_frequency | no | 'total'::enum_properties_price_frequency |
| service_charge | numeric | no | — |
| price_on_application | boolean | no | false |
| property_type | enum_properties_property_type | yes | — |
| bedrooms | numeric | no | — |
| bathrooms | numeric | no | — |
| total_area | numeric | no | — |
| area_unit | enum_properties_area_unit | no | 'sqft'::enum_properties_area_unit |
| plot_area | numeric | no | — |
| floor | numeric | no | — |
| total_floors | numeric | no | — |
| furnishing_status | enum_properties_furnishing_status | no | — |
| area_id | integer | no | — |
| community | character varying | no | — |
| building | character varying | no | — |
| unit_number | character varying | no | — |
| district | character varying | no | — |
| address | character varying | no | — |
| gps_lat | numeric | no | — |
| gps_lng | numeric | no | — |
| google_maps_url | character varying | no | — |
| featured_image_id | integer | no | — |
| floor_plan_image_id | integer | no | — |
| video_tour_url | character varying | no | — |
| description | jsonb | no | — |
| completion_status | enum_properties_completion_status | no | — |
| handover_date | timestamp(3) with time zone | no | — |
| dld_permit_number | character varying | no | — |
| rera_number | character varying | no | — |
| title_deed_number | character varying | no | — |
| agent_id | integer | no | — |
| developer | character varying | no | — |
| meta_title | character varying | no | — |
| meta_description | character varying | no | — |
| featured | boolean | no | false |
| published | boolean | no | false |
| published_at | timestamp(3) with time zone | no | — |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |
| external_image_url | character varying | no | — |
| external_image_alt | character varying | no | — |
| listing_status_label | character varying | no | — |
| beds_display | character varying | no | — |
| sqft_display | character varying | no | — |
| total_area_sqft | numeric | no | — |
| routing_issue | character varying | no | — |

Constraints:

```sql
CONSTRAINT "properties_agent_id_team_members_id_fk" FOREIGN KEY (agent_id) REFERENCES team_members(id) ON DELETE SET NULL
CONSTRAINT "properties_area_id_areas_id_fk" FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE SET NULL
CONSTRAINT "properties_featured_image_id_media_id_fk" FOREIGN KEY (featured_image_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "properties_floor_plan_image_id_media_id_fk" FOREIGN KEY (floor_plan_image_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "properties_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX properties_agent_idx ON public.properties USING btree (agent_id);
CREATE INDEX properties_area_idx ON public.properties USING btree (area_id);
CREATE INDEX properties_created_at_idx ON public.properties USING btree (created_at);
CREATE INDEX properties_featured_image_idx ON public.properties USING btree (featured_image_id);
CREATE INDEX properties_floor_plan_image_idx ON public.properties USING btree (floor_plan_image_id);
CREATE UNIQUE INDEX properties_pkey ON public.properties USING btree (id);
CREATE INDEX properties_public_area_idx ON public.properties USING btree (area_id, status, price, published_at DESC) WHERE (published = true);
CREATE INDEX properties_public_bedrooms_idx ON public.properties USING btree (status, bedrooms, published_at DESC) WHERE (published = true);
CREATE INDEX properties_public_building_trgm_idx ON public.properties USING gin (building gin_trgm_ops) WHERE (published = true);
CREATE INDEX properties_public_community_trgm_idx ON public.properties USING gin (community gin_trgm_ops) WHERE (published = true);
CREATE INDEX properties_public_district_trgm_idx ON public.properties USING gin (district gin_trgm_ops) WHERE (published = true);
CREATE INDEX properties_public_filter_idx ON public.properties USING btree (status, property_type, bedrooms, price) WHERE (published = true);
CREATE INDEX properties_public_market_idx ON public.properties USING btree (status, published_at DESC) WHERE (published = true);
CREATE INDEX properties_public_price_idx ON public.properties USING btree (status, price, published_at DESC) WHERE (published = true);
CREATE INDEX properties_public_size_filter_idx ON public.properties USING btree (status, total_area_sqft, price, published_at DESC) WHERE (published = true);
CREATE INDEX properties_public_size_idx ON public.properties USING btree (status, total_area_sqft, published_at DESC) WHERE (published = true);
CREATE INDEX properties_public_title_trgm_idx ON public.properties USING gin (title gin_trgm_ops) WHERE (published = true);
CREATE UNIQUE INDEX properties_reference_number_idx ON public.properties USING btree (reference_number);
CREATE UNIQUE INDEX properties_slug_idx ON public.properties USING btree (slug);
CREATE INDEX properties_total_area_sqft_idx ON public.properties USING btree (total_area_sqft);
CREATE INDEX properties_updated_at_idx ON public.properties USING btree (updated_at);
```

#### public.properties_amenities

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| order | integer | yes | — |
| parent_id | integer | yes | — |
| value | enum_properties_amenities | no | — |
| id | integer | yes | nextval('properties_amenities_id_seq'::regclass) |

Constraints:

```sql
CONSTRAINT "properties_amenities_parent_fk" FOREIGN KEY (parent_id) REFERENCES properties(id) ON DELETE CASCADE
CONSTRAINT "properties_amenities_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX properties_amenities_order_idx ON public.properties_amenities USING btree ("order");
CREATE INDEX properties_amenities_parent_idx ON public.properties_amenities USING btree (parent_id);
CREATE UNIQUE INDEX properties_amenities_pkey ON public.properties_amenities USING btree (id);
```

#### public.properties_highlights

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | character varying | yes | — |
| text | character varying | yes | — |

Constraints:

```sql
CONSTRAINT "properties_highlights_parent_id_fk" FOREIGN KEY (_parent_id) REFERENCES properties(id) ON DELETE CASCADE
CONSTRAINT "properties_highlights_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX properties_highlights_order_idx ON public.properties_highlights USING btree (_order);
CREATE INDEX properties_highlights_parent_id_idx ON public.properties_highlights USING btree (_parent_id);
CREATE UNIQUE INDEX properties_highlights_pkey ON public.properties_highlights USING btree (id);
```

#### public.properties_rels

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('properties_rels_id_seq'::regclass) |
| order | integer | no | — |
| parent_id | integer | yes | — |
| path | character varying | yes | — |
| media_id | integer | no | — |

Constraints:

```sql
CONSTRAINT "properties_rels_media_fk" FOREIGN KEY (media_id) REFERENCES media(id) ON DELETE CASCADE
CONSTRAINT "properties_rels_parent_fk" FOREIGN KEY (parent_id) REFERENCES properties(id) ON DELETE CASCADE
CONSTRAINT "properties_rels_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX properties_rels_media_id_idx ON public.properties_rels USING btree (media_id);
CREATE INDEX properties_rels_order_idx ON public.properties_rels USING btree ("order");
CREATE INDEX properties_rels_parent_idx ON public.properties_rels USING btree (parent_id);
CREATE INDEX properties_rels_path_idx ON public.properties_rels USING btree (path);
CREATE UNIQUE INDEX properties_rels_pkey ON public.properties_rels USING btree (id);
```

#### public.properties_views

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| order | integer | yes | — |
| parent_id | integer | yes | — |
| value | enum_properties_views | no | — |
| id | integer | yes | nextval('properties_views_id_seq'::regclass) |

Constraints:

```sql
CONSTRAINT "properties_views_parent_fk" FOREIGN KEY (parent_id) REFERENCES properties(id) ON DELETE CASCADE
CONSTRAINT "properties_views_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX properties_views_order_idx ON public.properties_views USING btree ("order");
CREATE INDEX properties_views_parent_idx ON public.properties_views USING btree (parent_id);
CREATE UNIQUE INDEX properties_views_pkey ON public.properties_views USING btree (id);
```

#### public.property_submission_photos

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('property_submission_photos_id_seq'::regclass) |
| alt | character varying | yes | — |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |
| url | character varying | no | — |
| thumbnail_u_r_l | character varying | no | — |
| filename | character varying | no | — |
| mime_type | character varying | no | — |
| filesize | numeric | no | — |
| width | numeric | no | — |
| height | numeric | no | — |
| focal_x | numeric | no | — |
| focal_y | numeric | no | — |
| sizes_review_url | character varying | no | — |
| sizes_review_width | numeric | no | — |
| sizes_review_height | numeric | no | — |
| sizes_review_mime_type | character varying | no | — |
| sizes_review_filesize | numeric | no | — |
| sizes_review_filename | character varying | no | — |

Constraints:

```sql
CONSTRAINT "property_submission_photos_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX property_submission_photos_created_at_idx ON public.property_submission_photos USING btree (created_at);
CREATE UNIQUE INDEX property_submission_photos_filename_idx ON public.property_submission_photos USING btree (filename);
CREATE UNIQUE INDEX property_submission_photos_pkey ON public.property_submission_photos USING btree (id);
CREATE INDEX property_submission_photos_sizes_review_sizes_review_fil_idx ON public.property_submission_photos USING btree (sizes_review_filename);
CREATE INDEX property_submission_photos_updated_at_idx ON public.property_submission_photos USING btree (updated_at);
```

#### public.quick_actions

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('quick_actions_id_seq'::regclass) |
| icon | character varying | yes | — |
| label | character varying | yes | — |
| href | character varying | yes | — |
| order | numeric | yes | 0 |
| active | boolean | no | true |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "quick_actions_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX quick_actions_created_at_idx ON public.quick_actions USING btree (created_at);
CREATE UNIQUE INDEX quick_actions_pkey ON public.quick_actions USING btree (id);
CREATE INDEX quick_actions_updated_at_idx ON public.quick_actions USING btree (updated_at);
```

#### public.referral_steps

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('referral_steps_id_seq'::regclass) |
| step_number | numeric | yes | — |
| title | character varying | yes | — |
| description | character varying | yes | — |
| order | numeric | yes | 0 |
| active | boolean | no | true |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "referral_steps_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX referral_steps_created_at_idx ON public.referral_steps USING btree (created_at);
CREATE UNIQUE INDEX referral_steps_pkey ON public.referral_steps USING btree (id);
CREATE INDEX referral_steps_updated_at_idx ON public.referral_steps USING btree (updated_at);
```

#### public.services

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('services_id_seq'::regclass) |
| icon | character varying | yes | — |
| title | character varying | yes | — |
| description | character varying | yes | — |
| order | numeric | yes | 0 |
| active | boolean | no | true |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "services_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX services_created_at_idx ON public.services USING btree (created_at);
CREATE UNIQUE INDEX services_pkey ON public.services USING btree (id);
CREATE INDEX services_updated_at_idx ON public.services USING btree (updated_at);
```

#### public.shared_ctas

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('shared_ctas_id_seq'::regclass) |
| name | character varying | yes | — |
| heading | character varying | yes | — |
| subheading | character varying | yes | — |
| button_label | character varying | yes | — |
| button_href | character varying | yes | — |
| variant | enum_shared_ctas_variant | no | 'banner'::enum_shared_ctas_variant |
| active | boolean | no | true |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "shared_ctas_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX shared_ctas_created_at_idx ON public.shared_ctas USING btree (created_at);
CREATE UNIQUE INDEX shared_ctas_pkey ON public.shared_ctas USING btree (id);
CREATE INDEX shared_ctas_updated_at_idx ON public.shared_ctas USING btree (updated_at);
```

#### public.site_settings

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('site_settings_id_seq'::regclass) |
| brand_name | character varying | yes | — |
| brand_tagline | character varying | no | — |
| brand_registration_number | character varying | no | — |
| brand_rera_number | character varying | no | — |
| brand_dre_number | character varying | no | — |
| contact_phone_display | character varying | no | — |
| contact_phone_href | character varying | no | — |
| contact_whatsapp_display | character varying | no | — |
| contact_whatsapp_href | character varying | no | — |
| contact_email | character varying | no | — |
| contact_office_address | character varying | no | — |
| contact_opening_hours | character varying | no | — |
| social_instagram_url | character varying | no | — |
| social_linkedin_url | character varying | no | — |
| social_youtube_url | character varying | no | — |
| social_facebook_url | character varying | no | — |
| social_twitter_url | character varying | no | — |
| seo_default_meta_title | character varying | no | — |
| seo_default_meta_description | character varying | no | — |
| seo_og_image_id | integer | no | — |
| seo_twitter_handle | character varying | no | — |
| notification_banner_banner_text | jsonb | no | — |
| notification_banner_banner_active | boolean | no | false |
| notification_banner_banner_link_label | character varying | no | — |
| notification_banner_banner_link_href | character varying | no | — |
| footer_footer_tagline | character varying | no | — |
| footer_copyright_text | character varying | no | — |
| updated_at | timestamp(3) with time zone | no | — |
| created_at | timestamp(3) with time zone | no | — |
| integrations_new_lead_webhook_url | character varying | no | — |
| integrations_lead_notification_recipients | character varying | no | — |
| integrations_general_enquiry_email | character varying | no | 'josephine.c@maingate.ae'::character varying |
| integrations_enquiry_cms_base_url | character varying | no | 'https://www.maingate.ae'::character varying |

Constraints:

```sql
CONSTRAINT "site_settings_pkey" PRIMARY KEY (id)
CONSTRAINT "site_settings_seo_og_image_id_media_id_fk" FOREIGN KEY (seo_og_image_id) REFERENCES media(id) ON DELETE SET NULL
```

Indexes:

```sql
CREATE UNIQUE INDEX site_settings_pkey ON public.site_settings USING btree (id);
CREATE INDEX site_settings_seo_seo_og_image_idx ON public.site_settings USING btree (seo_og_image_id);
```

#### public.site_settings_marketing_scripts_footer_scripts

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | character varying | yes | — |
| script | character varying | yes | — |

Constraints:

```sql
CONSTRAINT "site_settings_marketing_scripts_footer_scripts_parent_id_fk" FOREIGN KEY (_parent_id) REFERENCES site_settings(id) ON DELETE CASCADE
CONSTRAINT "site_settings_marketing_scripts_footer_scripts_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX site_settings_marketing_scripts_footer_scripts_order_idx ON public.site_settings_marketing_scripts_footer_scripts USING btree (_order);
CREATE INDEX site_settings_marketing_scripts_footer_scripts_parent_id_idx ON public.site_settings_marketing_scripts_footer_scripts USING btree (_parent_id);
CREATE UNIQUE INDEX site_settings_marketing_scripts_footer_scripts_pkey ON public.site_settings_marketing_scripts_footer_scripts USING btree (id);
```

#### public.site_settings_marketing_scripts_head_scripts

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | character varying | yes | — |
| script | character varying | yes | — |

Constraints:

```sql
CONSTRAINT "site_settings_marketing_scripts_head_scripts_parent_id_fk" FOREIGN KEY (_parent_id) REFERENCES site_settings(id) ON DELETE CASCADE
CONSTRAINT "site_settings_marketing_scripts_head_scripts_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX site_settings_marketing_scripts_head_scripts_order_idx ON public.site_settings_marketing_scripts_head_scripts USING btree (_order);
CREATE INDEX site_settings_marketing_scripts_head_scripts_parent_id_idx ON public.site_settings_marketing_scripts_head_scripts USING btree (_parent_id);
CREATE UNIQUE INDEX site_settings_marketing_scripts_head_scripts_pkey ON public.site_settings_marketing_scripts_head_scripts USING btree (id);
```

#### public.stat_cards

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('stat_cards_id_seq'::regclass) |
| display_number | character varying | yes | — |
| label | character varying | yes | — |
| description | character varying | no | — |
| icon | character varying | no | — |
| order | numeric | yes | 0 |
| active | boolean | no | true |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "stat_cards_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX stat_cards_created_at_idx ON public.stat_cards USING btree (created_at);
CREATE UNIQUE INDEX stat_cards_pkey ON public.stat_cards USING btree (id);
CREATE INDEX stat_cards_updated_at_idx ON public.stat_cards USING btree (updated_at);
```

#### public.team_members

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('team_members_id_seq'::regclass) |
| name | character varying | yes | — |
| slug | character varying | yes | — |
| role | character varying | no | — |
| photo_id | integer | no | — |
| bio | jsonb | no | — |
| email | character varying | no | — |
| phone | character varying | no | — |
| whatsapp_number | character varying | no | — |
| rera_number | character varying | no | — |
| dld_certified | boolean | no | false |
| orera_number | character varying | no | — |
| years_experience | numeric | no | — |
| deals_closed_count | numeric | no | — |
| transaction_volume | character varying | no | — |
| google_rating | numeric | no | — |
| review_count | numeric | no | — |
| linkedin_url | character varying | no | — |
| instagram_url | character varying | no | — |
| featured | boolean | no | false |
| order | numeric | no | 0 |
| active | boolean | no | true |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |
| image_alignment | character varying | no | 'center'::character varying |
| is_broker | boolean | no | false |

Constraints:

```sql
CONSTRAINT "team_members_photo_id_media_id_fk" FOREIGN KEY (photo_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "team_members_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX team_members_created_at_idx ON public.team_members USING btree (created_at);
CREATE INDEX team_members_is_broker_idx ON public.team_members USING btree (is_broker);
CREATE INDEX team_members_photo_idx ON public.team_members USING btree (photo_id);
CREATE UNIQUE INDEX team_members_pkey ON public.team_members USING btree (id);
CREATE UNIQUE INDEX team_members_slug_idx ON public.team_members USING btree (slug);
CREATE INDEX team_members_updated_at_idx ON public.team_members USING btree (updated_at);
```

#### public.team_members_languages

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| order | integer | yes | — |
| parent_id | integer | yes | — |
| value | enum_team_members_languages | no | — |
| id | integer | yes | nextval('team_members_languages_id_seq'::regclass) |

Constraints:

```sql
CONSTRAINT "team_members_languages_parent_fk" FOREIGN KEY (parent_id) REFERENCES team_members(id) ON DELETE CASCADE
CONSTRAINT "team_members_languages_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX team_members_languages_order_idx ON public.team_members_languages USING btree ("order");
CREATE INDEX team_members_languages_parent_idx ON public.team_members_languages USING btree (parent_id);
CREATE UNIQUE INDEX team_members_languages_pkey ON public.team_members_languages USING btree (id);
```

#### public.team_members_rels

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('team_members_rels_id_seq'::regclass) |
| order | integer | no | — |
| parent_id | integer | yes | — |
| path | character varying | yes | — |
| areas_id | integer | no | — |

Constraints:

```sql
CONSTRAINT "team_members_rels_areas_fk" FOREIGN KEY (areas_id) REFERENCES areas(id) ON DELETE CASCADE
CONSTRAINT "team_members_rels_parent_fk" FOREIGN KEY (parent_id) REFERENCES team_members(id) ON DELETE CASCADE
CONSTRAINT "team_members_rels_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX team_members_rels_areas_id_idx ON public.team_members_rels USING btree (areas_id);
CREATE INDEX team_members_rels_order_idx ON public.team_members_rels USING btree ("order");
CREATE INDEX team_members_rels_parent_idx ON public.team_members_rels USING btree (parent_id);
CREATE INDEX team_members_rels_path_idx ON public.team_members_rels USING btree (path);
CREATE UNIQUE INDEX team_members_rels_pkey ON public.team_members_rels USING btree (id);
```

#### public.team_members_specialisations

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| order | integer | yes | — |
| parent_id | integer | yes | — |
| value | enum_team_members_specialisations | no | — |
| id | integer | yes | nextval('team_members_specialisations_id_seq'::regclass) |

Constraints:

```sql
CONSTRAINT "team_members_specialisations_parent_fk" FOREIGN KEY (parent_id) REFERENCES team_members(id) ON DELETE CASCADE
CONSTRAINT "team_members_specialisations_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX team_members_specialisations_order_idx ON public.team_members_specialisations USING btree ("order");
CREATE INDEX team_members_specialisations_parent_idx ON public.team_members_specialisations USING btree (parent_id);
CREATE UNIQUE INDEX team_members_specialisations_pkey ON public.team_members_specialisations USING btree (id);
```

#### public.team_section

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('team_section_id_seq'::regclass) |
| image_id | integer | no | — |
| external_image_url | character varying | no | — |
| image_alt | character varying | yes | — |
| image_badge | character varying | no | — |
| eyebrow | character varying | yes | — |
| heading_line1 | character varying | yes | — |
| heading_line2 | character varying | yes | — |
| body | character varying | yes | — |
| cta_label | character varying | yes | — |
| cta_href | character varying | yes | — |
| updated_at | timestamp(3) with time zone | no | — |
| created_at | timestamp(3) with time zone | no | — |

Constraints:

```sql
CONSTRAINT "team_section_image_id_media_id_fk" FOREIGN KEY (image_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "team_section_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX team_section_image_idx ON public.team_section USING btree (image_id);
CREATE UNIQUE INDEX team_section_pkey ON public.team_section USING btree (id);
```

#### public.team_section_badges

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | character varying | yes | — |
| label | character varying | yes | — |

Constraints:

```sql
CONSTRAINT "team_section_badges_parent_id_fk" FOREIGN KEY (_parent_id) REFERENCES team_section(id) ON DELETE CASCADE
CONSTRAINT "team_section_badges_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX team_section_badges_order_idx ON public.team_section_badges USING btree (_order);
CREATE INDEX team_section_badges_parent_id_idx ON public.team_section_badges USING btree (_parent_id);
CREATE UNIQUE INDEX team_section_badges_pkey ON public.team_section_badges USING btree (id);
```

#### public.team_section_stats

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _order | integer | yes | — |
| _parent_id | integer | yes | — |
| id | character varying | yes | — |
| value | character varying | yes | — |
| label | character varying | yes | — |

Constraints:

```sql
CONSTRAINT "team_section_stats_parent_id_fk" FOREIGN KEY (_parent_id) REFERENCES team_section(id) ON DELETE CASCADE
CONSTRAINT "team_section_stats_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX team_section_stats_order_idx ON public.team_section_stats USING btree (_order);
CREATE INDEX team_section_stats_parent_id_idx ON public.team_section_stats USING btree (_parent_id);
CREATE UNIQUE INDEX team_section_stats_pkey ON public.team_section_stats USING btree (id);
```

#### public.testimonials

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('testimonials_id_seq'::regclass) |
| author_name | character varying | yes | — |
| author_role | character varying | no | — |
| author_company | character varying | no | — |
| author_photo_id | integer | no | — |
| quote | jsonb | yes | — |
| rating | numeric | no | — |
| transaction_date | timestamp(3) with time zone | no | — |
| agent_ref_id | integer | no | — |
| source | enum_testimonials_source | no | — |
| featured | boolean | no | false |
| published | boolean | no | false |
| updated_at | timestamp(3) with time zone | yes | now() |
| created_at | timestamp(3) with time zone | yes | now() |

Constraints:

```sql
CONSTRAINT "testimonials_agent_ref_id_team_members_id_fk" FOREIGN KEY (agent_ref_id) REFERENCES team_members(id) ON DELETE SET NULL
CONSTRAINT "testimonials_author_photo_id_media_id_fk" FOREIGN KEY (author_photo_id) REFERENCES media(id) ON DELETE SET NULL
CONSTRAINT "testimonials_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX testimonials_agent_ref_idx ON public.testimonials USING btree (agent_ref_id);
CREATE INDEX testimonials_author_photo_idx ON public.testimonials USING btree (author_photo_id);
CREATE INDEX testimonials_created_at_idx ON public.testimonials USING btree (created_at);
CREATE UNIQUE INDEX testimonials_pkey ON public.testimonials USING btree (id);
CREATE INDEX testimonials_updated_at_idx ON public.testimonials USING btree (updated_at);
```

#### stripe._managed_webhooks

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | text | yes | — |
| object | text | no | — |
| uuid | text | yes | — |
| url | text | yes | — |
| enabled_events | jsonb | yes | — |
| description | text | no | — |
| enabled | boolean | no | — |
| livemode | boolean | no | — |
| metadata | jsonb | no | — |
| secret | text | yes | — |
| status | text | no | — |
| api_version | text | no | — |
| created | integer | no | — |
| updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| last_synced_at | timestamp with time zone | no | — |
| account_id | text | yes | — |

Constraints:

```sql
CONSTRAINT "fk_managed_webhooks_account" FOREIGN KEY (account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "managed_webhooks_pkey" PRIMARY KEY (id)
CONSTRAINT "managed_webhooks_uuid_key" UNIQUE (uuid)
```

Indexes:

```sql
CREATE UNIQUE INDEX managed_webhooks_pkey ON stripe._managed_webhooks USING btree (id);
CREATE UNIQUE INDEX managed_webhooks_uuid_key ON stripe._managed_webhooks USING btree (uuid);
CREATE INDEX stripe_managed_webhooks_enabled_idx ON stripe._managed_webhooks USING btree (enabled);
CREATE INDEX stripe_managed_webhooks_status_idx ON stripe._managed_webhooks USING btree (status);
CREATE INDEX stripe_managed_webhooks_uuid_idx ON stripe._managed_webhooks USING btree (uuid);
```

#### stripe._migrations

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | — |
| name | character varying(100) | yes | — |
| hash | character varying(40) | yes | — |
| executed_at | timestamp without time zone | no | CURRENT_TIMESTAMP |

Constraints:

```sql
CONSTRAINT "_migrations_name_key" UNIQUE (name)
CONSTRAINT "_migrations_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX _migrations_name_key ON stripe._migrations USING btree (name);
CREATE UNIQUE INDEX _migrations_pkey ON stripe._migrations USING btree (id);
```

#### stripe._sync_status

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| id | integer | yes | nextval('stripe._sync_status_id_seq'::regclass) |
| resource | text | yes | — |
| status | text | no | 'idle'::text |
| last_synced_at | timestamp with time zone | no | now() |
| last_incremental_cursor | timestamp with time zone | no | — |
| error_message | text | no | — |
| updated_at | timestamp with time zone | no | now() |
| account_id | text | yes | — |

Constraints:

```sql
CONSTRAINT "_sync_status_pkey" PRIMARY KEY (id)
CONSTRAINT "_sync_status_resource_account_key" UNIQUE (resource, account_id)
CONSTRAINT "_sync_status_status_check" CHECK (status = ANY (ARRAY['idle'::text, 'running'::text, 'complete'::text, 'error'::text]))
CONSTRAINT "fk_sync_status_account" FOREIGN KEY (account_id) REFERENCES stripe.accounts(id)
```

Indexes:

```sql
CREATE UNIQUE INDEX _sync_status_pkey ON stripe._sync_status USING btree (id);
CREATE UNIQUE INDEX _sync_status_resource_account_key ON stripe._sync_status USING btree (resource, account_id);
CREATE INDEX idx_sync_status_resource_account ON stripe._sync_status USING btree (resource, account_id);
```

#### stripe.accounts

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _raw_data | jsonb | yes | — |
| first_synced_at | timestamp with time zone | yes | now() |
| _last_synced_at | timestamp with time zone | yes | now() |
| _updated_at | timestamp with time zone | yes | now() |
| business_name | text | no | ((_raw_data -> 'business_profile'::text) ->> 'name'::text) |
| email | text | no | (_raw_data ->> 'email'::text) |
| type | text | no | (_raw_data ->> 'type'::text) |
| charges_enabled | boolean | no | ((_raw_data ->> 'charges_enabled'::text))::boolean |
| payouts_enabled | boolean | no | ((_raw_data ->> 'payouts_enabled'::text))::boolean |
| details_submitted | boolean | no | ((_raw_data ->> 'details_submitted'::text))::boolean |
| country | text | no | (_raw_data ->> 'country'::text) |
| default_currency | text | no | (_raw_data ->> 'default_currency'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| api_key_hashes | text[] | no | '{}'::text[] |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "accounts_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX accounts_pkey ON stripe.accounts USING btree (id);
CREATE INDEX idx_accounts_api_key_hashes ON stripe.accounts USING gin (api_key_hashes);
CREATE INDEX idx_accounts_business_name ON stripe.accounts USING btree (business_name);
```

#### stripe.active_entitlements

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| feature | text | no | (_raw_data ->> 'feature'::text) |
| customer | text | no | (_raw_data ->> 'customer'::text) |
| lookup_key | text | no | (_raw_data ->> 'lookup_key'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "active_entitlements_pkey" PRIMARY KEY (id)
CONSTRAINT "fk_active_entitlements_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
```

Indexes:

```sql
CREATE UNIQUE INDEX active_entitlements_lookup_key_key ON stripe.active_entitlements USING btree (lookup_key) WHERE (lookup_key IS NOT NULL);
CREATE UNIQUE INDEX active_entitlements_pkey ON stripe.active_entitlements USING btree (id);
CREATE INDEX stripe_active_entitlements_customer_idx ON stripe.active_entitlements USING btree (customer);
CREATE INDEX stripe_active_entitlements_feature_idx ON stripe.active_entitlements USING btree (feature);
```

#### stripe.charges

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| paid | boolean | no | ((_raw_data ->> 'paid'::text))::boolean |
| order | text | no | (_raw_data ->> 'order'::text) |
| amount | bigint | no | ((_raw_data ->> 'amount'::text))::bigint |
| review | text | no | (_raw_data ->> 'review'::text) |
| source | jsonb | no | (_raw_data -> 'source'::text) |
| status | text | no | (_raw_data ->> 'status'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| dispute | text | no | (_raw_data ->> 'dispute'::text) |
| invoice | text | no | (_raw_data ->> 'invoice'::text) |
| outcome | jsonb | no | (_raw_data -> 'outcome'::text) |
| refunds | jsonb | no | (_raw_data -> 'refunds'::text) |
| updated | integer | no | ((_raw_data ->> 'updated'::text))::integer |
| captured | boolean | no | ((_raw_data ->> 'captured'::text))::boolean |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| customer | text | no | (_raw_data ->> 'customer'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| refunded | boolean | no | ((_raw_data ->> 'refunded'::text))::boolean |
| shipping | jsonb | no | (_raw_data -> 'shipping'::text) |
| application | text | no | (_raw_data ->> 'application'::text) |
| description | text | no | (_raw_data ->> 'description'::text) |
| destination | text | no | (_raw_data ->> 'destination'::text) |
| failure_code | text | no | (_raw_data ->> 'failure_code'::text) |
| on_behalf_of | text | no | (_raw_data ->> 'on_behalf_of'::text) |
| fraud_details | jsonb | no | (_raw_data -> 'fraud_details'::text) |
| receipt_email | text | no | (_raw_data ->> 'receipt_email'::text) |
| payment_intent | text | no | (_raw_data ->> 'payment_intent'::text) |
| receipt_number | text | no | (_raw_data ->> 'receipt_number'::text) |
| transfer_group | text | no | (_raw_data ->> 'transfer_group'::text) |
| amount_refunded | bigint | no | ((_raw_data ->> 'amount_refunded'::text))::bigint |
| application_fee | text | no | (_raw_data ->> 'application_fee'::text) |
| failure_message | text | no | (_raw_data ->> 'failure_message'::text) |
| source_transfer | text | no | (_raw_data ->> 'source_transfer'::text) |
| balance_transaction | text | no | (_raw_data ->> 'balance_transaction'::text) |
| statement_descriptor | text | no | (_raw_data ->> 'statement_descriptor'::text) |
| payment_method_details | jsonb | no | (_raw_data -> 'payment_method_details'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "charges_pkey" PRIMARY KEY (id)
CONSTRAINT "fk_charges_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
```

Indexes:

```sql
CREATE UNIQUE INDEX charges_pkey ON stripe.charges USING btree (id);
```

#### stripe.checkout_session_line_items

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| amount_discount | integer | no | ((_raw_data ->> 'amount_discount'::text))::integer |
| amount_subtotal | integer | no | ((_raw_data ->> 'amount_subtotal'::text))::integer |
| amount_tax | integer | no | ((_raw_data ->> 'amount_tax'::text))::integer |
| amount_total | integer | no | ((_raw_data ->> 'amount_total'::text))::integer |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| description | text | no | (_raw_data ->> 'description'::text) |
| price | text | no | (_raw_data ->> 'price'::text) |
| quantity | integer | no | ((_raw_data ->> 'quantity'::text))::integer |
| checkout_session | text | no | (_raw_data ->> 'checkout_session'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "checkout_session_line_items_pkey" PRIMARY KEY (id)
CONSTRAINT "fk_checkout_session_line_items_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
```

Indexes:

```sql
CREATE UNIQUE INDEX checkout_session_line_items_pkey ON stripe.checkout_session_line_items USING btree (id);
CREATE INDEX stripe_checkout_session_line_items_price_idx ON stripe.checkout_session_line_items USING btree (price);
CREATE INDEX stripe_checkout_session_line_items_session_idx ON stripe.checkout_session_line_items USING btree (checkout_session);
```

#### stripe.checkout_sessions

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| adaptive_pricing | jsonb | no | (_raw_data -> 'adaptive_pricing'::text) |
| after_expiration | jsonb | no | (_raw_data -> 'after_expiration'::text) |
| allow_promotion_codes | boolean | no | ((_raw_data ->> 'allow_promotion_codes'::text))::boolean |
| amount_subtotal | integer | no | ((_raw_data ->> 'amount_subtotal'::text))::integer |
| amount_total | integer | no | ((_raw_data ->> 'amount_total'::text))::integer |
| automatic_tax | jsonb | no | (_raw_data -> 'automatic_tax'::text) |
| billing_address_collection | text | no | (_raw_data ->> 'billing_address_collection'::text) |
| cancel_url | text | no | (_raw_data ->> 'cancel_url'::text) |
| client_reference_id | text | no | (_raw_data ->> 'client_reference_id'::text) |
| client_secret | text | no | (_raw_data ->> 'client_secret'::text) |
| collected_information | jsonb | no | (_raw_data -> 'collected_information'::text) |
| consent | jsonb | no | (_raw_data -> 'consent'::text) |
| consent_collection | jsonb | no | (_raw_data -> 'consent_collection'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| currency_conversion | jsonb | no | (_raw_data -> 'currency_conversion'::text) |
| custom_fields | jsonb | no | (_raw_data -> 'custom_fields'::text) |
| custom_text | jsonb | no | (_raw_data -> 'custom_text'::text) |
| customer | text | no | (_raw_data ->> 'customer'::text) |
| customer_creation | text | no | (_raw_data ->> 'customer_creation'::text) |
| customer_details | jsonb | no | (_raw_data -> 'customer_details'::text) |
| customer_email | text | no | (_raw_data ->> 'customer_email'::text) |
| discounts | jsonb | no | (_raw_data -> 'discounts'::text) |
| expires_at | integer | no | ((_raw_data ->> 'expires_at'::text))::integer |
| invoice | text | no | (_raw_data ->> 'invoice'::text) |
| invoice_creation | jsonb | no | (_raw_data -> 'invoice_creation'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| locale | text | no | (_raw_data ->> 'locale'::text) |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| mode | text | no | (_raw_data ->> 'mode'::text) |
| optional_items | jsonb | no | (_raw_data -> 'optional_items'::text) |
| payment_intent | text | no | (_raw_data ->> 'payment_intent'::text) |
| payment_link | text | no | (_raw_data ->> 'payment_link'::text) |
| payment_method_collection | text | no | (_raw_data ->> 'payment_method_collection'::text) |
| payment_method_configuration_details | jsonb | no | (_raw_data -> 'payment_method_configuration_details'::text) |
| payment_method_options | jsonb | no | (_raw_data -> 'payment_method_options'::text) |
| payment_method_types | jsonb | no | (_raw_data -> 'payment_method_types'::text) |
| payment_status | text | no | (_raw_data ->> 'payment_status'::text) |
| permissions | jsonb | no | (_raw_data -> 'permissions'::text) |
| phone_number_collection | jsonb | no | (_raw_data -> 'phone_number_collection'::text) |
| presentment_details | jsonb | no | (_raw_data -> 'presentment_details'::text) |
| recovered_from | text | no | (_raw_data ->> 'recovered_from'::text) |
| redirect_on_completion | text | no | (_raw_data ->> 'redirect_on_completion'::text) |
| return_url | text | no | (_raw_data ->> 'return_url'::text) |
| saved_payment_method_options | jsonb | no | (_raw_data -> 'saved_payment_method_options'::text) |
| setup_intent | text | no | (_raw_data ->> 'setup_intent'::text) |
| shipping_address_collection | jsonb | no | (_raw_data -> 'shipping_address_collection'::text) |
| shipping_cost | jsonb | no | (_raw_data -> 'shipping_cost'::text) |
| shipping_details | jsonb | no | (_raw_data -> 'shipping_details'::text) |
| shipping_options | jsonb | no | (_raw_data -> 'shipping_options'::text) |
| status | text | no | (_raw_data ->> 'status'::text) |
| submit_type | text | no | (_raw_data ->> 'submit_type'::text) |
| subscription | text | no | (_raw_data ->> 'subscription'::text) |
| success_url | text | no | (_raw_data ->> 'success_url'::text) |
| tax_id_collection | jsonb | no | (_raw_data -> 'tax_id_collection'::text) |
| total_details | jsonb | no | (_raw_data -> 'total_details'::text) |
| ui_mode | text | no | (_raw_data ->> 'ui_mode'::text) |
| url | text | no | (_raw_data ->> 'url'::text) |
| wallet_options | jsonb | no | (_raw_data -> 'wallet_options'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "checkout_sessions_pkey" PRIMARY KEY (id)
CONSTRAINT "fk_checkout_sessions_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
```

Indexes:

```sql
CREATE UNIQUE INDEX checkout_sessions_pkey ON stripe.checkout_sessions USING btree (id);
CREATE INDEX stripe_checkout_sessions_customer_idx ON stripe.checkout_sessions USING btree (customer);
CREATE INDEX stripe_checkout_sessions_invoice_idx ON stripe.checkout_sessions USING btree (invoice);
CREATE INDEX stripe_checkout_sessions_payment_intent_idx ON stripe.checkout_sessions USING btree (payment_intent);
CREATE INDEX stripe_checkout_sessions_subscription_idx ON stripe.checkout_sessions USING btree (subscription);
```

#### stripe.coupons

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| name | text | no | (_raw_data ->> 'name'::text) |
| valid | boolean | no | ((_raw_data ->> 'valid'::text))::boolean |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| updated | integer | no | ((_raw_data ->> 'updated'::text))::integer |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| duration | text | no | (_raw_data ->> 'duration'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| redeem_by | integer | no | ((_raw_data ->> 'redeem_by'::text))::integer |
| amount_off | bigint | no | ((_raw_data ->> 'amount_off'::text))::bigint |
| percent_off | double precision | no | ((_raw_data ->> 'percent_off'::text))::double precision |
| times_redeemed | bigint | no | ((_raw_data ->> 'times_redeemed'::text))::bigint |
| max_redemptions | bigint | no | ((_raw_data ->> 'max_redemptions'::text))::bigint |
| duration_in_months | bigint | no | ((_raw_data ->> 'duration_in_months'::text))::bigint |
| percent_off_precise | double precision | no | ((_raw_data ->> 'percent_off_precise'::text))::double precision |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "coupons_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX coupons_pkey ON stripe.coupons USING btree (id);
```

#### stripe.credit_notes

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| amount | integer | no | ((_raw_data ->> 'amount'::text))::integer |
| amount_shipping | integer | no | ((_raw_data ->> 'amount_shipping'::text))::integer |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| customer | text | no | (_raw_data ->> 'customer'::text) |
| customer_balance_transaction | text | no | (_raw_data ->> 'customer_balance_transaction'::text) |
| discount_amount | integer | no | ((_raw_data ->> 'discount_amount'::text))::integer |
| discount_amounts | jsonb | no | (_raw_data -> 'discount_amounts'::text) |
| invoice | text | no | (_raw_data ->> 'invoice'::text) |
| lines | jsonb | no | (_raw_data -> 'lines'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| memo | text | no | (_raw_data ->> 'memo'::text) |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| number | text | no | (_raw_data ->> 'number'::text) |
| out_of_band_amount | integer | no | ((_raw_data ->> 'out_of_band_amount'::text))::integer |
| pdf | text | no | (_raw_data ->> 'pdf'::text) |
| reason | text | no | (_raw_data ->> 'reason'::text) |
| refund | text | no | (_raw_data ->> 'refund'::text) |
| shipping_cost | jsonb | no | (_raw_data -> 'shipping_cost'::text) |
| status | text | no | (_raw_data ->> 'status'::text) |
| subtotal | integer | no | ((_raw_data ->> 'subtotal'::text))::integer |
| subtotal_excluding_tax | integer | no | ((_raw_data ->> 'subtotal_excluding_tax'::text))::integer |
| tax_amounts | jsonb | no | (_raw_data -> 'tax_amounts'::text) |
| total | integer | no | ((_raw_data ->> 'total'::text))::integer |
| total_excluding_tax | integer | no | ((_raw_data ->> 'total_excluding_tax'::text))::integer |
| type | text | no | (_raw_data ->> 'type'::text) |
| voided_at | text | no | (_raw_data ->> 'voided_at'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "credit_notes_pkey" PRIMARY KEY (id)
CONSTRAINT "fk_credit_notes_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
```

Indexes:

```sql
CREATE UNIQUE INDEX credit_notes_pkey ON stripe.credit_notes USING btree (id);
CREATE INDEX stripe_credit_notes_customer_idx ON stripe.credit_notes USING btree (customer);
CREATE INDEX stripe_credit_notes_invoice_idx ON stripe.credit_notes USING btree (invoice);
```

#### stripe.customers

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| address | jsonb | no | (_raw_data -> 'address'::text) |
| description | text | no | (_raw_data ->> 'description'::text) |
| email | text | no | (_raw_data ->> 'email'::text) |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| name | text | no | (_raw_data ->> 'name'::text) |
| phone | text | no | (_raw_data ->> 'phone'::text) |
| shipping | jsonb | no | (_raw_data -> 'shipping'::text) |
| balance | integer | no | ((_raw_data ->> 'balance'::text))::integer |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| default_source | text | no | (_raw_data ->> 'default_source'::text) |
| delinquent | boolean | no | ((_raw_data ->> 'delinquent'::text))::boolean |
| discount | jsonb | no | (_raw_data -> 'discount'::text) |
| invoice_prefix | text | no | (_raw_data ->> 'invoice_prefix'::text) |
| invoice_settings | jsonb | no | (_raw_data -> 'invoice_settings'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| next_invoice_sequence | integer | no | ((_raw_data ->> 'next_invoice_sequence'::text))::integer |
| preferred_locales | jsonb | no | (_raw_data -> 'preferred_locales'::text) |
| tax_exempt | text | no | (_raw_data ->> 'tax_exempt'::text) |
| deleted | boolean | no | ((_raw_data ->> 'deleted'::text))::boolean |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "customers_pkey" PRIMARY KEY (id)
CONSTRAINT "fk_customers_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
```

Indexes:

```sql
CREATE UNIQUE INDEX customers_pkey ON stripe.customers USING btree (id);
```

#### stripe.disputes

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| amount | bigint | no | ((_raw_data ->> 'amount'::text))::bigint |
| charge | text | no | (_raw_data ->> 'charge'::text) |
| reason | text | no | (_raw_data ->> 'reason'::text) |
| status | text | no | (_raw_data ->> 'status'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| updated | integer | no | ((_raw_data ->> 'updated'::text))::integer |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| evidence | jsonb | no | (_raw_data -> 'evidence'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| evidence_details | jsonb | no | (_raw_data -> 'evidence_details'::text) |
| balance_transactions | jsonb | no | (_raw_data -> 'balance_transactions'::text) |
| is_charge_refundable | boolean | no | ((_raw_data ->> 'is_charge_refundable'::text))::boolean |
| payment_intent | text | no | (_raw_data ->> 'payment_intent'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "disputes_pkey" PRIMARY KEY (id)
CONSTRAINT "fk_disputes_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
```

Indexes:

```sql
CREATE UNIQUE INDEX disputes_pkey ON stripe.disputes USING btree (id);
CREATE INDEX stripe_dispute_created_idx ON stripe.disputes USING btree (created);
```

#### stripe.early_fraud_warnings

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| actionable | boolean | no | ((_raw_data ->> 'actionable'::text))::boolean |
| charge | text | no | (_raw_data ->> 'charge'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| fraud_type | text | no | (_raw_data ->> 'fraud_type'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| payment_intent | text | no | (_raw_data ->> 'payment_intent'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "early_fraud_warnings_pkey" PRIMARY KEY (id)
CONSTRAINT "fk_early_fraud_warnings_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
```

Indexes:

```sql
CREATE UNIQUE INDEX early_fraud_warnings_pkey ON stripe.early_fraud_warnings USING btree (id);
CREATE INDEX stripe_early_fraud_warnings_charge_idx ON stripe.early_fraud_warnings USING btree (charge);
CREATE INDEX stripe_early_fraud_warnings_payment_intent_idx ON stripe.early_fraud_warnings USING btree (payment_intent);
```

#### stripe.events

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| data | jsonb | no | (_raw_data -> 'data'::text) |
| type | text | no | (_raw_data ->> 'type'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| request | text | no | (_raw_data ->> 'request'::text) |
| updated | integer | no | ((_raw_data ->> 'updated'::text))::integer |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| api_version | text | no | (_raw_data ->> 'api_version'::text) |
| pending_webhooks | bigint | no | ((_raw_data ->> 'pending_webhooks'::text))::bigint |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "events_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX events_pkey ON stripe.events USING btree (id);
```

#### stripe.features

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| name | text | no | (_raw_data ->> 'name'::text) |
| lookup_key | text | no | (_raw_data ->> 'lookup_key'::text) |
| active | boolean | no | ((_raw_data ->> 'active'::text))::boolean |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "features_pkey" PRIMARY KEY (id)
CONSTRAINT "fk_features_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
```

Indexes:

```sql
CREATE UNIQUE INDEX features_lookup_key_key ON stripe.features USING btree (lookup_key) WHERE (lookup_key IS NOT NULL);
CREATE UNIQUE INDEX features_pkey ON stripe.features USING btree (id);
```

#### stripe.invoices

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| auto_advance | boolean | no | ((_raw_data ->> 'auto_advance'::text))::boolean |
| collection_method | text | no | (_raw_data ->> 'collection_method'::text) |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| description | text | no | (_raw_data ->> 'description'::text) |
| hosted_invoice_url | text | no | (_raw_data ->> 'hosted_invoice_url'::text) |
| lines | jsonb | no | (_raw_data -> 'lines'::text) |
| period_end | integer | no | ((_raw_data ->> 'period_end'::text))::integer |
| period_start | integer | no | ((_raw_data ->> 'period_start'::text))::integer |
| status | text | no | (_raw_data ->> 'status'::text) |
| total | bigint | no | ((_raw_data ->> 'total'::text))::bigint |
| account_country | text | no | (_raw_data ->> 'account_country'::text) |
| account_name | text | no | (_raw_data ->> 'account_name'::text) |
| account_tax_ids | jsonb | no | (_raw_data -> 'account_tax_ids'::text) |
| amount_due | bigint | no | ((_raw_data ->> 'amount_due'::text))::bigint |
| amount_paid | bigint | no | ((_raw_data ->> 'amount_paid'::text))::bigint |
| amount_remaining | bigint | no | ((_raw_data ->> 'amount_remaining'::text))::bigint |
| application_fee_amount | bigint | no | ((_raw_data ->> 'application_fee_amount'::text))::bigint |
| attempt_count | integer | no | ((_raw_data ->> 'attempt_count'::text))::integer |
| attempted | boolean | no | ((_raw_data ->> 'attempted'::text))::boolean |
| billing_reason | text | no | (_raw_data ->> 'billing_reason'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| custom_fields | jsonb | no | (_raw_data -> 'custom_fields'::text) |
| customer_address | jsonb | no | (_raw_data -> 'customer_address'::text) |
| customer_email | text | no | (_raw_data ->> 'customer_email'::text) |
| customer_name | text | no | (_raw_data ->> 'customer_name'::text) |
| customer_phone | text | no | (_raw_data ->> 'customer_phone'::text) |
| customer_shipping | jsonb | no | (_raw_data -> 'customer_shipping'::text) |
| customer_tax_exempt | text | no | (_raw_data ->> 'customer_tax_exempt'::text) |
| customer_tax_ids | jsonb | no | (_raw_data -> 'customer_tax_ids'::text) |
| default_tax_rates | jsonb | no | (_raw_data -> 'default_tax_rates'::text) |
| discount | jsonb | no | (_raw_data -> 'discount'::text) |
| discounts | jsonb | no | (_raw_data -> 'discounts'::text) |
| due_date | integer | no | ((_raw_data ->> 'due_date'::text))::integer |
| ending_balance | integer | no | ((_raw_data ->> 'ending_balance'::text))::integer |
| footer | text | no | (_raw_data ->> 'footer'::text) |
| invoice_pdf | text | no | (_raw_data ->> 'invoice_pdf'::text) |
| last_finalization_error | jsonb | no | (_raw_data -> 'last_finalization_error'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| next_payment_attempt | integer | no | ((_raw_data ->> 'next_payment_attempt'::text))::integer |
| number | text | no | (_raw_data ->> 'number'::text) |
| paid | boolean | no | ((_raw_data ->> 'paid'::text))::boolean |
| payment_settings | jsonb | no | (_raw_data -> 'payment_settings'::text) |
| post_payment_credit_notes_amount | integer | no | ((_raw_data ->> 'post_payment_credit_notes_amount'::text))::integer |
| pre_payment_credit_notes_amount | integer | no | ((_raw_data ->> 'pre_payment_credit_notes_amount'::text))::integer |
| receipt_number | text | no | (_raw_data ->> 'receipt_number'::text) |
| starting_balance | integer | no | ((_raw_data ->> 'starting_balance'::text))::integer |
| statement_descriptor | text | no | (_raw_data ->> 'statement_descriptor'::text) |
| status_transitions | jsonb | no | (_raw_data -> 'status_transitions'::text) |
| subtotal | integer | no | ((_raw_data ->> 'subtotal'::text))::integer |
| tax | integer | no | ((_raw_data ->> 'tax'::text))::integer |
| total_discount_amounts | jsonb | no | (_raw_data -> 'total_discount_amounts'::text) |
| total_tax_amounts | jsonb | no | (_raw_data -> 'total_tax_amounts'::text) |
| transfer_data | jsonb | no | (_raw_data -> 'transfer_data'::text) |
| webhooks_delivered_at | integer | no | ((_raw_data ->> 'webhooks_delivered_at'::text))::integer |
| customer | text | no | (_raw_data ->> 'customer'::text) |
| subscription | text | no | (_raw_data ->> 'subscription'::text) |
| payment_intent | text | no | (_raw_data ->> 'payment_intent'::text) |
| default_payment_method | text | no | (_raw_data ->> 'default_payment_method'::text) |
| default_source | text | no | (_raw_data ->> 'default_source'::text) |
| on_behalf_of | text | no | (_raw_data ->> 'on_behalf_of'::text) |
| charge | text | no | (_raw_data ->> 'charge'::text) |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_invoices_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "invoices_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX invoices_pkey ON stripe.invoices USING btree (id);
CREATE INDEX stripe_invoices_customer_idx ON stripe.invoices USING btree (customer);
CREATE INDEX stripe_invoices_subscription_idx ON stripe.invoices USING btree (subscription);
```

#### stripe.payment_intents

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| amount | integer | no | ((_raw_data ->> 'amount'::text))::integer |
| amount_capturable | integer | no | ((_raw_data ->> 'amount_capturable'::text))::integer |
| amount_details | jsonb | no | (_raw_data -> 'amount_details'::text) |
| amount_received | integer | no | ((_raw_data ->> 'amount_received'::text))::integer |
| application | text | no | (_raw_data ->> 'application'::text) |
| application_fee_amount | integer | no | ((_raw_data ->> 'application_fee_amount'::text))::integer |
| automatic_payment_methods | text | no | (_raw_data ->> 'automatic_payment_methods'::text) |
| canceled_at | integer | no | ((_raw_data ->> 'canceled_at'::text))::integer |
| cancellation_reason | text | no | (_raw_data ->> 'cancellation_reason'::text) |
| capture_method | text | no | (_raw_data ->> 'capture_method'::text) |
| client_secret | text | no | (_raw_data ->> 'client_secret'::text) |
| confirmation_method | text | no | (_raw_data ->> 'confirmation_method'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| customer | text | no | (_raw_data ->> 'customer'::text) |
| description | text | no | (_raw_data ->> 'description'::text) |
| invoice | text | no | (_raw_data ->> 'invoice'::text) |
| last_payment_error | text | no | (_raw_data ->> 'last_payment_error'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| next_action | text | no | (_raw_data ->> 'next_action'::text) |
| on_behalf_of | text | no | (_raw_data ->> 'on_behalf_of'::text) |
| payment_method | text | no | (_raw_data ->> 'payment_method'::text) |
| payment_method_options | jsonb | no | (_raw_data -> 'payment_method_options'::text) |
| payment_method_types | jsonb | no | (_raw_data -> 'payment_method_types'::text) |
| processing | text | no | (_raw_data ->> 'processing'::text) |
| receipt_email | text | no | (_raw_data ->> 'receipt_email'::text) |
| review | text | no | (_raw_data ->> 'review'::text) |
| setup_future_usage | text | no | (_raw_data ->> 'setup_future_usage'::text) |
| shipping | jsonb | no | (_raw_data -> 'shipping'::text) |
| statement_descriptor | text | no | (_raw_data ->> 'statement_descriptor'::text) |
| statement_descriptor_suffix | text | no | (_raw_data ->> 'statement_descriptor_suffix'::text) |
| status | text | no | (_raw_data ->> 'status'::text) |
| transfer_data | jsonb | no | (_raw_data -> 'transfer_data'::text) |
| transfer_group | text | no | (_raw_data ->> 'transfer_group'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_payment_intents_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "payment_intents_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX payment_intents_pkey ON stripe.payment_intents USING btree (id);
CREATE INDEX stripe_payment_intents_customer_idx ON stripe.payment_intents USING btree (customer);
CREATE INDEX stripe_payment_intents_invoice_idx ON stripe.payment_intents USING btree (invoice);
```

#### stripe.payment_methods

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| customer | text | no | (_raw_data ->> 'customer'::text) |
| type | text | no | (_raw_data ->> 'type'::text) |
| billing_details | jsonb | no | (_raw_data -> 'billing_details'::text) |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| card | jsonb | no | (_raw_data -> 'card'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_payment_methods_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "payment_methods_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX payment_methods_pkey ON stripe.payment_methods USING btree (id);
CREATE INDEX stripe_payment_methods_customer_idx ON stripe.payment_methods USING btree (customer);
```

#### stripe.payouts

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| date | text | no | (_raw_data ->> 'date'::text) |
| type | text | no | (_raw_data ->> 'type'::text) |
| amount | bigint | no | ((_raw_data ->> 'amount'::text))::bigint |
| method | text | no | (_raw_data ->> 'method'::text) |
| status | text | no | (_raw_data ->> 'status'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| updated | integer | no | ((_raw_data ->> 'updated'::text))::integer |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| automatic | boolean | no | ((_raw_data ->> 'automatic'::text))::boolean |
| recipient | text | no | (_raw_data ->> 'recipient'::text) |
| description | text | no | (_raw_data ->> 'description'::text) |
| destination | text | no | (_raw_data ->> 'destination'::text) |
| source_type | text | no | (_raw_data ->> 'source_type'::text) |
| arrival_date | text | no | (_raw_data ->> 'arrival_date'::text) |
| bank_account | jsonb | no | (_raw_data -> 'bank_account'::text) |
| failure_code | text | no | (_raw_data ->> 'failure_code'::text) |
| transfer_group | text | no | (_raw_data ->> 'transfer_group'::text) |
| amount_reversed | bigint | no | ((_raw_data ->> 'amount_reversed'::text))::bigint |
| failure_message | text | no | (_raw_data ->> 'failure_message'::text) |
| source_transaction | text | no | (_raw_data ->> 'source_transaction'::text) |
| balance_transaction | text | no | (_raw_data ->> 'balance_transaction'::text) |
| statement_descriptor | text | no | (_raw_data ->> 'statement_descriptor'::text) |
| statement_description | text | no | (_raw_data ->> 'statement_description'::text) |
| failure_balance_transaction | text | no | (_raw_data ->> 'failure_balance_transaction'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "payouts_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX payouts_pkey ON stripe.payouts USING btree (id);
```

#### stripe.plans

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| name | text | no | (_raw_data ->> 'name'::text) |
| tiers | jsonb | no | (_raw_data -> 'tiers'::text) |
| active | boolean | no | ((_raw_data ->> 'active'::text))::boolean |
| amount | bigint | no | ((_raw_data ->> 'amount'::text))::bigint |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| product | text | no | (_raw_data ->> 'product'::text) |
| updated | integer | no | ((_raw_data ->> 'updated'::text))::integer |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| interval | text | no | (_raw_data ->> 'interval'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| nickname | text | no | (_raw_data ->> 'nickname'::text) |
| tiers_mode | text | no | (_raw_data ->> 'tiers_mode'::text) |
| usage_type | text | no | (_raw_data ->> 'usage_type'::text) |
| billing_scheme | text | no | (_raw_data ->> 'billing_scheme'::text) |
| interval_count | bigint | no | ((_raw_data ->> 'interval_count'::text))::bigint |
| aggregate_usage | text | no | (_raw_data ->> 'aggregate_usage'::text) |
| transform_usage | text | no | (_raw_data ->> 'transform_usage'::text) |
| trial_period_days | bigint | no | ((_raw_data ->> 'trial_period_days'::text))::bigint |
| statement_descriptor | text | no | (_raw_data ->> 'statement_descriptor'::text) |
| statement_description | text | no | (_raw_data ->> 'statement_description'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_plans_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "plans_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX plans_pkey ON stripe.plans USING btree (id);
```

#### stripe.prices

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| active | boolean | no | ((_raw_data ->> 'active'::text))::boolean |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| nickname | text | no | (_raw_data ->> 'nickname'::text) |
| recurring | jsonb | no | (_raw_data -> 'recurring'::text) |
| type | text | no | (_raw_data ->> 'type'::text) |
| unit_amount | integer | no | ((_raw_data ->> 'unit_amount'::text))::integer |
| billing_scheme | text | no | (_raw_data ->> 'billing_scheme'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| lookup_key | text | no | (_raw_data ->> 'lookup_key'::text) |
| tiers_mode | text | no | (_raw_data ->> 'tiers_mode'::text) |
| transform_quantity | jsonb | no | (_raw_data -> 'transform_quantity'::text) |
| unit_amount_decimal | text | no | (_raw_data ->> 'unit_amount_decimal'::text) |
| product | text | no | (_raw_data ->> 'product'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_prices_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "prices_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX prices_pkey ON stripe.prices USING btree (id);
```

#### stripe.products

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| active | boolean | no | ((_raw_data ->> 'active'::text))::boolean |
| default_price | text | no | (_raw_data ->> 'default_price'::text) |
| description | text | no | (_raw_data ->> 'description'::text) |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| name | text | no | (_raw_data ->> 'name'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| images | jsonb | no | (_raw_data -> 'images'::text) |
| marketing_features | jsonb | no | (_raw_data -> 'marketing_features'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| package_dimensions | jsonb | no | (_raw_data -> 'package_dimensions'::text) |
| shippable | boolean | no | ((_raw_data ->> 'shippable'::text))::boolean |
| statement_descriptor | text | no | (_raw_data ->> 'statement_descriptor'::text) |
| unit_label | text | no | (_raw_data ->> 'unit_label'::text) |
| updated | integer | no | ((_raw_data ->> 'updated'::text))::integer |
| url | text | no | (_raw_data ->> 'url'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_products_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "products_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX products_pkey ON stripe.products USING btree (id);
```

#### stripe.refunds

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| amount | integer | no | ((_raw_data ->> 'amount'::text))::integer |
| balance_transaction | text | no | (_raw_data ->> 'balance_transaction'::text) |
| charge | text | no | (_raw_data ->> 'charge'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| currency | text | no | (_raw_data ->> 'currency'::text) |
| destination_details | jsonb | no | (_raw_data -> 'destination_details'::text) |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| payment_intent | text | no | (_raw_data ->> 'payment_intent'::text) |
| reason | text | no | (_raw_data ->> 'reason'::text) |
| receipt_number | text | no | (_raw_data ->> 'receipt_number'::text) |
| source_transfer_reversal | text | no | (_raw_data ->> 'source_transfer_reversal'::text) |
| status | text | no | (_raw_data ->> 'status'::text) |
| transfer_reversal | text | no | (_raw_data ->> 'transfer_reversal'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_refunds_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "refunds_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX refunds_pkey ON stripe.refunds USING btree (id);
CREATE INDEX stripe_refunds_charge_idx ON stripe.refunds USING btree (charge);
CREATE INDEX stripe_refunds_payment_intent_idx ON stripe.refunds USING btree (payment_intent);
```

#### stripe.reviews

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| billing_zip | text | no | (_raw_data ->> 'billing_zip'::text) |
| charge | text | no | (_raw_data ->> 'charge'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| closed_reason | text | no | (_raw_data ->> 'closed_reason'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| ip_address | text | no | (_raw_data ->> 'ip_address'::text) |
| ip_address_location | jsonb | no | (_raw_data -> 'ip_address_location'::text) |
| open | boolean | no | ((_raw_data ->> 'open'::text))::boolean |
| opened_reason | text | no | (_raw_data ->> 'opened_reason'::text) |
| payment_intent | text | no | (_raw_data ->> 'payment_intent'::text) |
| reason | text | no | (_raw_data ->> 'reason'::text) |
| session | text | no | (_raw_data ->> 'session'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_reviews_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "reviews_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX reviews_pkey ON stripe.reviews USING btree (id);
CREATE INDEX stripe_reviews_charge_idx ON stripe.reviews USING btree (charge);
CREATE INDEX stripe_reviews_payment_intent_idx ON stripe.reviews USING btree (payment_intent);
```

#### stripe.setup_intents

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| customer | text | no | (_raw_data ->> 'customer'::text) |
| description | text | no | (_raw_data ->> 'description'::text) |
| payment_method | text | no | (_raw_data ->> 'payment_method'::text) |
| status | text | no | (_raw_data ->> 'status'::text) |
| usage | text | no | (_raw_data ->> 'usage'::text) |
| cancellation_reason | text | no | (_raw_data ->> 'cancellation_reason'::text) |
| latest_attempt | text | no | (_raw_data ->> 'latest_attempt'::text) |
| mandate | text | no | (_raw_data ->> 'mandate'::text) |
| single_use_mandate | text | no | (_raw_data ->> 'single_use_mandate'::text) |
| on_behalf_of | text | no | (_raw_data ->> 'on_behalf_of'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_setup_intents_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "setup_intents_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX setup_intents_pkey ON stripe.setup_intents USING btree (id);
CREATE INDEX stripe_setup_intents_customer_idx ON stripe.setup_intents USING btree (customer);
```

#### stripe.subscription_items

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| billing_thresholds | jsonb | no | (_raw_data -> 'billing_thresholds'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| deleted | boolean | no | ((_raw_data ->> 'deleted'::text))::boolean |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| quantity | integer | no | ((_raw_data ->> 'quantity'::text))::integer |
| price | text | no | (_raw_data ->> 'price'::text) |
| subscription | text | no | (_raw_data ->> 'subscription'::text) |
| tax_rates | jsonb | no | (_raw_data -> 'tax_rates'::text) |
| current_period_end | integer | no | ((_raw_data ->> 'current_period_end'::text))::integer |
| current_period_start | integer | no | ((_raw_data ->> 'current_period_start'::text))::integer |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_subscription_items_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "subscription_items_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX subscription_items_pkey ON stripe.subscription_items USING btree (id);
```

#### stripe.subscription_schedules

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| application | text | no | (_raw_data ->> 'application'::text) |
| canceled_at | integer | no | ((_raw_data ->> 'canceled_at'::text))::integer |
| completed_at | integer | no | ((_raw_data ->> 'completed_at'::text))::integer |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| current_phase | jsonb | no | (_raw_data -> 'current_phase'::text) |
| customer | text | no | (_raw_data ->> 'customer'::text) |
| default_settings | jsonb | no | (_raw_data -> 'default_settings'::text) |
| end_behavior | text | no | (_raw_data ->> 'end_behavior'::text) |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| phases | jsonb | no | (_raw_data -> 'phases'::text) |
| released_at | integer | no | ((_raw_data ->> 'released_at'::text))::integer |
| released_subscription | text | no | (_raw_data ->> 'released_subscription'::text) |
| status | text | no | (_raw_data ->> 'status'::text) |
| subscription | text | no | (_raw_data ->> 'subscription'::text) |
| test_clock | text | no | (_raw_data ->> 'test_clock'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_subscription_schedules_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "subscription_schedules_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX subscription_schedules_pkey ON stripe.subscription_schedules USING btree (id);
```

#### stripe.subscriptions

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _updated_at | timestamp with time zone | yes | timezone('utc'::text, now()) |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| cancel_at_period_end | boolean | no | ((_raw_data ->> 'cancel_at_period_end'::text))::boolean |
| current_period_end | integer | no | ((_raw_data ->> 'current_period_end'::text))::integer |
| current_period_start | integer | no | ((_raw_data ->> 'current_period_start'::text))::integer |
| default_payment_method | text | no | (_raw_data ->> 'default_payment_method'::text) |
| items | jsonb | no | (_raw_data -> 'items'::text) |
| metadata | jsonb | no | (_raw_data -> 'metadata'::text) |
| pending_setup_intent | text | no | (_raw_data ->> 'pending_setup_intent'::text) |
| pending_update | jsonb | no | (_raw_data -> 'pending_update'::text) |
| status | text | no | (_raw_data ->> 'status'::text) |
| application_fee_percent | double precision | no | ((_raw_data ->> 'application_fee_percent'::text))::double precision |
| billing_cycle_anchor | integer | no | ((_raw_data ->> 'billing_cycle_anchor'::text))::integer |
| billing_thresholds | jsonb | no | (_raw_data -> 'billing_thresholds'::text) |
| cancel_at | integer | no | ((_raw_data ->> 'cancel_at'::text))::integer |
| canceled_at | integer | no | ((_raw_data ->> 'canceled_at'::text))::integer |
| collection_method | text | no | (_raw_data ->> 'collection_method'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| days_until_due | integer | no | ((_raw_data ->> 'days_until_due'::text))::integer |
| default_source | text | no | (_raw_data ->> 'default_source'::text) |
| default_tax_rates | jsonb | no | (_raw_data -> 'default_tax_rates'::text) |
| discount | jsonb | no | (_raw_data -> 'discount'::text) |
| ended_at | integer | no | ((_raw_data ->> 'ended_at'::text))::integer |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| next_pending_invoice_item_invoice | integer | no | ((_raw_data ->> 'next_pending_invoice_item_invoice'::text))::integer |
| pause_collection | jsonb | no | (_raw_data -> 'pause_collection'::text) |
| pending_invoice_item_interval | jsonb | no | (_raw_data -> 'pending_invoice_item_interval'::text) |
| start_date | integer | no | ((_raw_data ->> 'start_date'::text))::integer |
| transfer_data | jsonb | no | (_raw_data -> 'transfer_data'::text) |
| trial_end | jsonb | no | (_raw_data -> 'trial_end'::text) |
| trial_start | jsonb | no | (_raw_data -> 'trial_start'::text) |
| schedule | text | no | (_raw_data ->> 'schedule'::text) |
| customer | text | no | (_raw_data ->> 'customer'::text) |
| latest_invoice | text | no | (_raw_data ->> 'latest_invoice'::text) |
| plan | text | no | (_raw_data ->> 'plan'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_subscriptions_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "subscriptions_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE UNIQUE INDEX subscriptions_pkey ON stripe.subscriptions USING btree (id);
```

#### stripe.tax_ids

RLS enabled: **false**; forced: **false**.

| Column | PostgreSQL type | NOT NULL | Default |
| --- | --- | --- | --- |
| _last_synced_at | timestamp with time zone | no | — |
| _raw_data | jsonb | no | — |
| _account_id | text | yes | — |
| object | text | no | (_raw_data ->> 'object'::text) |
| country | text | no | (_raw_data ->> 'country'::text) |
| customer | text | no | (_raw_data ->> 'customer'::text) |
| type | text | no | (_raw_data ->> 'type'::text) |
| value | text | no | (_raw_data ->> 'value'::text) |
| created | integer | no | ((_raw_data ->> 'created'::text))::integer |
| livemode | boolean | no | ((_raw_data ->> 'livemode'::text))::boolean |
| owner | jsonb | no | (_raw_data -> 'owner'::text) |
| id | text | yes | (_raw_data ->> 'id'::text) |

Constraints:

```sql
CONSTRAINT "fk_tax_ids_account" FOREIGN KEY (_account_id) REFERENCES stripe.accounts(id)
CONSTRAINT "tax_ids_pkey" PRIMARY KEY (id)
```

Indexes:

```sql
CREATE INDEX stripe_tax_ids_customer_idx ON stripe.tax_ids USING btree (customer);
CREATE UNIQUE INDEX tax_ids_pkey ON stripe.tax_ids USING btree (id);
```
