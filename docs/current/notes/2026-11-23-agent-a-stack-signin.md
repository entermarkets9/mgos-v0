# Agent-A session — stack activation and sign-in reset (2026-11-23)

Verified live on sh2. Companion to `docs/plans/MGOS-HANDOFF.md`; this note
records what changed after that handoff.

## Onboarding state

- Node on the operator PC was v24.21.0 (would fail the `^26.5.1` install gate);
  switched to **26.13.1 via nvm** (matches sh2).
- Node 26 ships no corepack; the repo's committed `.yarn/releases/yarn-4.18.1.cjs`
  (yarnPath in `.yarnrc.yml`) works without it.
- Worktree `C:\codespace\mgos-Agent-A` on `agent/a/onboarding` @ `c7f721d402`.

## Sign-in investigation (the "no sign-in button" report)

Root cause: this Twenty version auto-detects Sign in vs Sign up from
`checkUserExists`; there is no toggle. `SIGN_IN_PREFILLED=true` prefills
`tim@apple.dev`, which does not exist in the MGOS DB → the button shows
"Sign up". Typing a registered email (e.g. `admin@mgos.local`) correctly shows
"Sign in" + "Forgot your password?".

## Password reset (authorized by operator)

The only user (`admin@mgos.local`) had a custom hash; `TwentyMgmt!2026` did not
match. The email is fictional, so the forgot-password email flow is unusable;
the operator authorized a direct DB hash update:

- Set `passwordHash` to bcrypt(`TwentyMgmt!2026`) — `$2b$10$Kk4Drj0…`
  (verified `compareSync` → true).
- Set `isEmailVerified = true` (`IS_EMAIL_VERIFICATION_REQUIRED` defaults false
  anyway).
- Signed in through the browser → landed on `/objects/companies`.

## Worker activation (the "make the stack behave like a real app" request)

The stack had been started with `nx run-many -t start -p twenty-server
twenty-front`, which skips the worker. Redis held stuck jobs (webhook 29
prioritized, workspace 12, entity-events 8, calendar 4; ~5.8h queue wait).

Started `nx run twenty-server:worker` (queue-worker entry, logged to
`/var/log/mgos/worker.log`). It drained the backlog (43 jobs) and processed:
webhook `CallWebhookJobsForMetadataJob`, `RewriteAgentChatChannelGrantsJob`,
`InstallPreInstalledAppsJob`, `GenerateSdkClientJob` (2 SDK clients), plus
entity-events and calendar work.

Email pipeline verified end-to-end: `emailPasswordResetLink` mutation →
server → Redis email-queue → worker → LOGGER driver printed the reset URL
(`http://192.168.100.181:3001/reset-password/<token>`). email-queue 1
completed, 0 failed.

All four monitored queues now wait=0 / failed=0. Front 200, server healthz 200,
Redis PONG.

## Gotcha discovered

Root `yarn start` uses `npx wait-on tcp:3000` before launching the worker, but
on sh2 port 3000 is teable — the wait resolves instantly instead of waiting for
the server. Harmless (worker retries), but the wait is a no-op on this box.

## Notes for later

- `docs/current/13b-sh2-dev-stack.md` is the operating sheet for the box.
- Remaining open: sidebar nav bug (Calculator row), D-RBAC-01, D-DATA-01, and
  the rest of the Phase 0 gates.