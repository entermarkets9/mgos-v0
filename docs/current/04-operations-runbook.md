# 4. Operations

Read [agent policy](../../AGENTS.md) and confirm the requested environment,
source, configuration authority, and allowed effects before acting. This repo
governs how agents work in parallel: session letters, worktrees, no branch
switches in a checkout you do not own, and operator-owned lifecycle actions.

## Local development

```bash
# Node 26 is MANDATORY — engines: ^26.5.1. Node 24 hard-fails the install gate.
# Node 26 does not ship corepack; the repo pins Yarn via yarnPath in .yarnrc.yml.
node .yarn/releases/yarn-4.18.1.cjs install --immutable

# build order matters
yarn workspace twenty-shared build
yarn workspace twenty-server build
yarn workspace twenty-front build

# then dev (front + server + worker)
yarn start
```

Hot-reloading dev server (what runs on sh2):

```bash
npx nx run-many -t start -p twenty-server twenty-front
# plus, in a second terminal, the worker:
npx nx run twenty-server:worker
```

`yarn start` already runs both via concurrently (`wait-on tcp:3000` then the
worker). On sh2 port 3000 is teable, so that wait resolves immediately; the
worker retries until the server is up.

## Environment files (not committed)

Recreate them on any new box:

`packages/twenty-server/.env` (mode 600, contains DB password):

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

`packages/twenty-front/.env`:

```
REACT_APP_SERVER_BASE_URL=http://192.168.100.181:3020
REACT_APP_PORT=3001
VITE_HOST=0.0.0.0
VITE_BUILD_SOURCEMAP=false
```

## sh2 stack

```bash
export PATH=/opt/node-v26.13.1-linux-x64/bin:$PATH
cd /srv/mgos/mgos
nohup corepack yarn nx run-many -t start -p twenty-server twenty-front > /var/log/mgos/dev.log 2>&1 &
nohup /opt/node-v26.13.1-linux-x64/bin/node .yarn/releases/yarn-4.18.1.cjs nx run twenty-server:worker > /var/log/mgos/worker.log 2>&1 &
```

Ports: front `:3001`, server `:3020` (port 3000 is teable's). Only one dev
stack runs per machine; a second stack needs different ports and a different
database name.

## Known traps

| Trap | Consequence | Fix |
| --- | --- | --- |
| Node 24 | install hard-fails | Node `^26.5.1` (26.13.1 verified); fix the runtime, not `yarn.config.cjs` |
| corepack missing on Node 26 | `corepack` commands fail | use the committed `.yarn/releases/yarn-4.18.1.cjs` |
| `.env` not committed | fresh clone will not start | recreate from above |
| `twenty-shared` not rebuilt after `AppPath` change | front does not see the new enum | `yarn workspace twenty-shared build` |
| `SIGN_IN_PREFILLED=true` | welcome page prefills fictional `tim@apple.dev` → "Sign up" only | type a real registered email; or set `false` |
| Worker not started | queues back up silently | `yarn start` or start the worker target |
| Dev server killed mid-rename | Nx watch thrashes | stop before large file moves |
| Vite `createSettingsRouteObjects` HMR warning | benign, falls back to full reload | ignore |
| `gh` token on your PC | invalid; `gh` fails there | git uses SSH via `maingatessh`; `gh auth login` if needed |

## Verification

- Install application dependencies only when needed (`yarn dx:runtime` →
  `yarn install --immutable` under a per-checkout stamp).
- Rebuild `twenty-shared` with `--skip-nx-cache` after switching branches or
  editing it, before trusting typecheck/test failures in dependents.
- Nx caching can serve a stale pass; verify with
  `npx tsgo -p tsconfig.json --noEmit` in the package directly.
- Report database migration and service/worker activation state as Unknown
  until an approved lifecycle supplies evidence.