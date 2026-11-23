# 13b. sh2 dev stack

sh2 (`192.168.100.181`) is the shared live Linux dev box. This file is the
operating sheet for that one stack.

## What runs on the box

- **teable** on `:3000` (docker) — NOT Twenty. Do not assume default ports.
- **Twenty front** (vite) on `:3001`.
- **Twenty server** (nest, `dist/main`) on `:3020`.
- **Twenty worker** (`queue-worker`) — must be running for background jobs.
- Postgres 17 (`127.0.0.1:5432`), Redis (`127.0.0.1:6379`).
- Other tenants on the box: nabra-smma dev, openwa-support-ticketing, marketing.
  They are separate processes; do not restart them while working on the MGOS
  stack.

## Start (operator-owned)

```bash
export PATH=/opt/node-v26.13.1-linux-x64/bin:$PATH
cd /srv/mgos/mgos
nohup /opt/node-v26.13.1-linux-x64/bin/node .yarn/releases/yarn-4.18.1.cjs nx run-many -t start -p twenty-server twenty-front > /var/log/mgos/dev.log 2>&1 &
nohup /opt/node-v26.13.1-linux-x64/bin/node .yarn/releases/yarn-4.18.1.cjs nx run twenty-server:worker > /var/log/mgos/worker.log 2>&1 &
```

Only one MGOS dev stack runs per machine. Never stop/restart/migrate/reseed the
shared stack mid-run without the operator; if you need a second stack, use
different ports and a different database name.

## Health checks

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.100.181:3001/   # 200
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.100.181:3020/healthz  # 200
ssh sh2-stack "redis-cli ping"   # PONG
ssh sh2-stack "ps aux | grep -E 'queue-worker|dist/main|vite' | grep -v grep"
```

## Queue health

```bash
ssh sh2-stack "for q in webhook-queue workspace-queue entity-events-to-db-queue calendar-queue email-queue; do echo \"\$q wait:\$(redis-cli llen bull:\$q:wait) failed:\$(redis-cli zcard bull:\$q:failed)\"; done"
```

All zeros = healthy. A growing `wait` with no worker log activity means the
worker is down.

## Email behavior

`EMAIL_DRIVER` defaults to LOGGER in dev: emails are printed to the server or
worker log, not delivered. A password-reset flow therefore logs the reset URL
instead of mailing it — expected, not a bug. SMTP would require
`EMAIL_SMTP_*` env vars (operator decision).

## SSH

`Host sh2-stack` in `~/.ssh/config` maps to `root@192.168.100.181`. The repo
path on the box is `/srv/mgos/mgos` (a clone, not an agent worktree — treat it
as a fixed checkout).