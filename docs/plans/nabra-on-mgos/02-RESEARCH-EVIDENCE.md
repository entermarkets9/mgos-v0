# Research evidence — ripgrep over nabra-smma

Source: `C:\codespace\nabra-smma` on GTR6, HEAD unknown (working tree), searched 2026-11-23.
Tool: `rg.exe` (ripgrep), globs excluding `node_modules`, `dist`, `*.test.*`, `*.spec.*`.

---

## 1. Zernio files (real paths)

**Client**
```
client/src/lib/zernioAdsOAuth.ts
client/src/lib/oauthPopup.ts
client/src/lib/launchSelection.ts
client/src/pages/ads-manage.tsx
client/src/pages/ads-manage-tiktok-audience-dialog.tsx
client/src/pages/launch/useLaunchQueries.ts
client/src/pages/launch/useLaunchAnalysisActions.ts
client/src/components/ad-health/SpendPlanner.tsx
client/src/components/ad-health/ProviderAudienceEstimate.tsx
client/src/components/launch/LaunchAnalysisStep.tsx
client/src/components/launch/GoogleCustomerPicker.tsx
client/src/components/content/ContentPublishingWizard.tsx
client/src/pages/settings/ZernioSocialAdsPanel.tsx
client/src/pages/settings/ZernioMetaToolsSection.tsx
client/src/pages/settings/IntegrationsSection.tsx
```

**Server**
```
server/zernio/connect.ts
server/zernio/destinations.ts
server/zernio/leads.ts
server/content-publishing/upstreams/zernio.ts
server/ads/launch/runtime.ts
server/ads/launch/service.ts
server/ads/launch/handoff.ts
server/ads/launch/providers/meta.ts
server/ads/launch/providers/google.ts
server/ads/launch/providers/tiktok.ts
server/ads/manage/service.ts
server/ads/campaign-reconcile.ts
server/ad-health/{detectors,episodes,events,forecast-comparison,planner,planner-guidance,provider-estimates,provider-reads,registry,store,sync,worker}.ts
server/ads-analytics/{core,google,meta,retained,service,status,tiktok-metrics}.ts
server/ai/sdk-tools/{ads-read-tools,ads-launch-tools,campaign-mutation-tools,content-rule-lead-tools,integration-tools,composio-dynamic}.ts
server/composio/publishing.ts
server/composio/tiktok-launch.ts
server/routes/tiktok.ts
scripts/zernio/register-webhook.ts
scripts/zernio/spike.ts
```

**Migrations / schema**
```
migrations/0119_zernio_foundation.sql
migrations/meta/0119_snapshot.json
```

**Docs (the ones that matter)**
```
docs/current/notes/zernio-integration-plan.md
docs/current/notes/zernio-handover.md
docs/current/notes/zernio-qa-2026-11-20.md
docs/current/04-operations-runbook.md
docs/current/05-codebase-map.md
docs/current/06-open-work.md
docs/current/07-decisions-and-rules.md
openapi.yaml
```

---

## 2. Zernio configuration contract (from runbook + env example)

| Variable | Purpose | Required |
|---|---|---|
| `NABRA_SOCIAL_PROVIDER` | `native` (default) or `zernio`; anything else stops boot | yes |
| `ZERNIO_API_KEY` | Full-access team key | in `zernio` mode |
| `ZERNIO_WEBHOOK_SECRET` | We generate it, 32+ bytes hex; Zernio never generates | in `zernio` mode |
| `ZERNIO_BASE_URL` | Default `https://zernio.com/api/v1`; tests point at a stub | optional |
| `ZERNIO_RPM` | Client request budget, default 500; Zernio allows 600/min for 3–2,000 accounts | optional |

**Critical operational facts, verbatim from their runbook:**
- Mode `zernio` is **exclusive** — server and worker refuse to boot without the key and secret.
- Signed receiver is `POST /api/webhooks/zernio`, returns 503 when the switch is off.
- **Use a separate Zernio team, key and webhook secret per environment** (dev, staging, production).
- Migrations `0110`–`0112` are expand-only (new tables, nullable columns).

---

## 3. Ads domain — where the logic actually lives

Concept frequency by file (from ripgrep counts):

| File | Top concepts |
|---|---|
| `providers/meta.ts` | campaign (55), adset (49), creative (34), targeting (16), daily_budget (16), objective (14), lifetime_budget (10) |
| `providers/google.ts` | campaign (63) |
| `launch/handoff.ts` | campaign (38) |
| `launch/service.ts` | campaign (23), creative (23) |
| `manage/service.ts` | campaign (23) |
| `campaign-reconcile.ts` | campaign (19) |
| `launch/runtime.ts` | campaign (16) |
| `providers/tiktok.ts` | creative (11) |

**Interpretation:** there are per-platform launch providers, a launch service, a manage
service, and a reconcile job. That is a real orchestration layer — not a thin passthrough.
Porting it means porting four provider adapters plus reconciliation.

---

## 4. Metrics actually implemented

`ad-health`: detectors, episodes, events, forecast-comparison, planner, planner-guidance,
provider-estimates, provider-reads, registry, store, sync, worker.
Concepts used: `impressions`, `reach`, `clicks`, `ctr`, `cpc`, `cpm`, `cpa`, `roas`,
`spend`, `conversions`, `frequency`.

`ads-analytics`: core, google, meta, retained, service, status, tiktok-metrics.
Same concept set plus `retained` (retention of historical rows) and per-platform normalisation.

**Interpretation:** analytics is per-platform normalised into a common shape (`core.ts`),
with platform-specific extractors. A `/ads` analytics page in MGOS can consume the
normalised shape without caring which platform produced it.

---

## 5. Platforms in scope

`facebook`, `instagram`, `tiktok`, `tiktok-ads`, `google-ads` (plus `linkedin` present in
older session notes and mock specs, but not in the Zernio adapter paths).

**Canonical launch set from `zernioAdsOAuth.ts` signature:**
```ts
platform: "facebook" | "tiktok" | "tiktok-ads" | "google-ads"
```
Note the comment: *"`facebook` is the Meta connect key (Meta ads are a child account)"* —
so Instagram rides on the Meta connection.

---

## 6. Content publishing

`server/content-publishing/` with an `upstreams/zernio.ts` adapter.
`client/src/components/content/ContentPublishingWizard.tsx` is the UI.
`server/composio/publishing.ts` is an alternate path via Composio.

Concept presence: scheduled / draft / publishAt / timezone / calendar / approval / queue /
slot all appear in the content-publishing tree.

**Interpretation:** content publishing already models schedule + approval + queue. A
read-only calendar view is a projection of data that already exists.

---

## 7. AI tool surface

`server/ai/sdk-tools/` contains distinct tool modules:
- `ads-read-tools.ts` — read campaigns/metrics
- `ads-launch-tools.ts` — launch campaigns
- `campaign-mutation-tools.ts` — mutate existing campaigns
- `content-rule-lead-tools.ts` — content rules + leads
- `integration-tools.ts` — integrations
- `composio-dynamic.ts` — dynamic Composio tools

**Interpretation:** nabra-smma already separates **read tools** from **mutation tools** at
the AI layer. That separation is exactly the shape MGOS's AI-sidebar-writes-only design needs,
and it is evidence the design is sound rather than novel.

---

## 8. Permissions

`requirePermission("...")` is the gate idiom. `manage_integrations` confirmed present.
Manager/admin/owner concepts present throughout.

**Gap found:** ripgrep did not surface a dedicated `manage_ads` or `manage_content`
permission in the first pass. The gating may be role-based elsewhere. **This must be
verified before Phase 6** — it is the single most important unknown for Mohammed's
"managers only" requirement.

---

## 9. Webhooks

`ZERNIO_WEBHOOK_SECRET`, `scripts/zernio/register-webhook.ts`, signed receiver at
`POST /api/webhooks/zernio`. Idempotency and signature verification are implemented
in nabra-smma.

**For Option B, MGOS must reimplement these** — this is the main cost of choosing B.

---

## 10. OpenAPI

`openapi.yaml` exists at repo root, generated by `scripts/generate-openapi.ts`, with
`tests/openapi-route-coverage.test.ts` and `tests/openapi-schemas.test.ts` guarding drift.

**Useful even for Option B:** the OpenAPI spec documents the *shape* of the domain
(request/response schemas for launch, manage, analytics, content) even though MGOS will
call Zernio directly rather than this API.
