# 5. Codebase map

Follow source rather than old generated line numbers. Entry-point map, not a
claim that every path is exercised or deployed. `@/` maps to `src/modules` and
`~/` maps to `src` in twenty-front.

## twenty-front

| Area | Entry |
| --- | --- |
| App entry | `src/index.tsx`, `src/modules/app/components/App.tsx` |
| Workspace routes | `src/modules/app/routing/utils/createWorkspaceRouteObjects.tsx` |
| Route enum | `packages/twenty-shared/src/types/AppPath.ts` |
| Custom page example | `src/pages/calculator/CalculatorPage.tsx` |
| Auth / sign-in-up | `src/pages/auth/SignInUp.tsx`, `src/modules/auth/` |
| Auth mode auto-detection | `src/modules/auth/sign-in-up/hooks/useSignInUp.ts`, `src/modules/auth/states/signInUpModeState.ts` |
| Sign-in prefill | `src/modules/auth/sign-in-up/hooks/useSignInUpForm.ts` |
| Apollo / GraphQL client | `src/modules/apollo/services/ApolloFactory.ts`, `src/modules/apollo/hooks/useApolloFactory.ts` |
| Branding override | `src/mgos-theme.css`, `src/index.tsx` |
| Navigation drawer | `src/modules/ui/navigation/navigation-drawer/` |
| Generated GraphQL (core / metadata) | `src/generated/graphql.ts`, `src/generated-metadata/graphql.ts` |

## twenty-server

| Area | Entry |
| --- | --- |
| Server entry | `packages/twenty-server/src/main.ts` |
| Worker entry | `packages/twenty-server/src/queue-worker/queue-worker.ts` |
| Auth resolver | `src/engine/core-modules/auth/auth.resolver.ts` |
| Auth service | `src/engine/core-modules/auth/services/auth.service.ts` (incl. `checkUserExists`) |
| Email / password reset | `src/engine/core-modules/auth/services/reset-password.service.ts`, `src/engine/core-modules/email/` |
| User session cookie / CORS | `src/engine/core-modules/user-session/` |
| Config variables | `src/engine/core-modules/twenty-config/config-variables.ts` (defaults: `EMAIL_DRIVER=LOGGER`, `IS_EMAIL_VERIFICATION_REQUIRED=false`) |
| BullMQ queues | `src/engine/core-modules/message-queue/` |
| Dev seeder | `src/engine/workspace-manager/dev-seeder/` |
| Upgrade commands | `src/database/commands/upgrade-version-command/` (never edit committed logic) |

## Database

| Area | Schema |
| --- | --- |
| Platform / workspace metadata | `core` (82 tables) |
| Workspace records | per-workspace `workspace_<id>` (39 tables for `Mgos`) |
| Migrations | 667, never touch |

## Auth flows to know

- **Sign-in vs sign-up** is not a toggle: `checkUserExists` (server
  `auth.service.ts`) decides the mode after email entry.
- **Session cookie opt-in**: cross-origin GraphQL calls must send the
  `x-twenty-session-cookie` header (`SESSION_COOKIE_OPT_IN_HEADER_NAME` in
  `twenty-shared/constants`); otherwise the request is treated as
  unauthenticated.
- **Public endpoints** still carry `CaptchaGuard`; captcha is disabled when no
  CAPTCHA env vars are set.