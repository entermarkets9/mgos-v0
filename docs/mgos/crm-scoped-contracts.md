# Scoped CRM — implementation contracts

**Parent:** [Canonical roadmap](crm-scoped-delivery-plan.md).  
**State:** Explicit user approvals are recorded in the amendments below; other refinements remain pending the stated owners. Fields/status labels/topology are requirements, not proof of native capability. No implementation command or assumed product choice is approved here.

### Approved native Enquiry-model amendment — 2026-10-11

The user approved separate native Enquiry objects per broker, with shared
Property/Listing and manager-only unassigned intake, using native object-level
roles without Enterprise-gated feature activation. This replaces the original
exactly-three-object-count requirement: there are three domain types, but
Property + Listing + intake Enquiry + one Enquiry object per broker.
Broker identity remains a native workspace member, never a Broker object.
The source baseline is [`crm-source-baseline.json`](crm-source-baseline.json).

Only the model direction is approved. Exact schema/lifecycle, default-deny
native role composition, generated inverse relationships, manager aggregation,
native atomic transfer and stable identifiers/references remain source/product
gates. No custom CRUD pages, custom ACL service, permission bypass, separate
workspaces, DB setup, accounts or provider/live actions are authorized by this
amendment. All tests remain in the final phase.

## 1. Metadata realization (D03; source + database owners)

Use the **verified native workspace metadata framework** with `CreateOneObjectMetadataInput`, not source-defined standard objects or handcrafted tables/forms. The symbol is specified in the locked target but its exact source interface/permissions at the approved fork are not inspected yet.

Before realization record the exact input schema, object/field metadata mutation and upgrade APIs, relation/inverse definition, supported field types, role/permission interfaces, generated UI/SDK/cache path and failure/rollback behavior at the full SHA. Stop if unavailable; do not substitute direct DDL or manual custom CRUD.

Registration contract:

- Exactly the approved Property and Listing identities plus intake/per-broker Enquiry identities from the amendment above; no Broker or other new domain type. Native technical metadata/audit/read-state support is not an additional domain object. Any other data-store/table/module beyond supported native mechanisms requires explicit review.
- Stable native object/field/record IDs, workspace-qualified by native tenant identity. Persist these in a versioned registration ledger; label changes must not regenerate IDs.
- Distinguish absent object, existing compatible object and conflicting metadata. Serialize registration/upgrades per approved workspace; re-execution must not create another object/field/relation or erase existing data. Record ordinary action state, not acceptance.
- Allowlist expected metadata/schema changes, cache invalidation and SDK regeneration. Registration rollback disables/deprecates or uses the verified reversible native mechanism; destructive removal needs data/lifecycle approval.
- All existing and future workspaces intended for v2 receive the approved metadata version through supported provisioning. Do not create workspaces/accounts as tests before final phase.
- No external provider IDs/import keys required in v2. Native workspace+record UUID (or verified native stable ID) is authoritative; never map Payload numeric IDs or names into it. If later authorized imports need IDs, use environment/source/tenant-qualified unique identifiers then, not current ingestion fields.

### Approved calculator arithmetic/settings amendment — 2026-10-11

The user approved:

- Net return counts purchase price once: `100 × (annual rent − annual total
  service charge) / (purchase price + acquisition fees)`.
- Annual rent and annual total service charges; initial currency AED.
- Initial agency fee **2% of purchase price**.
- Initial conveyancing fee **AED 2**, exactly the entered fixed-amount answer;
  not 2%, AED 2,000 or an illustrative historical fee.
- Currency must be mutable, and **all fee placeholders must be mutable in
  settings**. This includes the initial **4%** DLD rate: it is an editable
  default, not an immutable constant after this explicit amendment.

Gross yield remains `100 × annual rent / purchase price`. Acquisition fees are
the current configured DLD percentage of price, agency percentage of price and
fixed conveyancing amount. The settings source must be native and scoped, with
authorized editing and unprivileged access only to validated non-secret
calculator defaults. No generic custom settings/CRUD page or extra domain
object is approved.

Currency editability is not authorization for live FX APIs or silently changing
persisted Property/Listing money. Preserve stored currency codes until an
explicit authorized record edit. Fixed monetary fees and calculation amounts
must use a consistent explicit currency; no automatic conversion, mixed-currency
arithmetic or silent zero-fee fallback. Exact supported settings mechanism,
currency-change behavior, field/display precision, rounding and persistence
details remain to be frozen after source inventory.

Earlier alternative formulas/illustrative fee examples in §5 are historical
comparison material; they are not configured defaults or approval to implement
the double-price denominator. A07 must cover changing fee/currency settings.

### Approved dashboard fields/reporting amendment — 2026-10-11

The user approved two additional native fields, not another domain object:
`assignedAt` on each Enquiry model (assignment timestamp), and
`expectedClosingDate` on Listing (expected closing calendar date).
Native representations, trusted timestamp writes and transfer lifecycle must
be reconciled with the approved source before realization.

The four approved card rules are:

- **Leads assigned today:** currently assigned authorized enquiries whose latest
  assignment falls in today's reporting window, including **New, Contacted and
  Closed**. Count records, not each transfer event. Unassigned intake has no
  current assignment and does not enter this count.
- **Deals closing this week:** distinct authorized **Under Offer** Listings with
  an expected closing date in the reporting week. No substitution of listing
  date, general updatedAt or Closed Enquiry status.
- **Active listings:** distinct authorized Listings with status exactly **Active**;
  Under Offer is not included in this card.
- **New enquiries:** authorized enquiries with status exactly **New**, not an
  unread/recently-created proxy or an implicit time window.

Reporting initially uses **Asia/Dubai**, with **Monday** as week start. The user
explicitly requires the **reporting timezone to be mutable in settings**.
The parenthesized instruction is not part of the IANA timezone identifier.
Use validated named timezones, native scoped settings and authorized editing;
brokers may read the typed reporting setting without receiving settings-write
permission. Invalid/missing configuration must produce an explicit error, not
silently switch to browser timezone or UTC.

Changing the reporting timezone recomputes day/week boundaries and invalidates
affected dashboard results. It must not rewrite stored assignment instants or
calendar closing dates. Use half-open reporting windows; distinguish native
calendar-date filtering from UTC timestamp filtering.

These approvals resolve the above D03/D05 field/reporting choices, not inbox
follow-up/alert/read-state capability, inventory access policy, timestamp
integrity, metadata registration, database setup, fixtures or final acceptance.

### Approved shared-inventory editing amendment — 2026-10-11

The user explicitly permits brokers to **create and edit all shared Property
and Listing records**, including records created by another broker. Brokers
also read shared inventory. Enquiry write/lifecycle rules remain separately
defined by the D04 matrix; this decision does not expand them.
Do not infer creator-only inventory ownership or add an unapproved owner field.
Use native object-level read/create/update permissions for the shared scope.

This approval does not permit cross-broker Enquiry access, transfers, archive,
delete/restore, role/member management or settings changes. Those permissions
remain separate lifecycle/administration gates. Website/Payload inventory and
routing are not synchronized or modified by CRM inventory edits.

### Approved archive/restore and settings administration — 2026-10-11

Only managers and administrators may archive or restore CRM records. Brokers
may not archive or restore their own Enquiries or shared Property/Listing
records. Permanent deletion remains unapproved, including for managers/admins;
no cascading deletion, cleanup activation or retention schedule is authorized.
Native authorization, dependency handling and restore/count behavior remain
source/lifecycle gates, not implied by this product decision.

Only administrators may edit shared calculator fees, currency settings and
dashboard reporting timezone. Managers and brokers need authorized read access
for calculations/reporting, not settings-write or application-management powers.
Use existing native settings surfaces; no generic custom settings page is added.

### Approved broker-private Enquiry writes — 2026-10-11

Brokers may create and edit their own private Enquiries. This does not permit
reading/writing another broker's Enquiries, accessing intake, claiming unassigned
records or transferring assignment. Table ownership, assignment and assignedAt
must remain consistent server-side, including direct/bulk API requests.
Native validation/stamping and actor/role revocation remain capability gates.

### Approved Property types and initial statuses — 2026-10-11

Property type is a native dropdown with exactly Apartment, Villa, Townhouse,
Penthouse, Duplex, Land, Office, Retail and Warehouse. Newly created Property
and Listing records default to Draft; every intake/private Enquiry object
defaults to New. This does not change the previously locked status sets.

These approvals resolve allowed type values and initial statuses, not native
registration/default enforcement, requiredness, field limits, price/currency
precision, lifecycle transitions or setup permissions.

## 2. Three-domain-type field and lifecycle contract (D03; product/data + source owners)

The following labels/enums/relations are **locked**. Property type dropdown values and Draft/Draft/New initial statuses are approved above. Remaining native representations/defaults, requiredness, precision, length limits and currency policy need D03 resolution before implementation. Proposed types below are recommendations, not native schema assertions.

| Object | Locked field | Proposed native representation / outstanding decision |
| --- | --- | --- |
| Property | title | Text; propose nonblank required display label; product approves max length |
| Property | type | Approved native dropdown: Apartment, Villa, Townhouse, Penthouse, Duplex, Land, Office, Retail, Warehouse; native stable option representation/enforcement still to realize |
| Property | community | Native text/select supported by framework; no fourth Community object or external location API |
| Property | bedrooms | Nonnegative integer, including 0 studio if approved; nullable policy/upper bound unresolved |
| Property | price | Decimal/native monetary field; currency/scale and null/zero policy D03/D06; no binary floating currency persistence |
| Property | status | Exactly **Active, Draft, Under Offer**; approved initial Draft; native machine values/default enforcement still to realize |
| Property | description | Native text/rich text supported by source; sanitization/length/optional policy agreed |
| Listing | Property relation | Many Listings → one Property; inverse Listings collection on Property; propose required same-workspace reference |
| Listing | status | Exactly **Draft, Active, Under Offer, Sold, Let**; approved initial Draft |
| Listing | price | Independent native decimal/monetary value; no automatic Property-price overwrite/inheritance unless approved |
| Listing | listing date | Native date or timestamp chosen by D03/D05; semantics/timezone explicit |
| Listing | expectedClosingDate | Approved additional native expected closing calendar date; used with Under Offer for the weekly card |
| Enquiry | Listing relation | Many Enquiries → one Listing, inverse Enquiries collection; propose required same-workspace reference; standalone/general enquiries not silently added |
| Enquiry | broker assignment | Native workspace-member relation, not custom Broker object; nullable state and assignment permissions D04 |
| Enquiry | buyer name/email/phone | Native appropriate text/email/phone; required contact combinations, normalization, country-code/format and max lengths D03/privacy |
| Enquiry | message | Native text, length/validation/optional policy approved |
| Enquiry | status | Exactly **New, Contacted, Closed**; approved initial New for intake and all broker-private objects |
| Enquiry | assignedAt | Approved additional native assignment timestamp; latest current assignment, not general updatedAt; intake unassigned state has no current assignment |

Native timestamps/creator/editor/audit/attachment support may remain if present and approved. The two dashboard fields above are explicitly approved; other close/follow-up/history/import fields still require a product decision.

### Proposed lifecycle to approve, not silently apply

Owners must sign a transition/operation matrix for each status and role. Until then:

- Generate native create/view/edit and native delete/archive actions only; don't hide missing backend behavior behind UI filters.
- Proposed conservative default is archive parents with dependent children, reject physical delete while referenced, and never cascade-delete enquiries or buyer information accidentally. Whether archive is natively supported and how restores affect relations/counts is unresolved.
- Required references reject null/missing/cross-workspace IDs, archived targets (unless explicitly permitted) and unauthorized attachments. Relinking preserves record identity and atomically applies effective scope; no cross-workspace relink.
- Property status and Listing status are distinct; Sold/Let does not automatically change Property to an invented Sold status. Closing Enquiry does not imply closing a deal. No automatic cross-object transition without an approved rule.
- Price/relationship edits must not silently change calculator assumptions or historical enquiry content.
- Assignment and status changes have native audit evidence with actor/time/before/after, retained under D11. No arbitrary status string or forged creator/role accepted via APIs.

**Observable acceptance A04:** Shared Property/Listing and each approved intake/broker Enquiry object appear once with generated forms/filters/detail pages; approved requiredness/types/enums/defaults enforced on UI and server; create/edit/read/archive/delete/restore conform to approved matrix. Navigate Property→multiple Listings→permitted Enquiry objects and inverse links; invalid/cross-workspace references fail; IDs survive edits/restart/version registration. No custom CRUD pages, Broker object, unrelated domain objects or integrations.

## 3. Brokers, shared workspace and server authorization (D04/D09)

**Identity:** One supported shared workspace; broker is the approved native CRM user/workspace-member identity with broker role. Manager/admin are explicitly permitted native roles; security must determine whether manager and admin share access rights or differ. A CRM login identity is not a Payload TeamMember profile, email match or display name. No automatic account creation/linkage, staff copy or custom broker-management page.

**Capability gate:** Source maintainer/security must prove the pinned native model supports broker isolation at every path, including aggregate/relation/attachment operations. Under the approved separate-table amendment, default-deny object-level roles are the candidate boundary; ordinary workspace membership or a filtered personal view is insufficient. Enterprise-gated activation is excluded. Native role composition and consistency between table ownership, displayed assignment and permitted reassignment must be proven; unsupported transfer/lifecycle blocks implementation. Separate workspaces/custom ACL service are not implicitly approved.

### Proposed permission matrix for owner approval

This is a complete candidate policy, not a decision filled in for the user. D04 must approve/replace each cell before exposing data.

| Operation/path | Broker candidate | Manager/admin candidate |
| --- | --- | --- |
| Enquiry read/list/search/export/count/inbox | Only assigned to own active native member | All permitted workspace enquiries including unassigned |
| Enquiry create | Approved own private Enquiries only; assignment must remain self/table-owner, no forged roles | Create/assign to active eligible broker or leave unassigned |
| Enquiry edit/status/attachment | Approved own private Enquiry create/edit/status within lifecycle/field policy; attachment handling still source-gated | Workspace scope, audited |
| Enquiry assign/unassign/reassign | No transfer to another member; explicitly decide self-assignment of unassigned records | Authorized reassignment with audit |
| Enquiry archive/restore | Denied, including own assigned records | Approved managers/admins only, subject to native/dependency contract |
| Enquiry permanent delete | Denied / unapproved | Unapproved; no cascading deletion |
| Property/Listing read/search/detail | Approved shared workspace inventory, not only relations reachable from own enquiries | Workspace inventory |
| Property/Listing create/edit/price/status | Approved all shared records, including records created by other brokers; native read/create/update grants | Shared workspace records |
| Property/Listing archive/restore | Denied despite shared create/edit permission | Approved managers/admins only, subject to native/dependency contract |
| Property/Listing permanent delete | Denied / unapproved | Unapproved; no cascading deletion |
| Shared fees/currency/reporting timezone settings | Read authorized values only; no settings edit | Administrator edit only; managers read only |
| Member identity/role edit/invite/deactivate | No privilege/other-member management | Supported native admin capability only |
| Dashboard aggregates/alerts/read state | Same record predicate; no counts/titles from another broker | Approved workspace aggregates/alerts; read-state policy D05 |
| Attachment signing and delivery | Same parent authorization, checked server-side before key lookup/signing | Same workspace/lifecycle scope |

Native list/detail REST, GraphQL queries/mutations/subscriptions, metadata (where sensitive), global search, filters/autocomplete, count/aggregate, export, relation expansions, attachment access/signing and realtime updates must apply the **same server policy before returning data or effects**. Permission denial may be not-found or forbidden per approved anti-enumeration policy. No cross-broker IDs/titles/email/phone/count leakage in errors, nested records or dashboard.

### Assignment/lifecycle decisions required

- Unassigned enquiries: proposal manager-only, never silently all-broker-visible. Decide broker claim workflow if supported; no custom allocation UI.
- Reassignment: require active target membership in same workspace; atomic update/audit. Former broker loses future record/search/aggregate/read-state/realtime/attachment access; new broker obtains agreed scope. Cached data/subscriptions must invalidate. Previously downloaded data cannot be revoked; signed URLs have bounded residual exposure.
- Deactivation: revoke sessions/native tokens, role/membership and subscriptions per native capability. Proposal manager retains enquiry ownership history, must explicitly reassign/unassign; never orphan/delete customer records or allow assignment to inactive user.
- Manager access: same-workspace only, including unassigned; cross-workspace access still denied. Manager override/audit authority explicit.
- Record visibility after parent archive/relink, manager demotion, assignment change and member deletion must be specified. A native relation to a deactivated member must remain interpretable or have an approved history-preserving treatment.

**Acceptance A05:** Two synthetic brokers, manager/admin and second workspace exercise every positive/negative operation above through UI and all server paths. Forged assignment/role, unassigned disclosure, relation/aggregate/subscription leakage, deactivated token and stale cache denied. Native broker lifecycle/invitation behavior tested, not a fourth object's CRUD.

### Authentication diagnostic/preparation contract

**Setup-sequence amendment:** The user approved compiling untouched stock source
and native synthetic account/workspace bootstrap before metadata/customizations.
Execute only after exact fresh-target, identity, environment/resource and
side-effect approvals. Native setup accounts/prefill are ordinary setup state,
not final login/UAT evidence. Acceptance signup diagnostics, additional test
accounts/fixtures and login verification stay in Phase 7. No real-data/provider/
production action or permission bypass is inferred.

D09 traces native `signUpInNewWorkspace` token request/verification/issuer/audience/type, refresh/revocation, workspace bootstrap guards and activation commands. Determine real cookies versus browser-token storage; no guessed cookie API. Website keeps host-only `maingate-cms`; CRM uses distinct native signing secrets and origin/storage scope, no parent-domain cookie, SSO or shared signing key.

Approve bootstrap administrator, allowed signup/invitations, email verification/reset provider and domain, anti-abuse/CSRF/CORS/redirect policy. Synthetic logger-email settings are final synthetic fixtures only; production invitation/reset acceptance requires actual approved delivery behavior. Native invite/admin operations are not approval for custom user/settings pages.

In final phase, capture sanitized request IDs/status/error/action state, never credentials/token values. Resolve auth rejection first; only after successful auth inspect activation locks/transactions. Narrow evidence-supported fixes preserve native guards, completed actions/effect markers and lock ownership. Another clean signup after failure requires separately approved attributable fresh scope; no ambiguous Retry/reset.

## 4. One dashboard contract (D05; product + security owners)

Route `/dashboard` on CRM host only. Exactly two zones/four cards and one inbox. UI must work with native object generated routes and current role, include loading/empty/error/denied states, be keyboard usable and adapt to narrow screens. No duplicate notification center or extra dashboard objects.

### Approved card definitions; source realization still pending

| Locked label | Intended scoped query | Missing source/decision; no silent substitution |
| --- | --- | --- |
| Leads assigned today | Currently assigned authorized Enquiries, latest assignedAt in today's window; New/Contacted/Closed included | Trusted assignment timestamp/transfer integrity and native scope/filter implementation pending |
| Deals closing this week | Distinct authorized Under Offer Listings whose expectedClosingDate falls in the reporting week | Approved native calendar-date field; no listing-date/follow-up/Closed Enquiry substitution |
| Active listings | Distinct authorized Listings with status exactly Active | Broker inventory scope still requires approval; no Under Offer or Property-status proxy |
| New enquiries | Authorized Enquiries with status exactly New; no implicit date window | No unread/recent proxy; native deleted/archive exclusion must be reconciled with lifecycle |

Each returned value must reconcile to an authorized native filtered record set; no exposed global total to broker, double count by join, hard-coded demo count or fabricated zero on error. If a source isn't natively available under locked fields, block that card and request a product scope/source decision **before implementing the dashboard**, not ship an empty placeholder and call it complete.

Timezone/day/week: approved initial Asia/Dubai, mutable through native settings, Monday-start calendar week. Use half-open `[start, next start)` timestamp-query boundaries derived from that timezone; compare calendar dates with the corresponding local calendar window. Define DST behavior without rewriting persisted instants/dates. A06 final fixtures cover midnight/week rollover and timezone-setting changes; the named zone comes from explicit approval, not inferred location.

### Inbox and native read state

- Brokers: own permitted enquiries and native follow-ups only; managers/admins: agreed all-workspace permitted items plus supported native system alerts.
- D05 names exact native follow-up source and association, due/overdue/completed handling, event timestamp, dedup key and kind whitelist. If absent, no extra custom task/follow-up object by assumption.
- D05 lists native supported alert types/roles/privacy/expiry/record targets. No imported provider activity, invented alert service or custom notifications page.
- Each row has type icon + accessible label, title, chosen timestamp, mark-read button and authorized jump-to-record. Native system alerts without record target need explicit product choice (native target or exclusion); do not create dead links.
- Proposed ordering: newest event first, stable ID tie-breaker, bounded cursor pagination/page size; product approves due-follow-up priority/limits. Realtime invalidates/refetches authorized data without duplicate rows.
- Read-state decision: propose **per native member**, keyed by workspace/member/native event, idempotent mark-read with ownership enforced. Not a global Enquiry `read` flag. Determine actual supported native state storage/API and whether readers can unread/mark-all (not locked, do not add).
- Mark-read changes only approved read state, not Enquiry status/assignment, and persists after refresh/restart; second device reconciles. If supported native read state is absent, stop for explicit backing-mechanism approval; no fourth domain object.
- Reassignment prevents old-member feed/item/record access; decide whether new member begins unread. Native event history must not leak prior broker private items.
- Deleted/archived/now-unauthorized jumps show honest unavailable/denied behavior; recheck server ACL at click and read-state mutation. Do not return stale titles/customer content after losing access.

**Acceptance A06:** Four card values match signed-off synthetic counts and boundary examples for broker/manager; follow-ups/alerts match approved native sources. Row icons/title/time/jump/read actions, pagination, read ownership/idempotency/multi-device/persistence and assignment invalidation work. Other-broker/workspace and unassigned items/counts remain denied under A05.

## 5. Property calculator arithmetic (D06; product/finance approver)

Locked inputs: **price, expected rent, service charge, bedrooms**. Outputs gross yield/net ROI; display agreed fee breakdown. Local pure arithmetic, no external APIs/AI/provider/bedroom estimates. Decide whether inputs prefill Property fields and edits are ephemeral versus explicitly save approved fields via native permissions; silent autosave is not approved.

Units to approve:

- Currency, proposed AED with decimal money precision; no FX/cross-currency arithmetic.
- Price is purchase amount, positive for a computable yield. Rent frequency (annual versus monthly ×12); service charge annual total versus monthly ×12.
- Website service charge is per sqft/year, but this is **not** an approved CRM/calculator unit. Per-area input needs area absent from the four locked inputs; stop rather than infer size.
- Bedrooms integer/nonnegative or approved nullable value; not a multiplier in any supplied formula.
- DLD assumed fixed 4% of price by the target. Confirm which fees are fixed currency amounts versus percentages and where agency/conveyancing values come from without adding unapproved UI inputs. No zero-fee defaults unless finance explicitly chooses them.
- Display precision/rounding (proposal two percentage decimals, decimal arithmetic, round final display only), range/max input, blank/error behavior and negative net-return display require approval.

### Apparent double count — explicit decision

Let `P` = purchase price, `R` = annual rent, `S` = annual total service charge, `A` = agency fee amount, `C` = conveyancing fee amount, `F = 0.04P + A + C`.

| Option | Formula | Meaning |
| --- | --- | --- |
| Literal source | upfront cost `U=P+F`; net ROI `100(R−S)/(P+U) = 100(R−S)/(2P+F)` | Purchase price counted twice; must not label it standard net ROI without finance approval |
| Candidate correction: fees only | upfront fees `U=F`; net ROI `100(R−S)/(P+F)` | One purchase amount + fees; change to source requires explicit product/finance decision |
| Candidate correction: total acquisition | upfront cost `U=P+F`; net ROI `100(R−S)/U` | Same arithmetic as fees-only alternative, different displayed term; requires explicit decision |

Do not silently select a corrected formula or implement literal double count as settled financial advice. D06 records chosen formula/naming plus whether taxes, vacancy, maintenance, financing/insurance or selling fees remain excluded. The target includes rent/service charge and specified acquisition fees only; no extra financial model or standalone analysis page.

### Known arithmetic examples — comparison fixtures, not signed-off outputs

For explicit hypothetical annual AED inputs `P=1,000,000`, `R=80,000`, `S=12,000`, bedrooms=2, **fixture assumptions** `A=20,000`, `C=5,000`:

- DLD=40,000, `F=65,000`, total acquisition `P+F=1,065,000`.
- Gross yield = **8.00%**.
- Literal net = `68,000 / 2,065,000 ×100` = **3.292978…%**, proposed display **3.29%**.
- Either correction net = `68,000 / 1,065,000 ×100` = **6.384976…%**, proposed display **6.38%**.
- Monthly equivalents rent=`80,000/12`, charge=1,000 annualize to these same outcomes **only if approved precision/period policy permits**.
- With annual charge=80,000, net is **0%** under either formula; charge=90,000 gives negative net (literal −0.484261…%, corrected −0.938967…%); approve display, do not silently clamp.
- Rent=0 with valid price gives gross **0%**; P=0/missing/negative or nonfinite input must give a validation error/not-computable, never Infinity/NaN or misleading 0%.

A/C are illustrative comparison values, not approved default fees. D06 signs exact expected outputs/rounding after choosing formula/units. Validation rejects malformed/exponential overflow/nonfinite/negative money inputs and incompatible currencies; missing fee/period choices block computation. A07 covers zero rent, positive/zero/negative net, blanks, extremes, decimal rounding and changing bedrooms without changing return.

## 6. Database/migration/environment contracts (D07/D08/D09)

### Isolation and preservation

Approve fresh synthetic Replit PostgreSQL in this same Repl; both CRM and synthetic Payload fixtures ultimately share **that same database** under separate identities. Initial CRM-only setup can be bookkeeping, not shared coexistence proof. Preserve real Payload connection, config, tables, data, migration history and media; any final target change requires separate decision/approval.

| Principal | Permitted proposed authority | Forbidden |
| --- | --- | --- |
| Website runtime | Existing required website-owned DML/function access | CRM private objects, role escalation, general DDL |
| CRM API runtime | Approved core/workspace DML and required helpers only | Payload/private website objects; unrestricted CREATE/SET ROLE/migration authority |
| CRM worker runtime | Native job-required DML/helper/storage access, separately scoped identity | Website objects and migrator/admin authority |
| Website migrator | Controlled website-owned schema upgrades only | CRM private DDL unless explicit shared-object approval |
| CRM migrator/provisioner | CRM core/workspace ownership under serialized approved scope | Unapproved website/public objects, unrestricted runtime delegation |
| Shared helper owner | Only approved extensions/functions, narrowly granted execution | Unreviewed CREATE OR REPLACE on website-owned `public` |

Names/schema sets are resolved from the approved source/catalog, not assumed `stripe` exists. Inventory definitions/owners/ACLs for tables, columns/types/defaults, indexes/constraints, sequences, triggers, policies, functions, extensions and role memberships. Search path is never isolation. Apply existing grants and creator-specific default privileges **FOR ROLE**, including new workspace schemas; review CREATE/database/schema rights, SET ROLE, function security/search paths and cleanup ownership.

If verified initializer requires `public.unaccent_immutable`/extensions, either approve explicit shared objects/owner/access and website impact or source-supported isolated helper with all references updated; no unmodified bootstrap on real website DB or blanket `public` prohibition that makes initialization impossible.

### Controlled execution

Exact commands remain **UNRESOLVED pending D01/D08**. Future ledger row must specify SHA/interface/command, target/role, allowed diffs, transaction boundaries, lock domain/key, bounded wait/error/lock-loss, ordinary postconditions/action ledger, safe retry classification and abort evidence. Never copy container entrypoint that upgrades/registers cron and swallows errors.

Database-level exclusion covers CRM/website migration, workspace provisioning and restore within shared target; native per-workspace activation may need narrower nested lock with documented order. Runtime/API startup has no migrations/cron registration. A metadata mutation doing dynamic DDL must use supported bounded authorized provisioning, not unrestricted role inheritance/guard bypass. Missing provider/privilege/Publish support blocks it.

Managed production: owner follows supported Publish schema flow; no direct Agent production DDL, new startup/deploy-build migration hook or custom production migrator. Existing Payload `.replit` migration build hook and post-merge schema/media/seeding behavior need reconciliation, not automatic reuse. Do not invoke website post-merge as CRM setup.

### Sealed process configuration

Allowlist environment **names** and exact source mappings for gateway, website, API, worker, migrators separately. No `...process.env` propagation or website URL/key fallback. Example target/source names to verify: `PG_DATABASE_URL`, `PG_POOL_MAX_CONNECTIONS`, `SERVER_URL`, `NODE_PORT`, `APP_SECRET`, `DISABLE_DB_MIGRATIONS`, Redis/storage/email/signup variables; listing names is not proof of support.

Website alone retains `PAYLOAD_SECRET`, required website provider config and App Storage identity. CRM API/worker receive only scoped DB/Redis/Backblaze/native auth/job config. Migrator credentials never reach API/worker. Gateway receives routing config, no business/provider credentials. Worker receives no Replit ambient identity or whole workspace secret set.

Resource identities distinguish editor/synthetic staging/actual production. External worker connectivity to app-local dev database is unresolved; verify provider-supported network/TLS requirements in final phase only. Never weaken certificate verification, use retired URLs or silently switch providers.

**A08/A12 proof:** Shared synthetic full definition/catalog diffs and controlled data hashes, runtime cross-read/write/DDL/role negatives, approved workspace/upgrade/recovery boundaries and lock-loss handling. Production observations tolerate legitimate website writes; no global row-count/max-timestamp “checksum.”

## 7. Gateway, supervision, artifacts and branding (D02/D10)

One public listening gateway at configured external port; separate loopback/private website/Payload and CRM children (5100/5101 proposed, exact map D10). Isolated website Node20/npm and exact compatible CRM Node24/Yarn binaries/dependency trees in same Nix container; exact patch/build/package-manager/lockfile/OS/ABI pinned after source verification. No global website runtime replacement or duplicate independent CRM publication.

Gateway contract:

- Normalize valid authority/host (case/port handling), reject malformed/multiple/unknown/spoofed authorities with chosen explicit 400/421/404 policy. Exact `maingate.ae`/`crm.maingate.ae` map; `www`/preview/health aliases only explicitly approved. No wildcard suffix/default backend.
- Only trust forwarded origin/client/proto from confirmed platform ingress; strip/reconstruct client-supplied forwarding headers. Correct HTTPS Host/Origin/redirect/auth callback, no leaked private ports. Define CSRF/CORS/native proxy trust on actual transport.
- CRM host owns `/`, `/dashboard`, generated record deep links, assets, REST/GraphQL/metadata and realtime endpoints. Website host retains existing `/api` and `/admin`; no cross-app path collisions, `/crm`, iframe or SPA fallback into another app/API/admin.
- Preserve streaming/backpressure/range/large transfer and WebSocket upgrades/SSE/subscription reconnect; configurable connect/read/body/idle limits and graceful drain. Forward required upgrade headers correctly while stripping other hop-by-hop headers; don't buffer realtime.
- Unavailable CRM → explicit CRM-host 502/503, gateway stays up, website continues while shared infrastructure healthy. Unknown host never becomes website content.
- Per-child health/readiness separately reported. Proposed release readiness requires gateway + both apps initially; runtime degraded status can preserve healthy website route while CRM restarts boundedly. D10 specifies platform health mapping/restart ceiling/escalation; “both down only” success must not conceal a failed CRM release.
- Supervisor forwards signals/drains children/reaps processes with bounded shutdown; distinguish child failure, gateway failure and deployment/provider failure. No endless restart cost loop. Private ports must be publicly inaccessible.
- Minimal logs hostname/status/latency/request ID, no bodies/cookies/auth headers/customer data.

Frontend serving contract must name actual verified frontend-enabled module, server-relative assets, injected same-origin API configuration, content-type/cache/content-hash policy and SPA deep-link fallback excluding native APIs. A healthy API alone is not frontend success.

Artifact manifest: website SHA/build, fork full SHA/release/branding commit, lockfile hashes, exact binaries/package managers, OS/architecture/native ABI, generated SDK/assets/config contract version, full production workspace dependencies/entrypoints and archive checksums. Frontend/API/worker must match; worker only consumes compatible queue payload versions. No `dist`-only package, manually edited lockfile or archived renamed-package assumption.

Branding covers approved MGOS/MaingateOS shell/navigation/auth/onboarding/record screens/emails/errors/help/generated favicons/manifests/title/localization plus owned backend names. Preserve required notices/source offers and truthful upstream/dependency provenance under D02, outside ordinary user product identity where lawful. Inventory persisted metadata/package IDs/queues/schedules/storage prefixes/SDK refs; decide new install versus upgrade aliases/backfill/drain/mixed-version/rollback. No bulk historical-ID rename or accepted queue root change.

**A01/A10/A13:** Complete approved visible/backend identity without unapproved stock branding, reproducible matching artifacts, deep link/assets/API/realtime correct host, host/session/header negatives and child-outage website continuity; actual published replicas/cold starts separate from local simulation.

## 8. Native private Backblaze attachment contract (D11)

Payload stays Replit App Storage with existing keys and adapter. CRM API and worker use **same approved native B2/S3** environment bucket/prefix/endpoint/region/path-style/signature configuration and narrow credentials. Source-map exact `STORAGE_TYPE`/`STORAGE_S3_*` variables after source verification; no placeholder defaults that select local storage. No App Storage bridge, local-disk/CDN/public-bucket fallback.

- Attachment is bound to native workspace/authorized record, not an arbitrary client object key; validate path/object ownership and type/size before signing/upload.
- Check native actor/record authorization before upload/download/read/replace/delete/sign and worker execution. Anonymous, other broker/workspace and deactivated users denied. Worker identity gets only job-required attachment scope, not global browser ACL bypass.
- D11 chooses signed expiry numeric limit, upload size/type/max count, object key/version scheme, native multipart/checksum/hash support, replacement preconditions and transfer mode.
- Signed URL is bearer capability until expiry; don't claim instant revocation. Prefer short TTL within approved residual exposure, regenerate only after current permission check. Never log/commit signed URLs. Define Content-Disposition, content type and download scope.
- Exact browser CORS origins/methods/headers/exposed checksum/range handling, or supported server-mediated transfer; no wildcard credential origin. Backend signing success does not prove browser behavior.
- Streaming/ranges/integrity verified for API and worker; record changes/attachment metadata commit ordering/failed-upload orphan cleanup documented. Retrying replace/delete must not duplicate visible effects.
- Archive/delete/restore lifecycle respects records and version retention. D11 approves logical versus physical delete, legal/consent retention, orphan/version cleanup ownership and expiry including backups. Background cleanup never scans unrelated Payload/B2 namespaces.
- Provider error visible and bounded; incomplete transfer is not success, no temporary local persistence claim. A process/deployment restart must retain records/metadata/attachments.

**A09:** Authorized browser/API/worker upload/read/replace/delete/range/stream/hash; private broker/workspace denial, expiry, reassignment residual exposure, CORS/transfer, provider error/no fallback and approved retention after restart.

## 9. Redis and intended native Vultr jobs (D12/D13)

S2 matrix is literal:

| Environment/application | Queue | Cache | Session | Rate limit |
| --- | --- | --- | --- | --- |
| Production website | `{prod:web:queue}` | `{prod:web:cache}` | `{prod:web:session}` | `{prod:web:rl}` |
| Production CRM | `{prod:crm:queue}` | `{prod:crm:cache}` | `{prod:crm:session}` | `{prod:crm:rl}` |
| Staging website | `{staging:web:queue}` | `{staging:web:cache}` | `{staging:web:session}` | `{staging:web:rl}` |
| Staging CRM | `{staging:crm:queue}` | `{staging:crm:cache}` | `{staging:crm:session}` | `{staging:crm:rl}` |

Website roots reserve scope; no new website Redis feature/use merely because this matrix includes them. Map the controlled synthetic development experiment to approved staging roots; never default editor to production or invent a new dev root that contradicts S2. Other environment names require authority decision.

Connection setup alone reads `UPSTASH_REDIS`, validates `.upstash.io`, upgrades accepted input to verified TLS `rediss://` and derives `REDIS_URL`, `REDIS_QUEUE_URL`, `REDIS_QUEUE_PREFIX`. URL does not encode the native subsystem root; configure/verify every cache/session/rate-limit/queue consumer. All API/worker queue keys use exact same accepted root. Preserve hash tag semantics for native Lua/multi-key operations. Stop if BullMQ consumer rejects format or quota behavior; do not remove braces/global-prefix silently.

No accepted queue root/name/schedule ID rename without approved drain/compatibility plan. Staging cleanup may SCAN/DEL only attributed whole braced roots; no FLUSHDB, bare prefix deletion or global key dumps. Nonempty scope blocks reinitialization; reusing a root with accepted work is not “fresh.” Shared Redis credential may not enforce provider ACL separation; D12 documents this limitation, approved scoped cleanup and consumer enforcement rather than claiming braced prefixes are authorization.

### Native job ledger

After source access enumerate **required native jobs only**: consumer/queue, payload version, producer, permission/DB/storage need, native maintenance/metadata/SDK effects, recurring schedule, exact registration command, stable job/schedule IDs, retryable/terminal errors, attempt/backoff/deadline/retention/lag limits and durable effect uniqueness key. Historically reported SDK jobs are candidates to inspect, not a complete hard-coded native inventory.

**Explicit exclusion:** No inventory ingestion, inbound-lead processing, external provider synchronization or custom connector schedules, even if referenced in target worker UAT or older roadmap. Do not use unrelated synthetic lookup jobs as substitute proof of required native jobs.

One designated registrar, separate from API replicas/consumer start, owns registration/reconciliation/removal with lock and version ledger. Define orphaned schedules, upgrade/reboot reconciliation and rollback; no duplicate recurring producers. Startup cannot disable all cron to pass.

Delivery can be at-least-once. Use stable native IDs plus transactional/durable effect dedup where needed; acknowledge only after durable effect/state. Bounded retries/backoff/jitter, visible terminal failures and authorized replay; no blanket exactly-once claim. Deletion/retention must preserve effect dedup for approved retry horizon.

Worker is intended for the **approved Vultr VM**. Source/build work stays same Repl; worker placement is operational artifact activation, not an agent task in another Repl. Under separate approval verify current owner/tier/services/OS/architecture/out-of-band SSH host trust; establish fresh nonroot native service identity/key-based restricted management and scoped sudo. Do not reactivate retired experiment account. Protected config, rotated scoped secrets, atomic checksummed release switch, bounded restart/log retention and graceful job drain. Reboot/activation/resize/rebuild/delete are separate actions; destructive rebuild is never routine and user VM never automatic cleanup.

Native worker needs approved shared DB route/minimal runtime role, verified Redis TLS and native Backblaze access. If Replit target cannot support Vultr connectivity, worker acceptance blocked; no provider switch or local substitute. Measurements/probes/reboot/retry/recovery only final phase.

**A11:** Matching package on verified intended identity consumes each required native job, registers once, retries and recovers after restart/backlog without unintended duplicate durable effects; payload/version/namespace and quota boundaries hold. Disabled scheduling/unapproved VM/synthetic-only lookup proof is not a pass.

## 10. Budgets, rollback, privacy and stop gates (D11/D14/D15)

Owner worksheet must supply **numeric** limits, measurement interval/method, target environment and approver for:

- Per-process and total CPU/RSS/disk/build cache/log retention, maximum joint deployment replicas, build duration/concurrency.
- Warm/cold p50/p95/readiness/shutdown/realtime reconnect/error rate and recovery deadlines.
- Database provider connection ceiling, app/workspace/worker pool maxima, migrator/admin reserve, website headroom, lock duration and statement/query queue policy.
- Redis command/connection/memory quota, idle polling/active throughput, lag/backlog/failed-job retention and alerts.
- Backblaze object/transfer/request/retained-version use, worker uptime/tier, release/test budget and soak duration.
- Backup retention/frequency, RPO/RTO, scoped restore/rollback time and incident escalation.

For joint web replicas `n`, budget:

`n × (website pools + CRM API core pools + bounded workspace pools) + worker pools + migrator/admin reserve <= approved provider ceiling − reserved website headroom`.

Record every pool/owner/environment; do not treat old max=3 or one pool per process as total capacity. Limits UNKNOWN → BLOCKED; S3/historical 40%/20%/2GB/$10/workload figures are not current consent.

Rollback runbook precedes consequential writes: prior compatible CRM artifact/config/schema, immutable coordinated manifest with unchanged website payload for CRM-only rollback, queue/job/storage compatibility, stop producers/drain or reconcile worker, scoped schema/data restore/compensations, release switch/verification triggers. Do not blindly down-migrate populated metadata or revert unrelated website changes. Whole shared database restore is exceptional, explicitly coordinated by owner with website write-loss analysis, not default CRM rollback. Domain rollback restores approved prior serving path without reverting website database/media.

Define backup capability and rights from current provider, not implied from checkpoint/PITR terms; disposable restore rehearsals in final phase precede production consideration. All synthetic cleanup is attributed/approved DB/schema/role, Redis roots and B2 prefixes only; preserve failed-state sanitized evidence, website resources and user-owned VM.

Privacy: minimum buyer fields/consent/lawful purpose before real use, actor/workspace/broker audit, role-limited exports, log redaction/no bodies/tokens, deletion propagation to attachments/index/cache/read state and approved retained audit/backups. Integration payload/DLQ handling is deferred, but native failed-job payloads/logs may still contain PII and need expiry. Staging/evidence contains synthetic data only. Large generated evidence belongs in ignored `generated-artifacts/` or approved durable storage, with small tracked manifests; no customer screenshots/key dumps/raw private catalogs.

Stop on missing approval/owner/rights/source, unknown target, changed pin, partial setup/activation, lock loss, unapproved helper/public/Payload change, ambiguous mutation, unavailable native ACL/support, provider route failure or resource/cost breach. Preserve evidence and ask the accountable owner for a named decision. Never infer permission to widen privileges, Retry/reset, create another app/provider, revive integrations or weaken security.
