# CRM and website — target state

> **Historical broader draft:** For the current locked v2 delivery specification,
> use [the scoped roadmap](crm-scoped-delivery-plan.md). Its three custom objects,
> native broker identity, dashboard/calculator and explicit inventory/inbound-lead
> deferral supersede this draft's integrations, Broker-object and admin-theme scope.
> The text below is preserved as history, not delivered software or execution approval.

**Updated:** 2026-10-11  
**Status:** Completion criteria, not a record of completed implementation.

This document updates the [shared CRM/Next.js plan](https://share.onorca.dev/a/6a-K61sLvtAW) into a high-level description of what done looks like. It retains the scoped requirements and review safeguards, but replaces the proposed `/crm` path with hostname-based routing. It is not an execution schedule or permission to change production.

## 1. The finished system

The public website, Payload administration and the owned CRM run from the **same Repl and one published deployment**. They are built and released together, but remain separate applications.

| Address | What users receive |
| --- | --- |
| `https://maingate.ae` | The existing Next.js public website |
| `https://maingate.ae/admin` | Existing Payload administration and its own login |
| `https://crm.maingate.ae` | The fully branded CRM, including its frontend, API and its own login |

Both domains reach one public entry point. Routing selects the application by hostname, not by a `/crm` prefix. CRM routes operate at the root of its own hostname. Neither application's internal listening ports are public alternatives.

**Done means:**

- Both domains have valid HTTPS and reach the correct application.
- Direct links, page reloads, assets, APIs, redirects, authentication callbacks, streaming and realtime connections work on the appropriate hostname.
- Website APIs, assets, existing links and Payload administration keep their behavior.
- Unknown hosts and unavailable services produce explicit, appropriate errors rather than another application's page.
- The CRM does not require a separate Replit application, independent publication or iframe inside the website.

## 2. One release, separate application boundaries

A single versioned release contains the website, CRM frontend/API and the matching worker package. Separate application processes, compatible runtimes and dependency sets are preserved; one bundle does not mean merging both codebases into one Node process.

**Done means:**

- A reproducible build produces everything required to run the release, with identifiable source versions and runtime requirements.
- One documented startup entry point serves both web applications and reports their readiness.
- Application environments, secrets and sessions are separated.
- Shutdown, restart and child-process failures have tested, bounded behavior.
- A CRM-only failure does not redirect CRM traffic into the website. The website remains usable where shared infrastructure is healthy; a whole-deployment or shared-database failure is not presented as isolated.
- Combined memory, CPU, database connections and queue usage fit the selected deployment capacity and agreed operating budget.
- Background jobs remain assigned to an explicitly approved worker location. The matching worker package belongs to the release, but the inherited external-worker arrangement is not permission to activate, resize or replace a VM.

## 3. Shared database with enforced isolation

Payload and CRM use the **same PostgreSQL database**, with separate application-owned schemas and distinct runtime identities. Schema separation is backed by permissions, not merely different search paths.

**Done means:**

- Payload's existing tables, data and behavior are preserved.
- CRM owns its required application and workspace schemas without unrestricted access to Payload objects.
- Negative tests show that ordinary runtime accounts cannot read or modify the other application's private objects.
- Migration authority is controlled separately from application runtime access.
- Shared extensions or functions, including anything required in `public`, have explicit ownership and allowed access.
- Initialization, upgrades, workspace creation and recovery have passed on approved disposable staging.
- The actual database provider supports the required roles, permissions and extension arrangements.
- If provider limitations prevent safe isolation, delivery is blocked until an alternative is explicitly approved; there is no silent switch to another database or a shared administrator login.

## 4. An owned, fully branded CRM

The CRM is maintained as an approved, source-controlled fork with full frontend and backend customization. Branding is not limited to a theme setting or embedded view.

**Done means:**

- User-facing screens, authentication pages, generated assets and application-owned backend naming use the approved identity.
- The approved source version, dependencies and licensing obligations are documented.
- Required legal notices and provenance are preserved separately from product branding.
- Stored identifiers, integration references, queue names and storage keys have a defined compatibility or migration treatment.
- Rebranding does not strand records, invalidate integrations unexpectedly or prevent a safe rollback.
- Historical experiment results are not substituted for acceptance of the finished branded release.

## 5. Useful records and working integrations

The CRM supports the scoped **Property, Listing, Broker and Enquiry** records and their relationships. Identifiers are stable and distinguish source and tenant where required.

**Done means:**

- Supported record creation, viewing, editing and deletion or archival follow explicit permissions and lifecycle rules.
- The relationship between a property, its listings, projects where applicable, brokers and enquiries is unambiguous.
- The scoped inventory ingestion and inbound-lead integrations work against authorized provider endpoints.
- Provider field mappings, authentication, ownership, update rules and failure behavior are agreed and documented.
- Repeated delivery does not create unintended duplicate records or effects.
- Interrupted imports and failed deliveries can be retried or replayed safely, with visible status and bounded retention of failed work.
- Missing provider contracts or access remain release blockers. Synthetic fixtures and stubs are not described as working live integrations.

## 6. Broker access is enforced by the server

Each broker sees and acts on only the leads and related information they are authorized to access. Managers have explicitly defined access.

**Done means:**

- Record restrictions apply to every supported API, search, export, relationship and attachment path, not just the visible interface.
- Broker-to-login identity and assignment rules are explicit.
- Unassigned leads, reassignment, broker deactivation and manager overrides have defined behavior.
- Negative tests prove that another broker or workspace cannot bypass these rules.
- Login, invitation, signup restrictions, email delivery, token renewal and revocation work as specified.
- Website and CRM sessions remain separate, with host-scoped cookies unless a different arrangement is explicitly approved. A sibling hostname does not imply shared sign-in.

## 7. Durable, private attachments and reliable jobs

Payload continues to use **Replit App Storage**. CRM attachments use **native Backblaze S3**, consistently from the API and worker.

**Done means:**

- Authorized upload, read, replacement and deletion work, with integrity and restart-persistence checks.
- Anonymous users and unauthorized brokers or workspaces cannot access private attachments.
- Signed links expire correctly and browser access works through the intended origin and CORS arrangement, or approved server transfer.
- Provider failures are visible; there is no silent local-storage or alternate-backend fallback.
- Required native and custom background jobs run, retry and recover after restart without unintended duplicate user-visible effects.
- Recurring-job registration has a single controlled owner and is not repeated by every API instance.
- Environment-specific queue namespaces, worker privileges and retained logs are defined and tested.

## 8. Payload administration remains familiar and usable

Payload stays at `maingate.ae/admin` with its existing security and operational workflows. Approved CRM design tokens may align the administration interface without restyling the public website.

**Done means:**

- Admin forms, editors, tables, dialogs and responsive layouts remain usable and accessible.
- The public marketing site's styling and behavior are unchanged by the admin theme.
- Existing Payload branding stays unless a change is explicitly approved.
- Login and authorization are not weakened to simplify theme integration or testing.

## 9. Completion is supported by evidence

The system is not done because it builds or because an earlier bounded experiment passed.

**Done means:**

- Website regression checks and authenticated CRM acceptance checks pass on verified synthetic targets.
- Domain routing, deep links, account lifecycle, broker permissions, database isolation, attachments, worker recovery and combined resource behavior are tested.
- Existing website HTTP-500/font and missing-media baseline failures are resolved, or remain explicit blockers rather than being ignored.
- Every finding in the [42-finding review](.csv/crm-port-plan-review.csv) has a documented resolution and evidence, or an explicitly approved non-applicable decision. Hosting findings are reassessed for the two-hostname, same-deployment arrangement.
- Measurable performance, capacity, recovery and operating-cost limits are agreed before final acceptance; invented thresholds or missing tests cannot be reported as passes.
- A coordinated release and rollback rehearsal demonstrates that CRM recovery does not accidentally revert or damage website data.
- Handoff includes release identity, startup and migration responsibilities, worker operation, monitoring, backup/restore arrangements and outstanding approvals.
- Production-ready and live are reported separately. Live acceptance requires the actual approved domains and production release to have been verified.

## 10. Scope and approval boundaries

This target does **not** add website-to-CRM lead synchronization, shared SSO, replacement of public website inventory with CRM inventory, unrelated website rewrites, or full commercial broker-portal parity.

Production publication, DNS changes, production migrations, real-data imports, paid resource activation, VM lifecycle changes and an extended soak require their specific approvals. Documentation approval alone authorizes none of those actions.

The domain names above describe the intended destination, not proof of domain ownership, configured DNS or an existing live deployment.

## Definition of done

**One Repl and one coordinated release serve the website and Payload on `maingate.ae`, and the branded CRM on `crm.maingate.ae`; both safely share PostgreSQL, retain separate security and storage boundaries, deliver the scoped records and integrations, and have evidenced operation, recovery and acceptance with no unresolved required blockers.**
