## Current checkout naming and retirement

All project-owned experiment files, folders and text use neutral CRM naming.
Raw historical source, private resource inventories and measurements are
retained separately at `/tmp/crm-retained-preflight`, mode 700, outside this
checkout. Do not commit, publish, print or treat that archive as a new staging
configuration. It is temporary local retention, not a durable backup or a
promise to erase platform history.

The former API experiment workflow is removed. The website workflow is
unchanged. Source preparation, builds and experimental application startup are
fail-closed: the baseline pin is historical, not an approved rebranded fork.
Before reactivation, supply the actual owned repository and immutable commit,
set its pin status deliberately, port the neutral package/build references to
that fork, rebuild all artifacts, and obtain fresh isolated runtime inventory.
No repository URL is invented, no private product name is substituted, and no
new source build or provider lifecycle action is implied by this cleanup.

Report identifiers/paths are neutralized presentation labels. Immutable
baseline SHA and measured outcomes are retained; original commands and logs
remain in the separate archive. They are not evidence that renamed packages
have already been built or deployed.

# CRM isolated feasibility experiment

This is **preparation tooling**, not a deployed CRM or a substitute for runtime
tests. See `.local/reports/crm-feasibility-report.md` for evidence and blockers.
It does not change the website runtime, imports, workflows, database or media.

## Reproduce read-only findings

```sh
bash experiments/crm-preflight/prepare-source.sh
node experiments/crm-preflight/inspect.mjs plans
```

Source must match `pin.json`. Authoritative Git metadata lives in `/tmp` because
workspace checkpointing can strip nested `.git`; inspected exported files are
compared with pinned Git objects. Audit results include source hashes
and bounded excerpts; no credentials are read. Catalog lookup uses a public GET,
not the Vultr account API, and never provisions a VM.

Check public plan availability again at provisioning time. `ewr` and `atl`
are catalog locations, not proof of capacity or account eligibility.

## Approval gate

The user approved $10 total for 48 hours, New Jersey, a 24-hour soak and
separate staging publication, then requested starting at $2.50 and stepping up
one memory tier as needed, with VM backups disabled. Approval does not supply
the isolated database, Redis, storage or staging publication access.

Before installs/deployments, record the approved staging project, independent
logical database, Redis instance, storage bucket/namespace, VM region, spending
cap, duration, soak permission, resource owner and expiration. Do not interpret
a Git branch as proof of database isolation. All provider-dependent writes are
blocked until dedicated resources and their identities have been confirmed.

Credentials belong in the staging project's Secrets: dedicated
`CRM_PREFLIGHT_DATABASE_URL`, `CRM_PREFLIGHT_REDIS_URL` (Redis TLS, not REST),
Vultr token (`T3` is the user-provided workspace secret), and dedicated S3
access/secret keys. Never fall
back to this website's `DATABASE_URL`, bucket or AWS keys. Generate a separate
CRM application secret and synthetic user passwords securely there.
Do not copy Replit runtime identity to the worker host.

Keep the private resource inventory in ignored
`generated-artifacts/crm-preflight/private/`, permissions 0700/0600, with
provider IDs, owner, created time, TTL, cleanup state and approval reference.
Do not store credentials in that inventory.

## Source build recipe — NOT executed

Use a separate adequately sized builder with Node satisfying `^24.5.0`; do not
change this website's Node 20 module. In the pinned source checkout:

```sh
# Bundled pinned Yarn; upstream disables dependency scripts by default.
node .yarn/releases/yarn-4.13.0.cjs install --immutable
node .yarn/releases/yarn-4.13.0.cjs nx build crm-server
node .yarn/releases/yarn-4.13.0.cjs nx build crm-front
```

These targets include buildable dependency targets. Check the pinned Dockerfile
as a packaging reference, not an image dependency. Artifact assembly must include
production workspace dependencies, shared workspace dist outputs, native modules
for the VM's ABI, assets and client SDK. A copied `dist` directory alone is not
a self-contained worker. Produce independent frontend/API/worker bundles with a
SHA-256 manifest, identical source commit and lockfile hash. The API and worker
share compiled server code but have separate entrypoints:

```sh
# From each packaged crm-server directory, after packaging is VERIFIED:
node dist/main.js
node dist/queue-worker/queue-worker.js
```

No actual artifact has been built: dependency fetching hit a filesystem quota
both with the original cache and in a separate `/tmp` builder/cache.
`build-source.sh` reproduces the isolated attempt using `PREFLIGHT_NODE`.
Neither launch command must wrap Docker's entrypoint:
that entrypoint performs upgrades and cron registration and tolerates some failures.

## Database gate

`database-metadata.sql` is read-only but must still be directed explicitly at
the approved disposable staging logical database; no convenience wrapper supplies
the website URL. Do not run `database:reset`, truncate-db, post-merge, media
validation or website seeding as setup.

Inspect every bootstrap/upgrade command before execution. A dedicated migration
runner should use CRM's `database:init:prod` (which invokes instance commands)
and `command:prod upgrade` only after shared-public-object ownership and failure
handling have been reviewed. This recipe is **not authorized or certified safe**
for a shared provider. The upstream setup script catches errors, so a zero exit
is insufficient: assert schemas, extensions, helper function and migration state.
Keep Payload in `public`. Run actual synthetic Payload migrations from an isolated
config with no website storage/notifications/seeds. That config is not prepared yet.

## Runtime verification protocol

1. Publish split baseline in a separate staging Replit App; never republish the
   website for this experiment. Record published deployment ID/geography/capacity.
2. Test synthetic authenticated CRUD/deep links, invalid/expired credentials,
   refresh/cookies/CORS, subscription reconnect and state after cold/restart.
   Record warm/cold p50/p95, boot duration, RSS/peaks, error rate. Two **published**
   API instances must share Redis/database; process simulations are supplementary.
3. Intentionally run migrations once before API startup. Register required
   recurring jobs once using `command:prod cron:register:all`, record repeatable
   queue IDs, prove recovery and absence of duplicate user-visible effects.
   Do not disable all scheduling to obtain a passing result.
4. Separately evaluate same-ingress host routing (root CRM origin with a dedicated
   staging host, if supported) and `/crm` path routing. Do not assume path support.
   Supervisor must stop the entire deployment when a required child fails and
   forward SIGTERM, with aggregated readiness and no SPA fallback into `/api`
   or `/admin`. Check OAuth origins even though SSO integration is excluded.
5. Exact approved worker plan only. Install built production artifacts off-host;
   restricted SSH/admin channel, systemd nonroot worker, restart policy, rotated
   logs and secret env file. Reboot and retrieve logs remotely.
   Sample `host-telemetry.mjs PID 1800` during startup/load; start sampling before
   worker launch where possible to catch boot peaks. Also capture cgroup/kernel
   OOM records, disk `df`, PID restarts and CPU tick deltas. Sampling at 1 Hz can
   miss subsecond peaks; use host peak/cgroup counters too. No swap baseline.
6. From that host, verify DNS AAAA plus IPv6 TCP/TLS/auth to Postgres, Redis, S3
   or bridge, download sources and every enabled API. DNS alone does not pass.
7. Five synthetic concurrent users; 100 stable job IDs over a minimum 30-minute
   burst; approved 24-hour soak. Store a per-job durable effect ledger/hash and
   retry/restart outcomes. No claim of exactly-once delivery. Queue lag/backlog,
   command counts and idle polling must be measured from isolated Redis.
8. Test binary attachment upload/read/replace/delete, SHA-256 equality, private
   authorization (anonymous and another workspace denied), expired signing,
   provider errors without fallback, worker reads and restart persistence.
9. Custom object `preflightEnquiry` with stable synthetic external ID and a
   small authenticated React page; persist/read/update after restart. A lookup
   stub returns only deterministic `.test` data. This proof is not implemented.

## Rollback and cleanup

Stop staging ingress and worker, revoke experiment app/API/bridge credentials,
remove ONLY inventory-owned VM, Redis, deployment, dedicated bucket/prefix and
disposable logical DB after approval. Prefer deletion of the disposable DB over
schema-wide DROP commands; never use CRM truncate/reset on a shared DB.
Check provider inventories and object counts afterwards and record final state.
Do not delete resources that cannot be attributed to this experiment.

Experiment resource IDs and cleanup state are in the private inventory.
`vultr.mjs` supports only the approved 512 MB/1 GB tiers, explicit paid approval,
one active experiment VM at a time, disabled backups, status and ownership-checked
cleanup. It deliberately does not install Docker or build CRM on the VM.
`remote.mjs` uses a dedicated key and fixed baseline/network/reboot commands,
with root/password SSH disabled and a narrow sudo allowlist. First-connection
SSH host-key trust is TOFU (`accept-new`) to a provider-returned address; for a
long-lived deployment, establish out-of-band host-key verification.
The private key is never displayed or shipped as an artifact.

The user clarified that the required baseline is **`vc2-1c-0.5gb-v6`**, with a
$3/month ceiling and IPv4 expected. The live API currently quotes $2.50/month;
the identifier is unchanged and no $3.50 alternative is substituted. Creation
explicitly sets `disable_public_ipv4: false` and leaves backups disabled.
Inventory IP fields and `/ipv4` allocations are not proof that SSH is reachable;
record both metadata and real connectivity separately.

T4 now holds the user's Upstash Redis URL. It uses `redis://`, but these probes
explicitly establish verified TLS on its port before authentication. There is
no plaintext or REST fallback. Run `node experiments/crm-preflight/redis-probe.mjs
local 4` (or `host 4`, `host 6`) for an isolated AUTH/PING/SET/GET/DEL probe.
Credentials are passed only through stdin or encrypted SSH stdin, not command
arguments, files, cloud-init or logs. Synthetic keys expire after 60 seconds and
are explicitly deleted. This does not prove BullMQ compatibility or job behavior.
Offline final tests: `node --test experiments/crm-preflight/test-tools.mjs` and
`PYTHONDONTWRITEBYTECODE=1 python3 experiments/crm-preflight/test-redis-probe.py`.

### User-created Ubuntu worker candidate

The user supplied their own $5/month, 1 GB / 1 vCPU Ubuntu 24.04 VM. Register
its ID and IPv4 through `node experiments/crm-preflight/user-host.mjs register
<id> <IPv4>`; the helper verifies provider metadata and stores a private inventory.
This inventory is **separate** from disposable experiment VMs and prohibits
automatic VM deletion. Never feed it to the lifecycle cleanup client.

Use `node experiments/crm-preflight/user-host.mjs baseline` and
`node experiments/crm-preflight/redis-probe.mjs user-host 4` for read-only OS
metadata and a namespaced temporary Redis TLS probe. T5 is supplied to sshpass
through an anonymous file descriptor, not an argument, environment variable,
cloud-init, config file or log. Only the requested root SSH connection receives
that password; child environments do not inherit website/provider credentials.
Host-key enrollment is TOFU in a dedicated private known-hosts file, not an
independently verified host identity. This is bootstrap evidence, not proof of a
restricted nonroot worker management channel or a running CRM worker.

Source builds remain off the 1 GB worker. The isolated builder now uses a
compressed cache, disabled global mirror, bounded fetch concurrency and serial
Nx tasks. A local cache alone does not prevent Yarn duplicating its global
mirror. Source preparation uses `--no-checkout` to avoid another full tree while
retaining explicit pinned Git metadata. Only redundant experiment exports and
experiment-created download cache archives were removed; website modules and
source were untouched.

The downloaded source is in
ignored `generated-artifacts/crm-preflight/source`; it may be retained for
reproduction or removed by its exact path, not a broad workspace cleanup.

### Completed runtime experiment

The user subsequently approved one-tier resizing on a memory bottleneck.
`upgrade-user-host.mjs approved-one-tier` checks the original VM, eligible
upgrades and exact $10/month 2 GB plan before PATCHing that same instance.
It never creates a replacement, upgrades more than one level or changes backups.
`staging-db.mjs reinitialize-retired` requires an explicit retired scope, prior
zero-object retirement evidence and a fresh empty-database check. The new native
five-user fixture uses `load-five-users.mjs join|run`; it does not SQL-bypass
membership. See `.local/reports/crm-gotchas-and-fixes.md` for current outcomes.

The 2 GB follow-up completed: no worker OOMs, no swap, 29.54% minimum headroom,
100 lookup jobs and both native SDK-generation jobs passed. Verdict is YES for
the bounded experiment, not full production/24-hour acceptance.
`load-five-users.mjs probe` verifies recovery from expired fixture tokens;
`run` performs the 30-minute workload. Native token renewal retries only a 401
auth rejection once, never ambiguous mutations. Original run failures remain
reported separately from the successful renewal probe.
`audit-all-queues.mjs` inventories the pinned source's queue names and counts.
`memory-baseline.mjs enable|restore` keeps the no-swap baseline across reboot
and restores stock OS swap after retirement. The current stage is retired and
all services are disabled; user VM remains at the upgraded $10/month price.

## Dedicated Replit bucket follow-up

`storage-proof-config.mjs`, `storage-proof-driver.mjs`,
`storage-proof-bridge.mjs` and `storage-proof-test.mjs` retain a bounded
App Storage adapter/bridge experiment. The bucket is selected explicitly;
guarded random prefixes isolate fixtures from all website objects. Secrets
and VM inventory stay in ignored private storage. Bridge identity is temporary
and independent from Replit runtime identity; it travels to the VM over SSH
stdin only.

The real source-built CRM validator and the actual VM client passed
binary/range/stream/copy/move and private HTTPS upload/read/replace/delete
checks. Native factory/attachment ACL integration, atomic conditional moves,
complete folder/large-stream semantics and published behavior remain gaps,
not simulated passes. The driver is deliberately a bounded spike.

See `.local/reports/crm-alternative-storage-validation.md` and
`.local/reports/crm-port-project-plan.md` for the scoped YES and the detailed
port plan. Final cleanup removed three fixtures and the temporary identity;
bucket retained, bridge workflow removed, original development app restored.

## Selected CRM storage: native Backblaze

User supplied `S3_KEY_ID`, `S3_ACCESS_KEY`, `S3_ENDPOINT` for `mgre-v2`.
`run-native-s3.mjs` and `native-s3-proof.cjs` exercise actual source-built
CRM S3/validated drivers on Replit and the real VM, passing configuration
through stdin rather than secret arguments or VM files. Credentials and
signed URLs are never printed.

Native transfers, streams, ranges, metadata, signed URLs/expiry, private
access and provider copy preconditions passed. Browser CORS is absent;
configure exact origins or use native server transfer. Cloudflare is optional.
See `.local/reports/crm-storage-validation.md` and the revised 10-phase/35-session
plan. Cleanup removed 46 synthetic object versions/delete markers and verified
zero remaining. Retirement blocks reuse of the old proof prefix.

Latest stable v2.45.0 source frontend/API/worker builds completed. The actual
user-selected 1 GB VM failed the full baseline: four V8 heap OOMs, two failed
native SDK jobs and less than 20% peak host headroom. All 100 synthetic lookup
jobs completed with one stored effect each. See the authoritative final results
at the top of `.local/reports/crm-feasibility-report.md`; earlier entries are historical.

Runtime tooling uses only a verified-empty disposable T6 Neon database and
dedicated T4 TLS Redis. `staging-db.mjs` creates separate application roles;
`candidate.mjs payload|setup|cron|api|api2|payload-upgrade` launches fixed commands
with sealed environments. Never invoke setup/cron from API instance startup.
`NODE_PORT` is the pinned source's listen variable. Published Autoscale and
shared managed-Replit database tests remain blocked, not established by Neon.

`package-worker.sh` packages only production backend/workspace dependencies;
`install-worker.mjs` transfers/verifies archives and creates protected runtime
configuration, bounded logs and nonroot restricted management. Do not build on
the memory-test VM. `queue.mjs` and `worker-sampler.py` retain job/host evidence;
command instrumentation never records command arguments.

`build-proof-page.mjs` compiles the retained React template. Native metadata
auth and custom object creation use `/metadata`; record CRUD uses `/rest`.
Only synthetic accounts/objects are permitted. Local core asset directories
are explicitly temporary, not attachments, shared storage or a fallback.

Before retirement, stop both API processes. Run
`node experiments/crm-preflight/retire.mjs approved-disposable-services`.
It disables worker/sampler, removes runtime credentials/remote privileges,
clears dedicated Redis and removes synthetic database objects/roles, preserving
private evidence. It never deletes the user-owned VM. The completed run retired
the stage; initialize a fresh scope for another test instead of reusing deleted
application logins. VM billing continues until its owner deletes it.
