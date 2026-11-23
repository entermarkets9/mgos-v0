# Custom UI in Twenty — preflight findings (Calculator, 2026-11-23)

**Question:** can we render a custom UI surface inside Twenty, reached from the sidebar,
instead of a table view? This is the gate for building our own front ends on Twenty's
models (OpenWA chat, DataVault/AI query, etc).

**Answer: yes, proven.** A real route + page renders inside Twenty's own shell, with
Twenty's sidebar, header, and router.

---

## 1. What was built

| Piece | File | Change |
| --- | --- | --- |
| Route enum | `packages/twenty-shared/src/types/AppPath.ts` | added `Calculator = '/calculator'` |
| Page | `packages/twenty-front/src/pages/calculator/CalculatorPage.tsx` | new, 172 lines |
| Route registration | `packages/twenty-front/src/modules/app/routing/utils/createWorkspaceRouteObjects.tsx` | lazy import + route object |

The page is plain React + `@linaria/react` styled components. It does **not** import any
Twenty UI component, and it still renders correctly inside Twenty's layout. That matters:
it means a custom surface does not have to be written against Twenty's design system to
work.

## 2. How Twenty's navigation actually works

### 2.1 The type enum

`core."navigationMenuItem".type`:

```
VIEW | FOLDER | LINK | OBJECT | RECORD | PAGE_LAYOUT | AGENT_CHAT_CHANNEL
| NATIVE_PAGE | WORKFLOW | AGENT | TAB | SECTION
```

### 2.2 A LINK item is just a react-router link

`NavigationMenuItemLinkDisplay.tsx` renders `NavigationDrawerItem` with `to={computedLink}`.
So a `LINK` item points at a **client-side route that must already exist in the router**.
It is not an iframe and not a plugin mount.

Path resolution (`getLinkNavigationMenuItemComputedLink`):
- `isSafeInternalPath` accepts anything starting with `/` (but not `//`), or `#`.
- anything else goes through `ensureAbsoluteUrl` → external link, shown with an
  `IconArrowUpRight` arrow.

So: internal nav item = register a route. External nav item = just paste a URL.

### 2.3 Schema gotchas that cost time

| Wrong assumption | Reality |
| --- | --- |
| column is `label` | it is **`name`** |
| `applicationId` can be null | **NOT NULL** — must reference an existing `core.application` row |
| `applicationId` = applicationRegistration id | it is the **application** id, not the registration id |
| only id/type/link needed | `universalIdentifier` (uuid, NOT NULL) and `isActive` (bool, NOT NULL) are also required |

Working insert (reuses the workspace's existing `applicationId`):

```sql
INSERT INTO core."navigationMenuItem"
  (id, "workspaceId", "universalIdentifier", "applicationId",
   type, name, icon, position, link, color, "isActive", "createdAt", "updatedAt")
VALUES
  (gen_random_uuid(), '<workspace-id>', gen_random_uuid(),
   (SELECT "applicationId" FROM core."navigationMenuItem"
     WHERE "workspaceId" = '<workspace-id>' LIMIT 1),
   'LINK', 'Calculator', 'IconCalculator', <pos>, '/calculator', 'blue', true, now(), now());
```

## 3. Observed result

- `/calculator` renders inside Twenty's shell: sidebar, workspace switcher, header all intact.
- The page occupies the main content area where a record table would be.
- Arithmetic verified through the UI: `7` → `+` → `2` → `=` → display reads `9`.
- The nav item row exists in the DB (`type=LINK, name=Calculator, link=/calculator,
  position=8, isActive=t`).

### 3.1 Open issue — sidebar list did not show it on first load

The sidebar rendered the standard items (Companies, People, Opportunities, Tasks, Notes,
Dashboards, Workflows, Campaigns) but **not** Calculator, even though the row is present and
`isActive = true`.

Most likely causes, in order:
1. **Nav state is cached client-side** and was hydrated before the row existed. Needs a hard
   reload or a cache-busting step.
2. **Workspace nav is per-user** — `userWorkspaceId` is nullable, and the standard items may
   be resolved through a user-workspace join that our row does not satisfy.
3. The workspace metadata cache holds a precomputed navigation tree that must be invalidated.

This is the one thing still to close. Direct route access proves the UI mechanism; the
sidebar *entry* needs one more step (either setting `userWorkspaceId`, or invalidating the
metadata cache, or creating the item through the UI's own "Edit navigation" flow instead of
SQL — the UI path writes whatever extra state is required).

## 4. What this means for the real features

The pattern that works is: **own route + own component + router entry.** That is exactly
what is needed for the planned surfaces:

| Planned surface | How it maps |
| --- | --- |
| OpenWA chat embedded in Twenty | A route `/chat` (or reuse the existing `AiChat` path) rendering our own chat component against Twenty's auth + our backend |
| DataVault / DocDB AI query | A route `/datavault` rendering our query UI, calling our API with Twenty's session |
| Investment calculator | Already done — this page |

Because these are real routes inside Twenty's router, they get:
- Twenty's session and auth for free
- Twenty's layout, sidebar, theming
- Normal deep-linkable URLs
- No iframe, no postMessage bridge, no sandbox

**What they do not get automatically:** permission enforcement. A route is reachable by
anyone who can load the app. Authorization has to be enforced server-side per record, as the
old plan's CRM-005 already requires.

## 5. The other path — applications + front components

Not yet tested, still worth evaluating for anything we want to ship as a *package*:

`core.application` carries `frontComponentSharedDependenciesBuiltPath`,
`sdkClientCoreChecksum`, `packageJsonFileId`, `yarnLockChecksum`, `sourcePath`,
`sourceType`, `settingsCustomTabFrontComponentId`, and `packages/twenty-front-component-renderer`
exists in the tree. That is Twenty's supported third-party UI surface: compile a front
component against a shared dependency layer and mount it inside Twenty's shell.

Tradeoff:
- **Route fork (proven today):** fastest, full control, but every upstream sync is a merge
  and the surface is not distributable.
- **Application front component:** more setup, but survives upgrades and can be installed
  per workspace. Right answer if we ever ship these surfaces to other instances.

## 6. Reproduce

```bash
# on sh2, with Node 26 on PATH
export PATH=/opt/node-v26.13.1-linux-x64/bin:$PATH
cd /srv/mgos/mgos
corepack yarn nx run-many -t start -p twenty-server twenty-front
# front :3001, server :3020
```

Then `/calculator`, or insert the nav row and use the sidebar.

## 7. Environment notes for whoever picks this up

- Node **26** is mandatory (`engines: ^26.5.1`); Node 24 fails the install gate outright.
- `packages/twenty-shared` must be rebuilt after changing `AppPath`, or the front will not
  see the new enum member.
- Port 3000 was occupied on sh2 (teable), so the stack runs on 3001/3020.
- Dev DB is `mgos` on sh2 localhost Postgres; role `mgos`.
