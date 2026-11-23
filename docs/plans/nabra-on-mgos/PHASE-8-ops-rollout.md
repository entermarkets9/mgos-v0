# Phase 8 — Operations, hardening, rollout

**Objective:** make the system survivable. Observability, cost control, failure handling,
rollback, and a staged rollout that cannot hurt the existing CRM.

---

## 8.1 Environments and separation

| Environment | Zernio team | Key | Webhook secret | Data |
|---|---|---|---|---|
| dev | separate team | separate | separate | synthetic only |
| staging | separate team | separate | separate | synthetic only |
| production | separate team | separate | separate | real |

**Rule from nabra-smma's runbook:** *"Use a separate Zernio team, key and webhook secret per
environment."* Never one key across environments — a staging bug must never publish to a real
social account or spend real money.

| Concept | Requirement |
|---|---|
| **sandbox** | each platform's test mode where available; recorded per platform because they differ |
| **dry run** | default behaviour for every mutation tool |
| **feature flag** | each of `/ads`, `/content`, AI write tools independently switchable |
| **kill switch** | one flag disables all mutation, leaving reads working |
| **canary** | enable for one internal workspace before all |
| **staging → production** | promotion only after the Phase 6/7 exit gates pass on staging |

---

## 8.2 Observability

| Signal | What to record | Why |
|---|---|---|
| **logging** | structured, correlation id per request, no secrets, no caption bodies unless explicitly enabled | debugging without leaking PII |
| **tracing** | span per Zernio call, per tool invocation | latency attribution |
| **metric** | request rate, error rate by class, p95 latency, queue depth, **queue lag** | the four golden signals |
| **dashboard** | spend by account, campaign count, publish success rate | business view |
| **alert** | **threshold** rules on error rate, **budget burn**, publish failures | must wake someone |
| **alert rule** | per account: spend > X% of cap, error rate > 5%, zero publishes in 24 h when expected | actionability |
| **anomaly** | statistical deviation on spend/CTR vs 7-day baseline | catches silent breakage |
| **anomaly detection** | needs the daily snapshot history from Phase 2 — this is why 2A was recommended |
| **pacing alert** | projected end-of-flight overspend | the most expensive failure |
| **overspend alert** | actual spend exceeds cap | hard stop must already prevent this |
| **digest** | daily summary to the owner | passive awareness |
| **notification** | one channel, deduplicated, never per-event spam | |
| **SLO** | read availability 99.5%, publish success > 98% excluding policy rejections | contract with users |
| **uptime** / **health check** | `/healthz` covers DB, queue, Zernio reachability separately | partial degradation must be visible |

---

## 8.3 Cost and billing control

| Control | Implementation |
|---|---|
| **Spend cap** | per ad account, enforced in the tool handler *and* a DB constraint — two independent checks |
| **Budget owner** | named per account in config, not implicit |
| **Quota alert** | fires at 70% and 90% of cap |
| **Cost** tracking | record Zernio API call volume per workspace, so the integration's own cost is visible |
| **billing** / **invoice** | ad spend is billed by the platform, not by us — state this in the UI so nobody thinks MGOS charges them |
| **spend reconciliation** | daily comparison of our snapshot vs platform's own report; drift > 2% raises a flag |
| **currency mismatch** | each account reports in its own currency; never sum across currencies without an explicit FX snapshot and its date |

**Zernio's own limit:** 600 requests/min for 3–2,000 connected accounts. Our client budget
must stay under it (`ZERNIO_RPM`, default 500) so a retry storm cannot trip the provider.

---

## 8.4 Failure modes and required behaviour

Each of these needs an explicit test, because each is a real thing that happens:

| Failure | Required behaviour |
|---|---|
| **failed publish** | status `failed` with verbatim provider reason; never retried forever |
| **partial success** | per-platform result rows; user sees which landed |
| **token revoked** | `needs_attention`; account marked disconnected; no silent retry |
| **account disconnected** | excluded from launch targets until reconnected |
| **platform outage** | circuit open; reads serve cache with a banner; writes refused with a clear reason |
| **duplicate post** | idempotency key prevents; if it slips through, a dedupe sweep detects and alerts |
| **wrong audience** | prevented by preview showing audience summary + estimated reach |
| **overspend** | cap enforced server-side; a request above cap is refused, not clamped silently |
| **wrong creative** | preview shows the actual thumbnail |
| **deleted asset** | publish refuses with "asset missing", not a broken post |
| **orphaned campaign** | reconciled by `campaign-reconcile` job against provider truth |
| **timezone mismatch** | store UTC, display account tz, label it |
| **DST bug** | unit test at a DST boundary |
| **currency mismatch** | per-account currency, never naive sum |
| **rounding** | integer minor units end to end |
| **stale metrics** | "as of" timestamp on every widget |
| **delayed attribution** | conversions restated later; UI must not imply finality on day 1 |

---

## 8.5 Rollback

| Scenario | Rollback |
|---|---|
| A new MGOS release breaks `/ads` | feature flag off; pages disappear, CRM unaffected |
| A tool misbehaves | **kill switch** on mutations; reads continue |
| Bad schema migration | **expand-only** migrations mean rollback is code-only, no data loss |
| Provider key compromised | **secret rotation**; dual-secret window for webhooks |
| A campaign was launched in error | pause via tool; budget is not recoverable — that is why confirmation exists |

**Rollback never requires a database restore.** Same principle as the CRM plan: a whole-DB
restore would silently revert unrelated CRM data.

---

## 8.6 Data retention and privacy

| Item | Policy |
|---|---|
| Metric snapshots | retain 24 months, then aggregate-only |
| Content posts | retain while account connected; 90 days after disconnect |
| Audit log | 12 months minimum |
| Logs with any PII | redacted at write time, not at read |
| **PII redaction** in DLQ | mandatory — a failed payload can contain lead data |
| **retention policy** | written, not implied |
| **data residency** | which region each store lives in |
| **backup** | daily, with a **restore drill** scheduled, not assumed |
| **restore drill** | actually executed once before production go-live |

---

## 8.7 Staged rollout plan

| Step | Gate |
|---|---|
| 1. `/ads` read-only, internal workspace only | screenshots + no-write test |
| 2. `/content` read-only, internal workspace | timezone test green |
| 3. Read AI tools enabled | no mutation capability |
| 4. Content scheduling for one internal account | one real scheduled post, verified |
| 5. Content publishing, managers only | RBAC test green |
| 6. Ads launch in a platform sandbox | dry-run proven, then one real low-budget campaign with an explicit cap |
| 7. Full rollout | all gates above PASS |

Step 6 is the only step that can spend real money. It happens last, on one account, with a
hard cap, and with a named person watching.

---

## 8.8 Exit gate

- [ ] Environment separation verified (no shared keys)
- [ ] Kill switch tested: mutations stop, reads continue
- [ ] Feature flags independently toggle all three surfaces
- [ ] All 17 failure modes in §8.4 have a test
- [ ] Spend cap enforced twice (handler + DB) and tested with an over-cap request
- [ ] Quota alerts fire at 70% and 90%
- [ ] Anomaly detection produces a real alert on injected bad data
- [ ] Restore drill executed and timed
- [ ] Rollback performed once end to end on staging, without a DB restore
- [ ] Retention policy written and PII redaction verified in DLQ
- [ ] Staged rollout steps 1–5 completed before step 6 is attempted
