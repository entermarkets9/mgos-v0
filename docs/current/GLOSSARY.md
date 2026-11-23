# MGOS language

These are product and operating concepts, not instructions to rename existing
identifiers. Definitions distinguish ownership and authority; they do not
certify live rollout, provider acceptance, or performance.

## Workspace authority

**Workspace**:
The Twenty collaboration and authorization boundary (`core.workspace`), with its
own members, metadata rows, and record schema. The current workspace is `Mgos`.
_Avoid_: treating `workspaceId` as optional anywhere.

**Workspace record schema**:
The per-workspace PostgreSQL schema (`workspace_<id>`) holding record tables
(company, person, opportunity, …). Distinct from the `core` metadata schema.
_Avoid_: assuming a shared record table.

**Member**:
A person linked to a workspace via `core."userWorkspace"`. Nav visibility may be
per-user through this join (`userWorkspaceId`), which is why a raw SQL nav row
can exist yet not render.
_Avoid_: assuming one user table alone authorizes workspace UI.

## Surfaces

**Custom surface**:
A real route + page registered in Twenty's router and linked from a
`LINK`-type navigation item. No iframe, no plugin mount. The Calculator at
`/calculator` is the proof.
_Avoid_: describing surfaces as iframes or app mounts.

**`/ads` and `/content`**:
Planned read-only views (analytics and calendar). All mutation goes through the
AI sidebar / MCP tools. Plan only — nothing built.
_Avoid_: implying write capability exists.

## Runtime

**Worker**:
The `queue-worker` process (`twenty-server:worker`) that consumes BullMQ queues
(webhook, workspace, entity-events, calendar, email, cron, AI, …). Without it,
background jobs back up in Redis and the app stops behaving like a real
deployment.
_Avoid_: calling the API process "the worker".

**SIGN_IN_PREFILLED**:
Dev convenience that prefills `tim@apple.dev`/`tim@apple.dev` on `/welcome`.
Because the mode is auto-detected from `checkUserExists`, a prefilled email that
is not registered shows "Sign up" — this confused operators, not a bug.
_Avoid_: treating the welcome page as offering a manual Sign-in/Sign-up toggle.

**Zernio**:
The ad/social provider behind the nabra-on-MGOS plan (Option B: MGOS calls
Zernio directly). Must degrade on misconfiguration, never block boot.
_Avoid_: copying nabra-smma's exclusive-mode boot refusal.

## Fork relationship

**Upstream**:
`twentyhq/twenty` at base `4bac2940` (2026-11-22). MGOS is a private fork that
rebrands user-visible surfaces and adds custom surfaces; internal package names
stay as upstream's.
_Avoid_: renaming internal packages "for branding" (Phase B was dropped by
owner decision).