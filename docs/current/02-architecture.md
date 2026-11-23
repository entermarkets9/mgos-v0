# 2. Architecture

This is the maintained source-level overview. It is not an attestation of
deployed configuration, complete tenant isolation, or provider acceptance.

## Monorepo shape

Nx / Yarn 4 monorepo. Main packages:

| Package | Role |
| --- | --- |
| `twenty-front` | React 18, Jotai, Linaria, Vite |
| `twenty-server` | NestJS, TypeORM, PostgreSQL, Redis, GraphQL |
| `twenty-shared` | Isomorphic types/utils; must be rebuilt after `AppPath` changes |
| `twenty-ui` | Design system components |
| `twenty-sdk` | Application definitions and runtime |
| `twenty-cli` | Standalone CLI |
| `twenty-e2e-testing` | Playwright |

## Runtime topology

```
Postgres (127.0.0.1:5432)      Redis (127.0.0.1:6379)
        ^                            ^
        |                            |
   twenty-server (nest, :3020)  <-->  BullMQ queues
        ^                            ^
        |                            |
   twenty-front (vite, :3001)   twenty-server:worker (queue-worker)
        |                            |
        +--- Vite proxy /graphql --->+  (front also calls :3020 directly)
```

- **Front** (`:3001`) serves the UI; `/graphql` and `/metadata` proxy to the
  server. Cross-origin calls carry a session cookie that requires the
  `x-twenty-session-cookie` opt-in header.
- **Server** (`:3020`) exposes `/graphql` (core), `/metadata` (metadata), and
  `/healthz`.
- **Worker** (`twenty-server:worker`, `queue-worker` entry) consumes BullMQ
  queues: webhook, workspace, entity-events-to-db, calendar, email, cron, AI,
  and more. Without it, background jobs never process.

## Storage boundaries

| Plane | Authority | Isolation requirement |
| --- | --- | --- |
| Workspace metadata | PostgreSQL `core` schema | Workspace-scoped rows keyed by `workspaceId` |
| Workspace records | PostgreSQL per-workspace schema (`workspace_<id>`) | Bind workspace context before access |
| Storage | `STORAGE_TYPE=local` on sh2 | Local files, not S3 |
| Queues | Redis BullMQ | Queue names are global; never rename them |

The workspace `Mgos` uses schema `workspace_28s05y2lxh7uzx5y93g6sk3nh`.

## Custom UI mechanism (proven)

A `LINK` nav item is just a react-router link:
`NavigationMenuItemLinkDisplay` renders `NavigationDrawerItem to={computedLink}`.
So custom UI = register a real route. No iframe, no postMessage, no sandbox.

Three files make a surface:

| Piece | File |
| --- | --- |
| Route enum | `packages/twenty-shared/src/types/AppPath.ts` |
| Page | `packages/twenty-front/src/pages/<name>/<Name>Page.tsx` |
| Route object | `packages/twenty-front/src/modules/app/routing/utils/createWorkspaceRouteObjects.tsx` |

Verified live: `/calculator` renders inside Twenty's shell. Direct route access
proves the UI mechanism; the sidebar *entry* still needs the nav-item state fix
(see [open work](06-open-work.md)).

**What custom routes do NOT get automatically:** permission enforcement. A route
is reachable by anyone who can load the app; authorization must be enforced
server-side per record.

## Sign-in / sign-up auto-detection

`/welcome` renders `SignInUp` → `SignInUpGlobalScopeForm` (or workspace-scope
form) → `SignInUpWithCredentials`. After entering an email, the server
`checkUserExists` query decides the mode:

- email exists → button is **"Sign in"** (password step)
- email does not exist → button is **"Sign up"**

There is **no separate Sign in / Sign up toggle** in this version — the submit
button label flips based on `checkUserExists`. `SIGN_IN_PREFILLED=true` prefills
`tim@apple.dev`/`tim@apple.dev`, which does not exist in the MGOS DB and so
always shows "Sign up" — a known dev-config trap.

## nabra on MGOS architecture (Option B)

```
MGOS sidebar
├── /ads       → analytics view (GET only)
├── /content   → calendar view (GET only)
└── AI         → MCP tools (the ONLY write path)
                    │
                    ▼
             MGOS server (manager-gated)
                    │  ZERNIO_API_KEY
                    ▼
             zernio.com/api/v1
```

The read/write split is the safety design: a mis-click in a calendar cannot
spend money. Writes require an explicit tool invocation + manager role +
confirmation token. See `docs/plans/nabra-on-mgos/00-INDEX.md`.

The anti-pattern to avoid: in nabra-smma, `zernio` mode is exclusive and the
server refuses to boot without the key and secret. MGOS must degrade the feature
instead — a CRM that will not start because an ads integration is misconfigured
is a worse outage than a blank ads page.