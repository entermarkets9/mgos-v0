# CRM native-source audit

## Status and authority

## Current-generation reconciliation

Implementation now starts at the user's requested latest fork, pinned to
`d6e8c0255a7019741f623d838b18bd726dbe55dc`, source tree
`b356dbdb4f15fca5c6d93a4d2488b0c3b0460d8e`. See
[`crm-source-baseline.json`](crm-source-baseline.json). This is the observed
default-branch tip, not a published release tag. It is 474 commits ahead of
the earlier pilot source. The website checkout was not replaced.

Current tree recovery is complete/untruncated (37,422 blobs). All 25 previously
exported inputs were compared by immutable blob identity. Multiple permission
services changed, two sharing helpers were removed, and the root license changed.
Identical individual blobs do not make an old end-to-end conclusion current.

Eleven current-generation source blobs were exported for static inspection:
root package/toolchain/license inputs; current RLS service; current record-sharing
service/resolver; current row-access policy builder; native create-object input;
native object-metadata validator; and current object-sharing resolver utility.
No upstream executable, feature toggle, account, migration or test ran.

### Current permission findings and scope conflict

The latest predicate service still checks a valid Enterprise plan **and** the
RLS entitlement before its upsert operation. The user explicitly excludes
Enterprise-gated feature activation; therefore this route is not selected.
No more confirmation of general ownership/legal rights is requested.

The current native object-permission model exposes read/update/delete rights
at object scope. Those permissions alone do not restrict Enquiry rows by the
assigned member.

Native sharing has changed: current service operations are general-access,
share and remove-share operations. `resolveObjectSharing` resolves default/open
objects to `ROLE_ONLY` unless the record-sharing feature switch and native
exception conditions apply. PRIVATE and INHERITED modes exist, but their
availability is not established as a supported non-Enterprise assignment ACL.
The source helper is Enterprise-marked; that marker by itself is not proof of
a runtime entitlement gate and is not used to deny the user's stated rights.
Native `CreateObjectInput` does not expose readability as a GraphQL option.

**No supported non-gated equivalent has yet been established for the full
assignment-based broker policy.** Creating per-record shares separately is
not proof that native assignment, reassignment, unassigned privacy, related
records, aggregates, attachments and realtime atomically obey that policy.
No sharing flag, direct metadata alteration, custom permission service,
separate-workspace identity or weakened list-only filter has been selected.

D04 needs a product decision: preserve assigned-only record isolation and
remain blocked pending a supported non-gated native route, or explicitly
revise scope to standard object-level roles with shared workspace records.
In the latter scope, assignment is organization/responsibility, **not a
security boundary**, including list/search/export/detail/count paths.
This scope revision has not been approved.

### Current immutable evidence

The baseline manifest records current package/toolchain/license blobs.
Paths below are relative to the original server component's `src/`.

| Current input | Git blob |
| --- | --- |
| `engine/metadata-modules/row-level-permission-predicate/services/row-level-permission-predicate.service.ts` | `f384c5dc38bfeb812a3b90da1069e4e6be2aeeb8` |
| `engine/core-modules/record-share/services/record-sharing.service.ts` | `1605aef0e337990248bfd401857f34dbc3707e95` |
| `engine/core-modules/record-share/resolvers/record-sharing.resolver.ts` | `95b72a71e79711dc9d7f60de72aac8fe6cd17d72` |
| `engine/twenty-orm/utils/build-row-access-policy.util.ts` | `95061dad2ba04b033d45de1922d315fdc5d04b55` |
| `engine/metadata-modules/object-metadata/dtos/create-object.input.ts` | `aaaf0f4929ba83b2f724f1cf22453a58527d6b76` |
| `engine/workspace-manager/workspace-migration/workspace-migration-builder/validators/services/flat-object-metadata-validator.service.ts` | `a8708d2c36ee75c4fc21704ccc3b298de1f9118c` |
| `engine/core-modules/record-share/utils/resolve-object-sharing.util.ts` | `7cdaeae0dd99a6e653e6395163b64b0eee9820e5` |

## Current native role / personal-table follow-up

The user explicitly keeps assigned-only privacy and proposes native Roles and
personal data models with an individual lead table for each broker. Shared
workspace records and Enterprise activation are not approved.

Current source supports a **table/object-level route worth investigating**:

- `RoleResolver` uses authenticated native principals and the ROLES settings
  permission guard. Native role creation and native workspace-member role
  assignment are exposed. The inspected role creation path has no Enterprise
  entitlement check.
- `ObjectPermissionService.upsertObjectPermissions` addresses `roleId` and
  `objectMetadataId`, with read/update/soft-delete/destroy record grants, and
  uses native metadata migration validation/execution.
- `ObjectMetadataService.createOneObject` is workspace/application scoped and
  creates native initial views. Metadata names are unique within the workspace;
  target table naming is derived from the object name/application, not the
  current viewer or a user-specific filter.

Thus an individual generated lead table is another native **Enquiry object**,
not a personal filtered view of the single shared Enquiry object. Native roles
can grant a broker their object and deny others. Broker-role all-object defaults
must be false, and the broker must not retain another broad member/admin role
or metadata/role-management permission. The standard Member role defaults
to broad object access and must not be treated as a safe broker role.

This is not accepted universal-path isolation yet. Native role assignment,
effective permission composition, relationships, file/realtime/search/export
paths and lifecycle remain to be traced; final synthetic negative tests remain
in Phase 7.

**Object-count conflict:** the current contract requires exactly Property,
Listing and one Enquiry object. Separate broker Enquiry objects change that
contract. Keeping manager-only unassigned intake would need an intake Enquiry
object as well: Property + Listing + intake Enquiry + one Enquiry per broker.
These remain native generated objects, with no fourth Broker identity object,
but exceed the three-object limit.

**Lifecycle conflict:** assignment between broker tables is no longer a field
update on one object. Safe transfer, stable record identities/references,
manager aggregation and listing relations require a revised native contract;
native atomic transfer capability is not assumed. No custom CRUD, direct SQL,
permission bypass, workspace split or custom ACL service is authorized.

The user subsequently approved the per-broker-table direction. This object-count
gate is resolved by the amendment in the canonical contracts; native lifecycle/
transfer and universal-path capability are not yet accepted. Privacy is retained.

| Additional current input, server `src/` relative | Git blob |
| --- | --- |
| `engine/metadata-modules/role/role.service.ts` | `fc1dd0ff8b75c59a30cb552098fcb0025771572a` |
| `engine/metadata-modules/role/role.resolver.ts` | `97cb043b7417dd370aa816a5fe0b8c4b6b276ab7` |
| `engine/metadata-modules/object-permission/object-permission.service.ts` | `bf27a5af31d9a65d1d1a682794a64a481e9f0caf` |
| `engine/metadata-modules/object-metadata/object-metadata.service.ts` | `c02f71e48fd97a2669979a44e3d929c1028eb419` |
| `engine/metadata-modules/object-metadata/object-metadata.entity.ts` | `c0251f29cc950b7490b0f543fd3da96232d9f7e4` |
| `engine/utils/compute-object-target-table.util.ts` | `8dd786cce1ff12716b267c1f96516f533780ec2d` |

### Approved-model lifecycle interface inventory

Eight further current-source inputs were read at verified blob identities:
native user-role service, ORM manager/repository, permission resolver/validator,
file-by-ID guard, upload permission guard and files-field service.

Observed native interfaces:

- `assignRoleToWorkspaceMember` resolves native workspace member and workspace
  membership and validates assignability/acting member; role targets and cached
  effective role state use native mechanisms. Self-role changes are rejected.
  This is not an invitation/deactivation/session-revocation inventory yet.
- `resolveObjectRecordsPermissions` supports a single-role union and role
  intersection; multiple-role union throws an unsupported-operation error.
  Missing maps resolve empty permissions, without implicit bypass. Do not invent
  multi-role union behavior or assume source supports arbitrary role composition.
- `getRepositoryWithContextPermissions(name, transactionScope)` resolves the
  ordinary actor's native role configuration; missing configuration is denied.
  `executeInWorkspaceContext` accepts native auth context;
  `runInWorkspaceTransaction` uses the primary workspace datasource transaction.
  A transaction scope can supply multiple object repositories.
- The repository has native insert/update/delete/soft-delete operations and
  applies row-access policy plus query permission validation before execution.
  Available generic transaction primitives are not a finished Enquiry transfer
  operation. Transfer must preserve authorized actor context, identities,
  references, audit/event behavior and assignment consistency.
- `FileByIdGuard` checks signed file ID/workspace token and workspace suspension,
  not the current broker's role at every bearer-token download. Prior authorized
  signed URLs can retain access until expiry; TTL/residual policy must be
  explicit. The complete URL-issuance/parent-permission path is not traced yet.
- `FilesFieldService.copyFileIntoFilesField` copies an uploaded file into the
  destination field/application using native storage and a new file ID. This is
  an external storage operation, not an atomic part of a PostgreSQL transaction.
  Do not promise atomic cross-table attachment transfer from ORM primitives alone.

The model audit remains partial. Remaining source inventory includes universal
query/export/realtime/URL-issuance paths, generated relation metadata, field
defaults and native lifecycle/events/cleanup interfaces. No model registration,
workspace/member setup or attachment/provider action has run.

| Lifecycle input, server `src/` relative | Git blob |
| --- | --- |
| `engine/metadata-modules/user-role/user-role.service.ts` | `c21006eaf4afd944cf6e8a2bc5626ed3bbb75a29` |
| `engine/twenty-orm/workspace-orm.manager.ts` | `5e39dc605047038517326568c6d633aed50a8b4c` |
| `engine/twenty-orm/repository/workspace-repository.ts` | `6707474b16b3a2729864de30c6a84ac8573ba42a` |
| `engine/twenty-orm/utils/resolve-object-records-permissions.util.ts` | `adad0ff94ad54162215593d94c30f6810e8cad54` |
| `engine/core-modules/file/guards/file-by-id.guard.ts` | `e7ccdbef35d746157a137d6addbc830387ae2482` |
| `engine/core-modules/file/file-upload/guards/create-file-upload-permission.guard.ts` | `e7728e84e6051a55623e0ab42d713d525d9423b1` |
| `engine/core-modules/file/files-field/services/files-field.service.ts` | `8e08d6b6cbfd7bdceb670c0df186ce886f8a76b7` |
| `engine/twenty-orm/repository/permissions.utils.ts` | `6112bec895ef61f1cfef122c64f010863dd4194e` |

## Current calculator settings interface inventory

Approved product answers are in the canonical contract's calculator amendment:
annual amounts, price-once net denominator, initial AED, agency 2%, conveyancing
AED 2; currency and all fee defaults (including DLD) editable in settings.
These are configuration defaults, not permanently hardcoded arithmetic inputs.

Current source exposes a native application-settings candidate:

- `ApplicationVariableEntity` is native `core.applicationVariable`, scoped by
  native application/workspace, with type/options/label/required/default metadata.
  Values are encrypted by the native service even when `isSecret` is false.
  USER-scoped variables differ from shared application variables and are not
  the candidate for shared calculator fee defaults.
- `SettingsApplicationVariableInput` already renders numeric inputs, selects,
  raw JSON and other native types. Currency can be an explicit select and fees
  explicit numeric fields within the existing application settings editor.
- Native `updateOneApplicationVariable` uses principal authentication and
  APPLICATIONS settings permission. Target application is resolved from native
  context; the service filters by workspace/application/key and rejects updates
  to USER-scoped variables through this shared settings route.
- Updates use native encryption and invalidate/recompute application-variable
  cache. Manifest `defaultValue` is separate from operator-editable `value`;
  upgrades must preserve operator values rather than resetting them to defaults.
- `getPublicEnvVariables({ workspaceId, applicationId })` excludes secret and
  USER-scope values. This is a backend service interface, not proof that an
  unprivileged broker can call the settings GraphQL field. Calculator access must
  use an allowlisted typed public read without granting brokers APPLICATIONS
  write/settings permission or returning unrelated non-secret configuration.

The write DTO carries a branded string and the shared update method does not
show calculator-specific range/currency validation. Calculator read/write
integration needs explicit validation, not silent empty/invalid values or zero
fallbacks. Existing settings input code is not rendered acceptance.

Remaining integration questions: approved native application ownership/metadata
registration, actual settings-page availability, public-variable delivery,
supported currency options and stable upgrade behavior. No extra domain object,
settings page, application install or provider/database write has occurred.

| Settings input, original source relative | Git blob |
| --- | --- |
| `packages/twenty-server/src/engine/core-modules/application/application-variable/application-variable.entity.ts` | `a2c586791482fbbb28a1ae7518b1349dd9b21f29` |
| `packages/twenty-server/src/engine/core-modules/application/application-variable/application-variable.resolver.ts` | `e728c7444f91784fc55f271de76c4ae911d5f63a` |
| `packages/twenty-server/src/engine/core-modules/application/application-variable/application-variable.service.ts` | `4de87710498685dd24d2baf25f6ca043bd24e076` |
| `packages/twenty-server/src/engine/core-modules/application/application-variable/dtos/update-application-variable.input.ts` | `784407bf1d74f3a3d40c9feed904e557fc478498` |
| `packages/twenty-front/src/pages/settings/applications/components/SettingsApplicationVariableInput.tsx` | `3c7cb70be538f6c6b25d85347fc15c5ea8d9c929` |

## Current startup/database/storage interface inventory

Six immutable source inputs were read, not executed: server package scripts,
API module, bootstrap, native configuration declarations, storage service and
official database setup script.

- The source declares separate production API (`node dist/main`), worker
  (`node dist/queue-worker/queue-worker`) and CLI entrypoints. Official
  `database:init:prod` runs compiled setup then instance migration commands with
  `--force --include-slow`. A source script declaration is not a verified safe
  initializer outcome or permission to invoke it.
- The setup script creates `public`/`core` schemas and `uuid-ossp`, `unaccent`,
  `citext` extensions, and **replaces `public.unaccent_immutable(text)`**.
  Optional FDW initialization adds further extensions when explicitly enabled.
  Therefore native setup is not confined to a new CRM schema and must never run
  on the preserved Payload database by assumption. D07/D08 must allowlist shared
  helper/extension ownership and the exact fresh synthetic target/actions.
  Setup helpers, raw datasource and instance command list still require tracing.
- API bootstrap configures credentialed CORS, trust-proxy parsing, session store
  and body/upload parsers, then listens on `NODE_PORT` (default 3000). It does not
  specify a loopback host in the observed listen call. Private-child binding and
  gateway forwarding/trust rules require coordinated source integration.
- Observed signal handling flushes the usage recorder then exits. Bounded
  request/stream/subscription drain and main-agent child supervision are not
  proven by that handler. No healthy startup or migration-free transitive
  module initialization has been accepted.
- Source configuration includes separate Redis queue URL/prefix, cache prefix,
  queue allow/exclude lists, PostgreSQL pool/replica/SSL settings and a workspace
  schema-DDL lock. Empty cache prefix / `bull` defaults do not satisfy the
  approved environment hash-tag isolation contract; all consumers still need
  tracing. No default is silently accepted as a sealed launch configuration.
- Native storage config includes S3 endpoint/region/bucket/key fields, optional
  presigned mode/expiry and quotas. Default storage is LOCAL; CRM launch must
  explicitly require the approved private B2 S3 configuration without fallback.
  Provider calls, CORS/bucket changes and URL probes have not run.
- Native file-token default is one day; S3 presigned default is 900 seconds.
  The accepted residual-exposure policy is not yet decided. Nested bearer token
  and redirect lifetimes need one honest bound, not independent TTL assumptions.

Root `yarn.lock` metadata identifies blob
`70f32cccbab2e9afdbb675b0aee083faebcd2a53`, size 1,958,662 bytes. It has not been
downloaded/installed/validated. Server engines require Node `^24.5.0`; root
`.nvmrc`/Yarn declarations are in the baseline manifest. Frontend package
identity was located, not read; build outputs, framework/ABI compatibility,
native static serving, official CLI action list, auth/session/signup and complete
database ownership inventory remain unfinished.

| Runtime input, original server relative | Git blob |
| --- | --- |
| `package.json` | `556147987d4af57a64c010e3fcced49acc7db231` |
| `src/app.module.ts` | `df821d42054b88075c6b31bce13c314f8fcc3e44` |
| `src/main.ts` | `f5217e1a21ad1b4fb9f0f9daa9b8235d5844cf3a` |
| `src/engine/core-modules/twenty-config/config-variables.ts` | `878725c888d52369802a8565c8f469cb91c3f32e` |
| `src/engine/core-modules/file-storage/services/file-storage.service.ts` | `3d9bea4994331466ca998b401ceb9050944b12c7` |
| `src/database/scripts/setup-db.ts` | `f4ad1bcba971bbf80cc1235d430f8ebc4f950784` |

## Current official initializer/module continuation

The official setup helper reports query failures and sets exit code 1 but catches
them locally; later setup statements can still execute. Partial setup is
therefore possible. A nonzero result requires recorded reconciliation, not an
automatic rerun/rollback. No setup statement was executed in this audit.

The raw datasource calls dotenv with **override: true**, selecting `.env` or
`.env.test` from the process working directory, then uses `PG_DATABASE_URL`.
Passing a sealed child environment alone is insufficient if an old/local env
file can override its target. Initialization must use an approved clean working
directory/source generation with no inherited historical env files; exact CLI
dotenv paths and transitive loaders still need tracing. Do not point the native
initializer at the website directory or reuse a pilot dotenv file.

Observed raw datasource options do not explicitly name a schema or bind a
separate migration identity. SSL self-signed acceptance is opt-in. Credentials,
target identity, role/schema ownership and transport remain action gates, not
defaults inferred from source.

Core module imports include native queue/storage/config factories, registration,
preinstalled apps, subscriptions, cleanup modules, telemetry and deferred
integration/AI/billing modules. Imports alone prove neither activation nor
absence of module-load side effects. Do not equate CLI/main entrypoint simplicity
with migration-free startup or permission to enable deferred/Enterprise features.
The ORM module points to `src/database/typeorm/typeorm.module.ts`; that wiring,
module lifecycle hooks and instance migration command dispatch remain untraced.

| Continuation input, original server relative | Git blob |
| --- | --- |
| `src/database/scripts/setup-db-utils.ts` | `35e83438c9d57a83e82c85982cfbf193e01abcd1` |
| `src/database/typeorm/raw/raw.datasource.ts` | `3cb163ccc98359c17b6206108586c2486a063977` |
| `src/engine/core-modules/core-engine.module.ts` | `c797477c68e464ae0f6b63468c6293543000134d` |
| `src/engine/twenty-orm/twenty-orm.module.ts` | `2582e5f34fa1f642da3311330e628b0949b21819` |

## Current core connection and migration dispatch

Native TypeORM module initializes the datasource and installs its upgrade-aware
repository proxy; EnvironmentModule loads `.env`/`.env.test`, expands variables
and validates native configuration. Core datasource also independently loads
dotenv with override enabled. All relevant entrypoints need a clean, approved
source working directory and explicit sealed values; a website/pilot dotenv
file must never participate.

The observed core datasource sets schema `core`, `synchronize: false` and
`migrationsRun: false`. This proves those flags on this connection definition,
not absence of every transitive startup metadata/job/provider effect. It reads
pool/timeouts/SSL directly from environment; configuration-class defaults must
not be assumed to supply all those direct-env options. Entity/migration glob
paths are relative `dist/` (or `src/` under the native Jest condition), so an
arbitrary empty cwd is not a compatible initialization workaround.

The historical TypeORM migration system is frozen in this source. Native comments
direct new changes to registered fast/slow instance commands. Official CLI runs
pending legacy migrations with **transaction: each**, then the registered
upgrade sequence. `--force` specifically skips workspace-version safety checking;
it is not blanket permission to bypass guards or repeat initialization.
`--include-slow` includes data migration plus DDL. Slow data migration is skipped
when the command's provisioned-workspace set is empty; fast commands/DDL still
require an explicit inventory. Upgrade-status cache invalidation runs in finally
and catches/logs its own failure. This is not one atomic whole-setup transaction.

CommandModule imports **AppModule**, along with database commands, metadata and
cleanup modules. Thus the official migration CLI is not demonstrated to be a
database-only process. Transitive factories/hooks, native registry/sequence
contents and cache/job/provider effects must be allowlisted before initializer
approval. No CLI/module/database connection or migration was executed.

| Wiring/dispatch input, original server relative | Git blob |
| --- | --- |
| `src/database/typeorm/typeorm.module.ts` | `a06d5003cb11f85a4ea0014bcab03578ae941ee7` |
| `src/engine/core-modules/environment/environment.module.ts` | `74898d55876c2ac72b134330e7f4171e25a096ed` |
| `src/database/typeorm/core/core.datasource.ts` | `5a094882620bda4b51aa20ea5dd0e7ce65fd37f3` |
| `src/command/command.module.ts` | `7c2208f167b642032a258172c419b2930c6c47ee` |
| `src/database/commands/run-instance-commands.command.ts` | `aff23e0778c6e3f22adf9e78fe6859b576e5854e` |

## Current native storage/Redis/session/worker slice

- Storage factory supports the native S3 driver with a custom endpoint and
  `forcePathStyle: true`, wrapped in `ValidatedStorageDriver`. This is a native
  B2-compatible configuration candidate, not provider acceptance. It selects
  LOCAL or S3 by configuration; there is no observed S3-error-to-LOCAL fallback.
  Missing explicit access-key ID selects the AWS credential-provider chain.
  CRM sealing must require the approved B2 key pair, region, endpoint/bucket and
  S3 mode instead of allowing unrelated provider credentials/default LOCAL.
- S3 constructor returns without initializing clients when bucket or region is
  absent. Source startup alone cannot establish storage readiness; configuration
  validation must fail explicitly. Native upload supports bounded-memory streams;
  observed Put/Copy commands do not set a public-read ACL. Private bucket policy,
  key scopes and actual B2 behavior remain separately gated.
- Native S3 read supports byte ranges and destroy propagation. Presigned read/
  upload methods accept explicit expiry; upload signs declared content-type and
  content-length. Native method availability is not proof of issuer/parent ACL,
  private download headers, CORS or bounded stacked-token expiry.
- File move is head/copy/delete, not an atomic provider transaction. Conditional
  copy can fall back to an unconditional same-backend copy after 501/unsupported.
  That compatibility fallback is **not** a different storage backend. Folder
  copy/move listing and cleanup behavior require scoped reconciliation; no
  blanket directory/bucket cleanup action is permitted. Bucket create methods
  exist but have not been invoked or proven to be called during startup.
- Redis service lazily creates distinct IORedis queue/main clients, queue URL
  falling back to main Redis URL, `maxRetriesPerRequest: null`; pub/sub duplicates
  the main connection. Queue prefix is configurable; the generic main/pub-sub
  client has no observed universal environment prefix. All key/topic producers
  must still be enumerated. Retry/connection budgets are not accepted defaults.
- Queue factory unconditionally selects BullMQ and requests the queue client.
  Since official CLI imports AppModule, its configuration can initiate Redis
  connections as well as database work. Exact constructor/registration effects
  must be included in initializer approval; it is not a SQL-only action.
- Session factory uses another node-redis connection, heartbeat and a hardcoded
  `engine:session:` prefix. Cache/queue prefix settings alone do not isolate
  sessions. Native cookie configuration is httpOnly, SameSite lax, secure for an
  HTTPS SERVER_URL, with no explicit parent-domain cookie; signing-key resolution
  and actual native browser-token behavior still require auth inventory.
- Worker uses a Nest application context, no observed HTTP listen call, imports
  native JobsModule plus queue explorer and enables shutdown hooks. This
  identifies the separate worker entrypoint but not exact eligible jobs,
  schedule registration, retries, per-job authorization, connection count,
  bounded shutdown or actual intended-Vultr execution. No worker started.

| Services input, original server relative | Git blob |
| --- | --- |
| `src/engine/core-modules/file-storage/file-storage-driver.factory.ts` | `b6041dbbc16f050c15d6a064688b753773cc87be` |
| `src/engine/core-modules/file-storage/drivers/s3.driver.ts` | `3b19cf5d7be019245eb144941f5941b6ff891f4e` |
| `src/engine/core-modules/redis-client/redis-client.service.ts` | `59e74461c6a2d9af1e9d3d1f62558a730153bccb` |
| `src/engine/core-modules/message-queue/message-queue.module-factory.ts` | `cdc1e7e06e99d75bd0b5d570b0d4d9b03f93c959` |
| `src/engine/core-modules/session-storage/session-storage.module-factory.ts` | `ff409f6ddf4a40a175764592d92c410cb9ece556` |
| `src/queue-worker/queue-worker.module.ts` | `3151c40f5443b1b0deb7289edbe0393351dadbfa` |
| `src/queue-worker/queue-worker.ts` | `039bbe0c4c7f51544a4e2e1b54de50176bac4e49` |

### Current native worker discovery / deferred-feature boundary

MessageQueueModule separates core queue registration from `registerExplorer()`.
The worker imports the latter. Its explorer scans native processor providers
on module initialization, groups by queue, filters through enabled/excluded
queue names and calls `queue.work()` with native worker-config options.
Queue-name errors are warnings, not a fail-closed validation gate; empty array
entries are removed. Exact allowlist validation must precede activation.

Dispatch matches each job's name against processor metadata; request-scoped
handlers receive job-data workspaceId and per-context dependencies, then
abort/retry/progress options. This is not proof of trusted producer payloads or
record authorization. Source-defined handlers, queue driver retry/lock/close
behavior and cron *producers* remain untraced.

JobsModule includes native application install/upgrade, SDK generation,
workspace-member deletion/email changes, workspace cleanup, email/campaign,
billing, workflow/calendar/messaging/contact creation, AI/logic-function and
deferred migration services. Merely importing modules does not establish
activation, but neither does filtering worker queues prove that cron producers
are disabled. Required vs deferred queue/job families and one scheduler owner
still need a complete supported contract; do not accept broad defaults or reuse
historical queue namespaces. No processor/scheduler registered or started.

| Discovery input, original server relative | Git blob |
| --- | --- |
| `src/engine/core-modules/message-queue/message-queue.module.ts` | `658c04a1b7a790d643ece3584acf7ba4dad6b564` |
| `src/engine/core-modules/message-queue/message-queue.explorer.ts` | `fc1a8b78512c9204e007c53f6837f6e1a0db060e` |
| `src/engine/core-modules/message-queue/jobs.module.ts` | `4266115c340fcb66960e1ab5e73018585c4351ac` |

### Current archive/restore authorization mapping

At the approved source generation, native `isObjectOperationPermitted` maps
insert/update to `canUpdateObjectRecords`, restore/soft-delete to
`canSoftDeleteObjectRecords`, and permanent delete to
`canDestroyObjectRecords`. Thus shared create/edit need not grant archive or
restore. The role design must deny broker soft-delete/destroy, allow only the
approved manager/admin soft-delete scope, and not grant destroy by inference.
Effective defaults, protected administrator roles and API-key/service identities
still need reconciliation before any actor is considered safely configured.

WorkspaceRepository restores through the native mutation kind. Common restore
one delegates to restore many with an ID filter; restore many uses the common
filtered-mutation path, processes nested relations with the actor's
rolePermissionConfig, rejects remote-object mutation and requires a filter.
Repository permission validation checks object operation and metadata
writability. Missing object permissions deny unless native record-sharing
explicitly grants beyond-role access; that feature is not selected.

Object/field writability includes system/owning-application context checks,
distinct from ordinary role grants. No bypass/system identity is proposed for
broker requests. Exact common-base mutation delegation, REST/GraphQL route
contexts, archived-parent dependencies, account/token revalidation, realtime
and attachment paths remain unproven. This static mapping is **not** A05 pass.

| Mutation input, original server relative | Git blob |
| --- | --- |
| `src/engine/twenty-orm/utils/is-object-operation-permitted.util.ts` | `5adf21e8dcdb8b859a3b18095d6bccc71439ea1c` |
| `src/engine/twenty-orm/repository/validate-writability-or-throw.util.ts` | `c14e932391170883ef40721a7711eaf389f96c60` |
| `src/engine/api/common/common-query-runners/common-restore-one-query-runner.service.ts` | `92dda2807b1c94dc1e7ea8041b5a22f9009bf6e4` |
| `src/engine/api/common/common-query-runners/common-restore-many-query-runner.service.ts` | `e09f6355967762bd0082998524811b555e905f16` |

### Current native validation-rule inventory (partial)

Native core validation rules carry object ID, expression, compiled bindings,
active flag, error-field ID/message and syncable application identity. Service
create/update compiles against native field descriptors and applies the
workspace-custom application's supported migration builder/runner. Observed
service code has no entitlement check; resolver/feature gates and precise
expression support are still untraced, so free availability is not yet proved.

Native ORM insert/upsert helpers call `runWithValidationRules`; filtered
mutation calls it only for update, not restore/soft-delete/permanent-delete.
When rules exist the helper uses native transactional execution and validates
written records. Therefore these rules alone cannot be claimed to prevent
parent archiving or validate restore. Full write/delegation coverage remains
an audit gate.

The internal validator takes scoped native snapshots (including native
permission-bypassing internal reads), gathers live many-to-one relations for
bound paths, evaluates with a server-generated now instant in chunks, and
throws on violations/evaluation errors. This is an existing native integrity
mechanism, not authorization and not permission for new code to bypass roles
or return its privileged snapshots. Rule binding, active-membership/static
table-owner checks, readonly field/default stamping and upgrade invalidation
still need exact supported interfaces before implementation.

| Validation input, original server relative | Git blob |
| --- | --- |
| `src/engine/metadata-modules/validation-rule/entities/validation-rule.entity.ts` | `904633260532f090f4415cfef53c7d8cd15c2dd8` |
| `src/engine/metadata-modules/validation-rule/validation-rule.service.ts` | `3fdda94099d3ae97820ddcfdb08bed1101457759` |
| `src/engine/metadata-modules/validation-rule/utils/compile-validation-rule-expression-or-throw.util.ts` | `383156ccbd2deecc5fc01860e4c4f26aa584f85c` |
| `src/engine/twenty-orm/utils/validate-records-against-validation-rules.util.ts` | `07f402f464e34e1114b3a07d3863c67bd6eabf32` |

### Current validation expression / resolver continuation

Validation mutations require native DATA_MODEL permission and the workspace
`IS_VALIDATION_RULES_ENABLED` flag. Query requires the flag and native principal
authentication. The resolver itself does not request an Enterprise entitlement,
but the flag's availability/default/classification must still be traced before
any activation is proposed; no flag changed.

Field descriptors contain active native fields and, for many-to-one relations,
one-level active target fields. Compiler resolves identifier paths/bindings,
rejects empty/oversized expressions and bracket access, and validates evaluation
on an empty record. Exact parser functions, relation-ID binding and evaluator
semantics remain untraced; no expression was executed. Availability of these
interfaces alone does not prove a table-owner/assignment constraint or immutable
timestamp default.

| Continuation input, original source path | Git blob |
| --- | --- |
| `packages/twenty-server/src/engine/metadata-modules/validation-rule/validation-rule.resolver.ts` | `ed2de5318cf3d6bafa92a38233302c0825377c48` |
| `packages/twenty-server/src/engine/metadata-modules/validation-rule/utils/build-validation-rule-field-descriptors.util.ts` | `f6621d9afe31f5ac3be135dd60a44eca32da006b` |
| `packages/twenty-shared/src/utils/validation-rule/compileValidationRuleExpression.ts` | `5e9d81d8874a4e9d0d4e3b8ee6cb5e0d4b968c67` |
| `packages/twenty-shared/src/utils/validation-rule/evaluateValidationRuleExpression.ts` | `42afca0e629c48404e7d9062c27aadaa7e1baae2` |

### Current feature-flag guard/service continuation

Native FeatureFlagGuard obtains the authenticated workspace and denies a
disabled flag. FeatureFlagService reads the workspace cache map; missing entries
evaluate false. Its enabling/upsert methods write workspace-scoped core flags
and invalidate/recompute cache. They were not invoked. No Enterprise entitlement
guard was observed in these two files; defaults/initialization/classification
and downstream permission paths remain separate evidence requirements.

In particular, this does not authorize enabling IS_VALIDATION_RULES_ENABLED or
prove its default on the fresh target. Native integrity rules remain a candidate
pending that inventory and exact expression/default interfaces. Enterprise RLS
and record-sharing activation remain excluded.

| Flag input, original server relative | Git blob |
| --- | --- |
| `src/engine/guards/feature-flag.guard.ts` | `667d6d3eefcf8021d6c6ec834c56623a5579b902` |
| `src/engine/core-modules/feature-flag/services/feature-flag.service.ts` | `ab37b0eaa35860383ea72842ed18ea57869314e2` |

### Current native activation and rule-expression inventory (partial)

`signUpInNewWorkspace` is not an anonymous create-all endpoint: it requires a
native user-session principal, finds the current user, delegates workspace
creation to SignInUpService and returns a login token/workspace URLs. The auth
service delegates password/new-user decisions to the same service. Native
session/token/cookie services and the full signup destination/verification chain
still need tracing; no signup or token request made.

Workspace activation acquires a native pending→ongoing status lock and may
reclaim a stale ongoing lock. It initializes workspace metadata, enables
DEFAULT_FEATURE_FLAGS, creates a native workspace member, prefills records,
initializes upgrade cursor/state and enqueues preinstalled apps; SDK-generation
enqueue failure is caught/reported separately. A failure resets status to pending
but does not prove rollback of previous DDL/data/provider effects. No automatic
retry or purported atomic activation is authorized.

The exported default flag list has only REST metadata format and workflow core
index flags; IS_VALIDATION_RULES_ENABLED is absent. Other initializers/upgrades
may influence effective flags and remain untraced. This is not proof that rules
can be enabled without an entitlement or that required record prefill is scoped.

Native rule parser permits comparison/logical/arithmetic/member access; disables
assignment, function definitions and random/power operations. Functions come
from the native function registry. Evaluator requires a boolean, returning
passed/failed/errored. Identifier bindings support the special server-now value,
scalar/composite fields and at most one many-to-one relation; morph/to-many or
deeper related relations are rejected. Literal-owner/stamp rules, evaluation
context, field defaults and lifecycle mutations still need reconciliation.
None of these functions were invoked.

| Input, original path | Git blob |
| --- | --- |
| `packages/twenty-server/src/engine/core-modules/workspace/services/workspace.service.ts` | `d20e12b5e9c09839687300e2dc98686c69bda82f` |
| `packages/twenty-server/src/engine/core-modules/auth/auth.resolver.ts` | `7dec8578bb697c8ba23081f086f3927a1576126b` |
| `packages/twenty-server/src/engine/core-modules/auth/services/auth.service.ts` | `589c39d51ecf85a277b1ac281114eb923847b6b8` |
| `packages/twenty-server/src/engine/workspace-manager/workspace-migration/constant/default-feature-flags.ts` | `2d93f7043c7477fc9cfe97691026ccb57c71dc23` |
| `packages/twenty-shared/src/utils/validation-rule/validationRuleParser.ts` | `4f8d10d336b6d508e755baa05aa3c8b7465b7a01` |
| `packages/twenty-shared/src/utils/validation-rule/createValidationRuleEvaluator.ts` | `784350a5fcf8dbe3623fd21941eda924bf915558` |
| `packages/twenty-shared/src/utils/validation-rule/resolveValidationRuleIdentifierPath.ts` | `fe9d515e02cb09ea5484d3073b970499f98b245f` |

### Current native bootstrap prerequisite chain (partial)

SignInUpService.signUpOnNewWorkspace requires an email, nonblank display name
and workspace-creation policy. Its native transaction creates workspace/custom
application, creates or uses a native user, creates user-workspace membership
and onboarding state. First-server-admin determination occurs before new-user
creation. After commit it may infer/upload a work-domain logo, emits an event,
and conditionally creates a billing customer. Failure includes storage-stock
invalidation; it is not a universal transaction around outside effects.

WorkspaceManagerService.init creates a workspace schema and standard application,
synchronizes native metadata and configures default roles. Admin-role assignment
calls native user-role assignment after finding existing userWorkspace by userId
and workspaceId. Default Member role creation/selection remains unsafe for the
desired private-object policy until explicitly replaced/configured.
UserWorkspaceService.createWorkspaceMember uses native system context to create
the standard workspaceMember record from existing core membership; adding a
member subsequently assigns native role and invalidates caches/invitation state.
No custom identity or permission-bypassing caller is authorized by these internal
native operations.

The inspected stock activation unconditionally invokes prefill code for companies,
people, workflows and associated layouts/logic functions. Its metadata/role/member
requirements and seed/queue effects conflict with assuming P3 can realize objects
before any P7 native bootstrap. No alternative supported accountless bootstrap
has been proven. Freeze needs an explicit sequencing/synthetic-side-effect decision,
not fake IDs/SQL-seeded identities, early signup disguised as a probe, or a claim
that a definition file is registered/generated metadata.

| Input, original server relative | Git blob |
| --- | --- |
| `src/engine/core-modules/auth/services/sign-in-up.service.ts` | `609ca2e3795f5240732ae78a1a3465c6462d8302` |
| `src/engine/workspace-manager/workspace-manager.service.ts` | `6a8bc631f1ddedefa129bcc867f9c79a5975586f` |
| `src/engine/core-modules/user-workspace/user-workspace.service.ts` | `761624a8fb35d36988d7d953fda895de6a62f9db` |

### Platform source-body reconciliation — 2026-10-11

Official documentation search summary claimed all Replit databases private and
custom roles unsupported. Readable official page bodies do **not** support those
blanket statements: connection-details explicitly supports external clients for
production; development-and-production distinguishes app-local Helium from legacy
Neon and discusses migrating/resetting custom-role passwords. Current development
privacy does not prove production worker connectivity nor target-specific grants.
No direct platform role/CREATE DATABASE capability probe was made.

Read-only source bodies at
`https://docs.replit.com/features/data-and-storage/{name}.md`:

| name | bytes | SHA-256 |
| --- | --- | --- |
| `sql-database` | 4872 | `35e83224ae21a88dd6f94b6add0e57a1064b82b3f999ea6c0f320b38d623f471` |
| `connection-details` | 6060 | `3ffd8f29696018b4f0d4efd2ed51f64fceb74a97d3272aafe489d07f44f4e71b` |
| `development-and-production` | 12299 | `8591453dec478ae8db3e498f3da1cedb39c7754bab482af5a08747eab8b1305a` |

No supported second fresh managed database in this same Repl was established by
these bodies. Exact approved fresh target/ownership and supported provider actions
remain D07/D08 gates. Existing Payload target is not implicitly replaceable.

### Current field defaults and validation context (partial)

Native field metadata carries JSONB defaultValue/options/settings, nullable
configuration and relation target identifiers. Default serializer accepts native
function defaults, prequoted scalar strings, numbers/booleans, dates, arrays and
JSON objects; missing values become null. This generic serializer does not prove
that relation fields allow owner-UUID defaults or which function defaults are
valid. Field-type-specific default validation/schema application still untraced.

Evaluation context populates only expression identifiers, normalizes Date to ISO
and missing values to null (boolean false), uses native null/composite registries
and the supplied server-now value. It does not inject actor identity or previous
record state. Literal owner binding is a candidate, not a native "current user"
expression or arbitrary cross-record/history lookup. No expression evaluated.

| Input, original path | Git blob |
| --- | --- |
| `packages/twenty-server/src/engine/metadata-modules/field-metadata/field-metadata.entity.ts` | `86b010287dee663765feff83fb470b02439a4366` |
| `packages/twenty-server/src/engine/metadata-modules/field-metadata/utils/serialize-default-value.ts` | `50c1099daf4321b2a34dd9b05147d6afb5c3b2b4` |
| `packages/twenty-shared/src/utils/validation-rule/buildValidationRuleEvaluationContext.ts` | `c493b13832e28b0f705621dc94456d13f41f4993` |

### Typed default restriction continuation

Shared FieldMetadataDefaultValue mapping exposes native uuid/now functions and
currency amountMicros/currencyCode defaults. RELATION, MORPH_RELATION, FILES and
TS_VECTOR explicitly have no default value. Do not invent a native current-member
relation default or pass a UUID through the generic serializer to bypass this.
Private-object owner consistency needs a supported validation/creation interface;
generated form defaults alone do not enforce assignment. Timestamp function
availability is identified, not proof of registration/stamping/immutability.

Source: `packages/twenty-shared/src/types/FieldMetadataDefaultValue.ts`,
Git blob `bfede7273eddebb919acac4b7b334dfb986908fe`.

## Historical partial inventory — superseded generation

The findings below refer to the earlier pilot baseline and remain historical
unless individually reconciled above. Do not use them as current acceptance.

**P1.audit-model is incomplete.** This is static source inventory,
not runtime validation or a delivered permission system. Runtime and services
audits have not been admitted. No environment setup, install/build, database
operation, account creation, scheduler action or test was performed.

Source authority: the user approved the exact pinned fork commit
`7e1431c84adbb264db98ab8b8d008a8401b6d4d6`, source tree
`d1f8e9c24d494fc77b368ca42460f1a9838a7ed1`, and confirmed prior source rights.
The source repository URL and pilot recovery identities are in the
[execution ledger](crm-delivery-ledger.md). No missing pilot-local modifications
are claimed as recovered.

Execution was sequential by the main agent in the existing Nix container.
No subagent or separate checkout/build environment was used. Fifteen immutable
Git blobs totaling 275,290 bytes were exported for bounded static inspection;
each export's Git blob identity was checked against the complete source tree.
These provenance comparisons are source recovery, not application test evidence.
The ephemeral exports are not an authoritative Git checkout or release source.

## Blocking finding: native permission entitlement

The source root `LICENSE` distinguishes AGPL-covered code, MIT-covered packages
and files marked `/* @license Enterprise */`. Its commercial section permits
development/testing use without a subscription but conditions production use
on applicable terms and a valid commercial subscription/agreement; it does not
make every file AGPL-covered. This is an inventory of the source terms, not a
legal opinion about the user's entitlement.

The row-level permission predicate entity, service, filter-builder and
filter-resolution utility carry the Enterprise marker. The native predicate
service requires **both**:

1. `enterprisePlanService.isValid()`;
2. `billingService.hasEntitlement(workspaceId, BillingEntitlementKey.RLS)`.

Its upsert operation calls the entitlement check and throws
`ROW_LEVEL_PERMISSION_FEATURE_DISABLED` if unavailable. Its read operation
returns no predicates when the feature is unavailable. Therefore native
assignment-based row filtering cannot be assumed available solely because
the fork source is accessible or source modification rights are confirmed.

The Enterprise plan service uses signed key/validity information. Source
configuration includes `ENTERPRISE_KEY` and `ENTERPRISE_VALIDITY_TOKEN`; no
values were requested, read or configured. No license-validation network call
or billing/workspace query was performed.

**Decision required (D02/D04):** confirm applicable Enterprise RLS entitlement
for the planned deployment or an explicit agreement covering the marked code
and supported activation route. If absent or unknown, this branch remains
blocked. Do not remove entitlement checks, forge validity information, rename
licensed code to imply new rights, use direct metadata/database writes to bypass
the service, substitute client filtering or weaken broker access.

## Observed native interfaces

### Generated objects

`ObjectMetadataResolver.createOneObject` is workspace-authenticated and guarded
by `SettingsPermissionGuard(PermissionFlagType.DATA_MODEL)`. It passes the
workspace and typed object input to the native metadata service.

`ObjectMetadataService.createOneObject` resolves the workspace custom
application, builds flat object/field metadata and invokes
`validateBuildAndRunWorkspaceMigration` with `isSystemBuild: false`. For the
workspace-custom application it also prepares initial native view/view-field
and navigation metadata. Validation failure throws instead of yielding a
successful object. These are candidate native registration interfaces; no
object, generated form/table or record was created or accepted.

### Member identity and ORM

The native workspace-member entity exists and includes assignments/relations.
Its presence is not completion of member lifecycle, deactivation, revocation
or assignment validation. Those paths still require tracing.

`WorkspaceRepository.onBeforeExecute` applies row-level predicates and validates
query permissions. Predicate application covers the root query alias and joined
aliases. Operation-aware write filtering is also present. A privileged
`shouldBypassPermissionChecks` flag exists; browser/API paths must not receive it.
Missing workspace-member-bound predicate values become unsatisfiable branches
in the filter-builder rather than dropping the restriction.

This establishes a native enforcement candidate, **not universal proof**:
REST, GraphQL, direct lookup, relation traversal, aggregates, exports, attachments,
search, worker context and realtime each still need end-to-end static tracing
and final-phase negative acceptance.

### Other selected surfaces

The source exposes native record-permission queries and search/file surfaces.
Static excerpts identify search query builders, file redirects/streams and
record-export guards; these do not prove that every caller preserves current
actor/record authorization or revocation. File-by-ID guard, signing flows,
member lifecycle, record sharing and realtime remain untraced. Native sharing
has not been selected as an alternative to the approved assignment ACL.

## Immutable evidence manifest

Paths below are relative to the approved server component's `src/` unless
noted otherwise. They identify original source, not new owned product paths.

| Source input | Git blob |
| --- | --- |
| Repository root `LICENSE` | `085e0c6baf78a26688991d3f9a96a68a658c2662` |
| `engine/metadata-modules/object-metadata/object-metadata.resolver.ts` | `8891eee47df54f0867a3f957c88ea091d398fdf2` |
| `engine/metadata-modules/object-metadata/object-metadata.service.ts` | `807673bacfc1e1b66ce1487e48e44fd0ceca49ce` |
| `engine/metadata-modules/row-level-permission-predicate/services/row-level-permission-predicate.service.ts` | `4b40fe058fc013bd8468206e82702bf737522aad` |
| `engine/metadata-modules/row-level-permission-predicate/entities/row-level-permission-predicate.entity.ts` | `71d3361c95d69e3badcc22e84a36db530ddf8c26` |
| `engine/core-modules/auth/guards/enterprise-features-enabled.guard.ts` | `6b006daaee95c3cd1fd29202004373a7a626104a` |
| `engine/core-modules/enterprise/services/enterprise-plan.service.ts` | `3b48e3af7763d5dd7e56b4ad72dffe0bf12ccb86` |
| `engine/twenty-orm/repository/workspace-repository.ts` | `e64487cf7561faa27901730749a4e8fe0e14f93a` |
| `engine/twenty-orm/utils/build-row-level-permission-record-filter.util.ts` | `3695a603756a2cc647b8ff3269af9ec6a252a911` |
| `engine/twenty-orm/utils/resolve-row-level-permission-record-filter.util.ts` | `d4a7b1a0422aaeb749fc682f64ddef5202115ea4` |
| `modules/workspace-member/standard-objects/workspace-member.workspace-entity.ts` | `e487e3f9b2333dfe0af4418c3341b04ed3c8685e` |
| `engine/metadata-modules/record-permissions/record-permissions.resolver.ts` | `1c0fb166e64ab72fbc0d0ace6f59fb4bebecbd83` |
| `engine/core-modules/search/services/search.service.ts` | `e42a5eaab93c86aa167b524d4534616f38e1266f` |
| `engine/core-modules/file/files-field/services/files-field.service.ts` | `8e08d6b6cbfd7bdceb670c0df186ce886f8a76b7` |
| `engine/core-modules/file/controllers/file.controller.ts` | `fd545d3957edc7d45efe137d0613652608da41b0` |

One proposed singular row-level resolver path did not exist in the source tree.
It was not downloaded or treated as an interface. Resolve actual paths from
the authoritative source tree when the audit resumes.

## Resume boundary

Recorded entitlement decision and approved source generation must be reconciled
before re-admission. Remaining model tracing is still required; then admit
runtime and services audits sequentially and join all three before P1.freeze.
No source implementation, weakened ACL, database setup or early test is
authorized by this partial report.
