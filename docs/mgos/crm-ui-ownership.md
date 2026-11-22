---
name: CRM UI ownership requirement
description: Product scope for a future CRM port beside the website.
---

The user wants full granular control over CRM's UI, including white-labeling,
rather than only runtime theme settings or an embedded iframe.
The user wants the upstream product's name and branding removed from both
the UI and backend code, with full company attribution. They state that they
own the upstream product. Keep their private product name out of saved notes
and report filenames; use neutral CRM naming in shared planning documents.
The user requires zero mentions of the upstream product name, including
folder names, filenames and current project-owned contents.

**Why:** The user explicitly requested source-level control for the planned
CRM port alongside the existing Next.js app.

**How to apply:** Plan around a maintained frontend/component source fork.
Distinguish fixed source-owned surfaces from deliberately built runtime controls.
Preserve server-side workspace authorization while changing the UI.
Use the privately approved product identity and explicitly plan backend namespace
transitions, not only visible logo changes. Keep legal provenance separate
from product branding and handle persisted identifiers through migrations.
Do not introduce the upstream name into owned paths, new notes or outputs.
Distinguish current checkout cleanup from unerasable prior platform history
and separately retained original source/evidence; do not falsify attribution.

**Hosting scope:** The user specified on 2026-10-11 that the CRM and existing
Next.js application must be one bundle, served from the same Repl. The earlier
separate-Replit-app deployment proposal is superseded.

**Why:** This is an explicit user correction to the linked deployment plan.

**How to apply:** Plan one coordinated build/release and one public ingress
while preserving separate application processes, toolchains, credentials,
authorization and migration ownership. Do not create a separate Replit app
or deployment for the CRM. Worker placement is a separate concern from serving
both web applications in this Repl.

**Hostname target:** The user's updated target is `crm.maingate.ae` for the CRM
and `maingate.ae/admin` for Payload, in the same Repl, sharing PostgreSQL with
separate schemas. This replaces the proposed `/crm` path target.

**Why:** The user requested an updated definition-of-done document after
discussing the two-hostname arrangement; the retained experiment did not prove
either hostname or prefix routing.

**How to apply:** Use hostname routing in the shared public entry point.
Preserve separate runtime identities, schema permissions and host-scoped
sessions; do not infer that DNS or production deployment is already configured.
