# 9. CI/CD pipeline

The [workflow source](../../.github/workflows/) defines actual jobs and guards.
The integration branch is **`main`** (`origin/HEAD`); land work there via PR.

## Merge gate

| Gate | Requirement |
| --- | --- |
| Node | `^26.5.1` (engines gate in `yarn.config.cjs:26` hard-fails any other major) |
| Install | `yarn install --immutable` (Yarn 4 via corepack / `.yarnrc.yml`) |
| Commit messages | No AI attribution — CI rejects `@anthropic.com` co-author trailers or "Generated with Claude Code" lines |
| Branch strategy | Work on `agent/<letter>/<task>` or `task/<name>` branches; PR into `main` |

Stack phase PRs (e.g. `docs/plans/nabra-on-mgos/PHASE-*`) build on the previous
phase's branch, not on an older merged commit; each PR still targets `main` and
records its base branch in the body.

## Tests and verification

```bash
npx jest path/to/file.spec.ts --config=packages/<pkg>/jest.config.mjs  # single file
npx vitest run --root packages/twenty-ui --project unit <file>          # twenty-ui
npx nx test twenty-server
npx nx lint:diff-with-main twenty-server     # diff-based lint; run with typecheck after changes
npx nx fmt <pkg>
npx nx build twenty-shared                    # required before building/testing dependents
npx nx run twenty-server:test:integration:with-db-reset
npx nx storybook:build twenty-front && npx nx storybook:test twenty-front
npx nx run twenty-front:graphql:generate      # after GraphQL schema changes
```

## Releases

There is no automated deployment to sh2/sh5b from CI; deployments and
activation stay with the operator and the guarded lifecycle (see
[operations](04-operations-runbook.md) and the
[release inventory](11-release-state-inventory.md)).