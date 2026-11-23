# MGOS — full handoff (2026-11-23)

Everything needed to pick this up from a Devin desktop. All facts below were **verified on
the live system** at handoff time, not recalled.

---

## 1. Repository

| Item | Value |
|---|---|
| Repo | `git@github.com:entermarkets9/mgos.git` (private) |
| HTTPS | `https://github.com/entermarkets9/mgos.git` |
| Upstream parent | `twentyhq/twenty` (real fork, full history) |
| Base commit | `4bac2940dcdcbf4bb4c974b628cd5e1b0a2e37e0` (2026-11-22 `main`) |
| HEAD | `b15ddf17` |
| Remote parity | `HEAD == origin/main` ✅ |
| Working tree | clean ✅ |
| Local clone on your PC | `C:\codespace\mgos` |

### Commit history (all work to date)

```
b15ddf17  feat(mgos): sweep remaining user-facing strings Twenty -> MGOS
c26a8dde  feat(mgos): rebrand remaining 4 flagged strings + regenerate locales
19bdd7a1  feat(mgos): Phase A visible rebrand Twenty -> MGOS
b5b4832d  feat(mgos): custom UI surface proof - Calculator route inside Twenty shell
e660c71e  docs(mgos): add MGOS build plan and carry over CRM docs from mgre-new
```

---

## 2. Getting running (your Devin desktop)

```bash
git clone git@github.com:entermarkets9/mgos.git
cd mgos

# Node 26 is MANDATORY — engines: ^26.5.1. Node 24 hard-fails the install gate.
node -v                       # must be v26.x
corepack enable
corepack prepare yarn@4.13.0 --activate

yarn install --immutable
```

If `yarn install` fails with:

```
Error: Node version vXX doesn't match the required version, please use ^26.5.1
```

that is the `engines` gate in `yarn.config.cjs:26`, not a dependency problem. Fix the Node
version, do not edit the constraint.

### Run it

```bash
# build order matters
yarn workspace twenty-shared build
yarn workspace twenty-server build
yarn workspace twenty-front build

# then dev
yarn start
```

For a hot-reloading dev server (what we run on sh2):

```bash
npx nx run-many -t start -p twenty-server twenty-front
```

Needs `packages/twenty-server/.env` and `packages/twenty-front/.env` — see §4.

---

## 3. Current live dev environment (sh2)

| Item | Value |
|---|---|
| Host | sh2 `192.168.100.181` (LAN), 12 vCPU, 12 GiB, 154 G free |
| Repo path | `/srv/mgos/mgos` |
| Node | `v26.13.1` at `/opt/node-v26.13.1-linux-x64/bin` (side-by-side; system node is 24) |
| Yarn | 4.18.1 via corepack |
| Frontend | `http://192.168.100.181:3001` → **200** |
| Server | `http://192.168.100.181:3020` → `healthz` **200** |
| Database | Postgres `mgos`, role `mgos` |
| Workspace | `Mgos` / subdomain `mgos` / ACTIVE |
| Workspace id | `25e6a7ae-fb63-4033-bc99-5c4bc7a8837d` |
| Log | `/var/log/mgos/dev.log` |

**Port note:** sh2 already runs teable on `:3000`, so Twenty is deliberately on **3001**
(front) and **3020** (server). Do not assume default ports.

Start command for the sh2 box specifically:

```bash
export PATH=/opt/node-v26.13.1-linux-x64/bin:$PATH
cd /srv/mgos/mgos
nohup corepack yarn nx run-many -t start -p twenty-server twenty-front > /var/log/mgos/dev.log 2>&1 &
```

---

## 4. Environment files

### `packages/twenty-server/.env` (mode 600, contains DB password)

```
NODE_PORT=3020
NODE_ENV=development
PG_DATABASE_URL=postgres://mgos:<password>@127.0.0.1:5432/mgos
REDIS_URL=redis://127.0.0.1:6379
APP_SECRET=<generated>
FRONTEND_URL=http://192.168.100.181:3001
SIGN_IN_PREFILLED=true
STORAGE_TYPE=local
```

### `packages/twenty-front/.env`

```
REACT_APP_SERVER_BASE_URL=http://192.168.100.181:3020
REACT_APP_PORT=3001
VITE_HOST=0.0.0.0
VITE_BUILD_SOURCEMAP=false
```

**Not committed** — both are local-only. Recreate them on any new box.

---

## 5. What has been built

### 5.1 Custom UI proof — the Calculator (`b5b4832d`)

The finding that unlocks everything else: **a `LINK` nav item is just a react-router link.**
`NavigationMenuItemLinkDisplay` renders `NavigationDrawerItem to={computedLink}`. So custom
UI = register a real route. No iframe, no postMessage, no sandbox.

Three files:

| File | Change |
|---|---|
| `packages/twenty-shared/src/types/AppPath.ts` | `Calculator = '/calculator'` |
| `packages/twenty-front/src/pages/calculator/CalculatorPage.tsx` | new page, plain React + linaria |
| `packages/twenty-front/src/modules/app/routing/utils/createWorkspaceRouteObjects.tsx` | lazy import + route object |

Verified live: `/calculator` renders inside Twenty's shell (sidebar, header, router intact),
arithmetic works (`7 + 2 = 9` read back from the DOM).

**Schema gotchas that cost real time:**

| Wrong assumption | Reality |
|---|---|
| column is `label` | it is **`name`** |
| `applicationId` can be null | **NOT NULL**, must reference a `core.application` row |
| `applicationId` = applicationRegistration id | it is the **application** id |
| only id/type/link needed | `universalIdentifier` (uuid) and `isActive` (bool) also NOT NULL |

### 5.2 Branding — Phase A (`19bdd7a1`, `c26a8dde`, `b15ddf17`)

Twenty → MGOS on every user-visible surface. 123+ files.

**The key discovery:** Twenty ships its own branding-override pattern (`SalesfarceTheme`) —
a `--t-accent-*` CSS variable ramp plus a class toggle and favicon swap. So the monochrome
accent is **configuration, not a fork**. It survives upstream merges.

| Piece | Where |
|---|---|
| Monochrome accent ramp | `packages/twenty-front/src/mgos-theme.css` (imported in `src/index.tsx`) |
| Brand logo | `mgos-logo.svg` / `mgos-logo-dark.svg` (512×512, two greetings `#D9D9D9` / `#363636`) |
| Favicons | full android/ios/windows set rasterised from the SVG |
| Title/OG tags | `packages/twenty-front/index.html` |
| PWA manifest | `packages/twenty-front/public/manifest.json` |
| Locales | 70 `.po` files, ~4,175 msgid/msgstr lines |

Verified in the live DOM:

| check | value |
|---|---|
| `<title>` | `MGOS` |
| `--t-accent-primary` | `#e8e8e8` |
| `--t-accent-accent11` | `#363636` |
| `theme-color` | `#363636` |
| visible "Twenty" on screen | **0** |

### 5.3 What was deliberately NOT done

**Phase B (16 package renames) — dropped by owner decision.** Package names are internal
identifiers, users never see them. Renaming 16 packages across 31,732 import sites buys zero
user-facing value and makes every upstream merge worse.

**Never touch:** the 667 migrations, Redis queue names, storage prefixes, stored metadata
keys, licence headers/`LICENSE` files.

---

## 6. The open bug (fix this first)

**The Calculator row exists in the database but does not appear in the sidebar on first load.**

Current DB state:

```
SECTION   | Workspace  |         | isActive=t
FOLDER    | Workflows  |         | isActive=t
FOLDER    | Campaigns  |         | isActive=t
LINK      | Calculator | /calculator | isActive=t
```

Direct navigation to `/calculator` works perfectly. The nav list does not show it.

**Two candidate causes, in order:**
1. Client-side nav state cached and hydrated before the row existed.
2. Workspace nav is per-user — `userWorkspaceId` is nullable, and standard items may resolve through a user-workspace join our row does not satisfy.

**How to fix:** create the item through the UI's own **"Edit navigation"** flow and diff
what extra state it writes, rather than inserting by raw SQL. That likely reveals the missing
join/flag.

**Why this matters beyond the Calculator:** every future custom surface (`/ads`, `/content`,
OpenWA chat, DataVault query) hits the same mechanism. Fix it once, properly.

---

## 7. Plans in the repo

All plans now live under `docs/plans/`, so your Devin desktop can read them.

```
docs/plans/
├── twenty-custom-ui-preflight.md          ← how custom UI works (read first)
├── mgos-rebrand-plan.md                   ← branding phases A/B/C
├── mgos-single-vm-megaplan.md             ← single-VM topology
├── mgos-sh5b-runbook.md                   ← executable runbook for sh5b
└── nabra-on-mgos/                         ← 16 files, 2,311 lines
    ├── 00-INDEX.md                        ← start here for ads/content
    ├── 01-KEYWORDS-brainstorm.md          ← 384 concepts, written blind
    ├── 02-RESEARCH-EVIDENCE.md            ← ripgrep output from nabra-smma
    ├── 03-COVERAGE-MATRIX.md              ← keyword → file, 384/384
    ├── PHASE-0…8                          ← nine phase files
    └── APPENDIX-A/B/C                     ← targeting, integrations, channels
```

### Reading order for the ads/content work

1. `nabra-on-mgos/00-INDEX.md` — architecture in one paragraph
2. `twenty-custom-ui-preflight.md` — the routing mechanism you'll be extending
3. `nabra-on-mgos/PHASE-0-readiness.md` — the seven decisions that block everything

---

## 8. The nabra-on-MGOS architecture (summary)

**Option B chosen:** MGOS calls Zernio directly. No dependency on the nabra-smma service.

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

The read/write split is the safety design: **a mis-click in a calendar cannot spend money.**
Writes need an explicit tool invocation + manager role + confirmation token.

This split is not invented — nabra-smma already separates `ads-read-tools.ts` from
`ads-launch-tools.ts` / `campaign-mutation-tools.ts` at its AI layer.

---

## 9. Zernio facts (verified from nabra-smma)

| Item | Value |
|---|---|
| Base URL | `https://zernio.com/api/v1` (override: `ZERNIO_BASE_URL`) |
| Auth | `Authorization: Bearer <ZERNIO_API_KEY>` |
| Webhook secret | `ZERNIO_WEBHOOK_SECRET` — **we generate it**, 32+ hex bytes; Zernio never does |
| Client budget | `ZERNIO_RPM` default 500; Zernio allows 600/min for 3–2,000 accounts |
| Verified platforms | `facebook`, `instagram` (via Meta), `tiktok`, `tiktok-ads`, `google-ads` |
| Unverified | `linkedin`, `x/twitter`, `threads`, `youtube`, `pinterest`, `snapchat` — appear in old notes, **not** in the adapter paths. Spike before promising. |

**Anti-pattern to avoid:** in nabra-smma, `zernio` mode is exclusive and the **server refuses
to boot** without the key and secret. MGOS must degrade the feature instead — a CRM that will
not start because an ads integration is misconfigured is a worse outage than a blank ads page.

---

## 10. Seven blocking decisions (Phase 0)

| ID | Decision | Default if unresolved |
|---|---|---|
| `D-SCOPE-01` | Confirm `/ads` and `/content` are views only; all mutation via AI | BLOCKED |
| `D-CRED-01` | Zernio team + key + webhook secret **per environment** | BLOCKED |
| `D-RBAC-01` | **What "manager" means** in Twenty's role model | BLOCKED |
| `D-DATA-01` | Mirror Zernio entities into `core` schema, or fetch live | BLOCKED |
| `D-AI-01` | Twenty's built-in AI chat + MCP, or our own route | BLOCKED |
| `D-COST-01` | Spend cap per ad account, and who may raise it | BLOCKED |
| `D-APPR-01` | Approval model: inline confirm, four-eyes, or both | BLOCKED |

**Answer these two first**, because they unblock the most:
- **`D-RBAC-01`** — read Twenty's `Role` and `RolePermissionFlag` model *before* designing permissions. Ripgrep found `requirePermission("...")` with `manage_integrations` confirmed, but **no dedicated `manage_ads`/`manage_content`** — ad/content gating may be role-based elsewhere. **Phase 6's first task is inspection, not implementation.**
- **`D-DATA-01`** — recommendation is mirror campaigns + daily metric snapshots (append-only, wants history for trend/anomaly), but fetch account connection state live (a revoked token must show immediately).

---

## 11. Known environment traps

| Trap | Consequence | Fix |
|---|---|---|
| Node 24 | install hard-fails | Node `^26.5.1` (26.13.1 verified) |
| Port 3000 on sh2 | collision with teable | use 3001 / 3020 |
| `.env` not committed | fresh clone will not start | recreate from §4 |
| `twenty-shared` not rebuilt after `AppPath` change | front does not see new enum | `yarn workspace twenty-shared build` |
| Dev server killed mid-rename | Nx watch thrashes | stop before large file moves |
| Vite `createSettingsRouteObjects` HMR warning | benign, falls back to full reload | ignore |
| `gh` token on your PC | invalid; `gh` commands fail there | git uses SSH via `maingatessh`; run `gh auth login` if you need `gh` |

---

## 12. Your PC's git setup (already fixed)

```
origin  git@github.com:entermarkets9/mgos.git
~/.ssh/config →  Host github.com
                   HostName github.com
                   User git
                   IdentityFile C:\Users\jacks\.ssh\maingatessh
                   IdentitiesOnly yes
```

Verified: `git push --dry-run` → `Everything up-to-date`; `ssh -T git@github.com` →
`Hi entermarkets9!`

Note: `id_ed25519_mgos` was generated before finding `maingatessh` works — it is unused and
harmless; delete if you prefer.

---

## 13. Deliberately not done (scope honesty)

- No ads or content feature code written — **plan only**, as instructed.
- No `nabra-smma` files modified.
- No sh5b deployment. sh5b is still stopped with all 10 volumes intact.
- No Phase B package renames.
- No production credentials created for Zernio.

---

## 14. Suggested first three tasks

1. **Fix the sidebar nav bug** (§6) by using the UI's "Edit navigation" flow and diffing.
   Without this, no custom surface will appear in the sidebar.
2. **Answer `D-RBAC-01`** by reading Twenty's role model — 30 minutes of reading that
   determines the entire permission design.
3. **Start Phase 1** (Zernio client) against a stub — it needs no decisions and no credentials.

---

## 15. Reference: the UI extension mechanism in one screen

```ts
// 1. route enum
// packages/twenty-shared/src/types/AppPath.ts
Calculator = '/calculator',

// 2. page
// packages/twenty-front/src/pages/calculator/CalculatorPage.tsx
export const CalculatorPage = () => <StyledContainer>…</StyledContainer>;

// 3. route object
// createWorkspaceRouteObjects.tsx
const CalculatorPage = lazy(() => import('~/pages/calculator/CalculatorPage')
  .then(m => ({ default: m.CalculatorPage })));

{ path: AppPath.Calculator,
  element: <LazyRoute><CalculatorPage /></LazyRoute>,
  handle: { workspaceSurfaces: MAIN_AND_SIDE_PANEL } },

// 4. nav item (SQL, but prefer the UI's Edit navigation flow)
insert into core."navigationMenuItem"
  (id, "workspaceId", "universalIdentifier", "applicationId",
   type, name, icon, position, link, color, "isActive", "createdAt", "updatedAt")
values (gen_random_uuid(), '<workspace-id>', gen_random_uuid(),
   (select "applicationId" from core."navigationMenuItem"
     where "workspaceId"='<workspace-id>' limit 1),
   'LINK', 'Calculator', 'IconCalculator', 100, '/calculator', 'blue', true, now(), now());
```
