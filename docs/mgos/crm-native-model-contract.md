# Native audit completion — main joined read-only output

Source generation: d6e8c0255a7019741f623d838b18bd726dbe55dc. Main owns this report; no independent tests or implementation accepted by joining.

## Main correction from current native operation mapping

Do not carry forward the agent's historical `canCreateAllObjectRecords` claim
as a current native blocker: no such symbol occurs in current engine source.
Current `engine/twenty-orm/utils/is-object-operation-permitted.util.ts:18-28`
explicitly maps insert/update to per-object canUpdateObjectRecords and
restore/soft-delete to per-object canSoftDeleteObjectRecords. Current
object-permission.service.ts:264-305 uses read/update/soft-delete/destroy global
defaults and per-object overrides, not a create-all default.

Thus own-table create permission and no-broker restore have supported native
object-operation primitives; universal call-path coverage and insert rule/FK
consistency remain separate. Restore does not itself revalidate fields; this is
not proof of bypass if the stored row remains consistent, nor a universal pass.
Rule parser enables comparisons; relation target descriptors exist for many-to-one
fields, but exact compiled literal binding/evaluation is still unresolved.
No rule enabled/metadata mutated/test executed by these static discoveries.

Below is the original bounded agent inventory, preserved with this correction.

MODEL audit complete (read-only). Admission matched exactly: cwd `/home/runner/workspace`, `mnt:[4026532715]`, `pid:[4026532718]`, baseline `129:471472`, SHA256 `31aa2bc5e55392ce34ad58b3fa17c2922fc346ed4dfff083eeab13264de8a775`. The approved baseline manifest pins commit `d6e8c0255a7019741f623d838b18bd726dbe55dc`, tree `b356dbdb4f15fca5c6d93a4d2488b0c3b0460d8e`; the exported source has no `.git` metadata. No writes, tests, builds, startup, or external actions. Bounded to 12 focused native source bodies.

**Validation-rule availability and coverage**
- `packages/twenty-shared/src/types/FeatureFlagKey.ts:15` defines `IS_VALIDATION_RULES_ENABLED`. `packages/twenty-server/src/engine/metadata-modules/validation-rule/validation-rule.resolver.ts:52-55,68-107` gates rule query/create/update/delete by that workspace feature flag; rule mutations additionally require `DATA_MODEL`. No Enterprise entitlement check is present in these inspected rule interfaces. `workspace-orm.manager.ts:165-168` conditions rule-map loading on the same flag. Thus the stock, non-Enterprise code path exists; a supported production/operator interface for enabling the flag was not established in this bounded audit.
- `validation-rule.service.ts:147-188,196-248` compiles native expressions and migrates rule metadata. `validate-records-against-validation-rules.util.ts:67-119,144-246` can resolve dotted bindings through a `MANY_TO_ONE` join and evaluates active rules on written-record snapshots. The related-record lookup bypasses read permissions internally and excludes soft-deleted target rows (`:35-64`); that is an internal evaluation path, not an authorization grant.
- `workspace-repository.ts:775-805,1012-1016,1121-1124` wraps inserts and batch updates in the validation mechanism. `runMutation` only wraps `kind === 'update'` (`:1610-1631`); `softDelete` and `restore` invoke other mutation kinds directly (`:729-755`) and do not receive this validation callback. So rule coverage is insert/update, **not soft-delete/restore**. Rule failure is inside the transactional write path (`:767-805`).
- **FK consistency remains a hard blocker, not a demonstrated native solution.** Dotted many-to-one paths are supported, but this inventory did not establish the exact relation-ID/literal equality operator and target-member identifier binding needed to reject a forged per-object broker/member FK. The rules have no authenticated-actor context (existing audit `docs/crm-source-audit.md:661-665`), so they cannot dynamically mean “the current broker.” Existing typed-default inventory says `RELATION`/`MORPH_RELATION` have no default (`:675-679` in that audit): no native current-member relation default was found. A per-object literal rule may be a candidate only if its supported equality/ID binding is confirmed; it is not acceptance evidence.

**Native personal-object and permission interfaces**
- `object-metadata.resolver.ts:360-376` exposes workspace-scoped `createOneObject`, guarded by `DATA_MODEL`; the existing source audit records that this creates generated metadata/views and derives table identity from the object, not the viewer (`docs/crm-source-audit.md:80-103`). This is the native generated-object API, not a personal-table ownership feature.
- `role.resolver.ts:71-105,131-159,296-323,365-392` exposes native role/member-role assignment and role-scoped object/field permission upserts. `object-permission.service.ts:115-128,208-229` persists per-role/per-object read, update, soft-delete and destroy grants through validated native migrations. **There is no per-object create grant in that input**; the existing source audit notes the role-wide `canCreateAllObjectRecords` model (`docs/crm-source-audit.md:86-99,101-117`). Consequently native object grants can express read/edit separation, but own-table-only create is not established by this interface; role-wide create is a scope hazard until its generated API enforcement is traced. Per-member roles/object grants are a supported native direction, not proof of end-to-end isolation.
- `field-permission.service.ts:368-379` explicitly allows field permissions only to restrict read/update; they cannot grant access. They can help deny broker edits to selected fields but do not provide ownership, defaults, or a server-side member binding. A restricted `assignedAt`/member field plus an unverified FK rule does not satisfy the consistency contract.

**Archive/restore and settings**
- Per-object role permissions distinguish soft-delete from permanent destroy, so a broker role can be configured without soft-delete while a manager/admin role is granted it (`object-permission.service.ts:115-128`). This supports the no-broker-archive side at the metadata level. The inspected API does not expose a separate restore grant, and ORM restore has neither validation coverage nor a traced role/record authorization route. Manager-only **restore** is therefore unresolved; permanent delete remains unapproved and must stay denied.
- `DATA_MODEL` and `ROLES` settings guards exist for metadata and role management, but no existing native typed/shared workspace setting interface was identified here for calculator fee, currency, and reporting timezone with admin-write plus broker/manager-read grants. Do not infer that ordinary object/field permissions secure those existing settings surfaces. Exact blocker: identify a supported existing native settings model/API and its role enforcement; no added object or custom settings page is justified.

**Files and cross-surface enforcement**
- `file.controller.ts:240-255` serves `/file/:fileFolder/:id` under `FileByIdGuard` plus `NoPermissionGuard`. `file-by-id.guard.ts:36-79` checks supported folder, bearer token validity, token workspace and file-ID match, but does not resolve a parent record, current actor/member, or object permission. `file.service.ts:152-195,198-235` looks up the file by workspace/folder and redirects to a storage presigned URL when available. This is a workspace/file-scoped signed bearer path, **not demonstrated parent-object ACL**; signed delivery also bypasses later server authorization until the URL expires. Parent authorization before token issuance/signing and revocation behavior remain unproven.
- Universal enforcement is not established. Known ORM permission-bypass/internal snapshot interfaces exist (`workspace-repository.ts:1592-1607`; validation snapshots above); metadata object listing is an authenticated workspace query (`object-metadata.resolver.ts:95-137`) rather than a proven sensitive-metadata filter. This bounded inventory did not prove every generated GraphQL/REST read/write, relation expansion, search/count/aggregate, export download, metadata/settings query, or realtime/subscription path uses the intended per-member role policy. The existing audit explicitly leaves universal path tracing and negative acceptance open (`docs/crm-source-audit.md:101-117,773-785`). No universal-bypass claim should be made.

**Disposition:** Supported native primitives are generated object creation, role assignment, per-role/per-object read/update/soft-delete/destroy grants, restrictive field permissions, and feature-flagged validation on inserts/updates. Hard blockers are scoped create permission, exact server-side literal member-FK enforcement (including supported relation operator), restore authorization/validation, existing typed settings authorization, file parent-object ACL, and end-to-end API/metadata/export/realtime enforcement. No general legal/ownership gate is repeated.
