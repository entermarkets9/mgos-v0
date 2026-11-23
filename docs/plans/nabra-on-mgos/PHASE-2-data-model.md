# Phase 2 — Data model and storage

**Objective:** decide and implement where ad, content, and account data lives. This phase is
blocked on `D-DATA-01` (mirror vs live-fetch). Both options are specified here so the
decision can be made with the cost visible.

---

## 2.1 The two options, with real cost

### Option 2A — Mirror into Twenty `core` schema as custom objects

| Pros | Cons |
|---|---|
| Twenty views, filters, kanban, calendar, export all work for free | Must build **sync job** with cursor + **checkpoint** |
| Reporting joins campaign data to Property / Broker / Enquiry | Staleness: metrics lag the platform |
| Works when Zernio is briefly down | Schema **migration** needed for every new field |
| Record-level **permission** enforceable by Twenty itself | **Duplicate** rows risk on replay — needs **idempotency key** |
| **Anomaly** detection has local history | Storage growth; needs **retention policy** |

### Option 2B — Fetch live per request, store nothing

| Pros | Cons |
|---|---|
| Always fresh; no sync bug class | No cross-object reporting |
| No migration, no storage | Every page load costs a Zernio call against the **rate limit** |
| No staleness | Calendar needs all accounts queried every view |
| No **duplicate** risk | Provider **outage** = empty page, no fallback |
| | Historic **cohort** / trend analysis impossible without history |

**Recommendation: 2A for campaigns + metrics (daily snapshot), 2B for account state.**
Rationale: metrics are append-only facts that want history for trend and **anomaly**
detection; account connection state must be live because a revoked **access token** must
show immediately.

---

## 2.2 Objects to model (mirroring nabra-smma's domain)

| Object | Key fields | Notes |
|---|---|---|
| **Ad Account** | external id, platform, name, currency, timezone, status | currency matters for **currency mismatch** in reporting |
| **Connected Social Account** | platform, handle, page id, scopes, token expiry | **instagram business account** rides on the Meta connection |
| **Campaign** | external id, ad account, name, objective, status, budget | maps to Meta `campaign` / Google `campaign` |
| **Ad Set / Ad Group** | campaign, targeting, placement, bid strategy | Meta calls it `adset`, Google `ad_group` — normalise |
| **Ad / Creative** | ad set, headline, primary text, CTA, asset refs | **creative fatigue** tracking needs per-creative metrics |
| **Metric Snapshot** | date, entity, impressions, reach, clicks, spend, conversions | append-only, one row per entity per day |
| **Content Post** | social account, caption, media refs, status, scheduled time | status incl. draft / scheduled / published / failed |
| **Content Slot** | calendar slot, account, post ref | drives the calendar view |

Field naming must match Twenty's **metadata** conventions so the objects behave like native
records (`label`, `name`, `description`, relations, **lookup** fields).

---

## 2.3 Platform normalisation table

The single hardest correctness problem: platforms disagree about everything.

| Concept | Meta | Google Ads | TikTok |
|---|---|---|---|
| campaign | `campaign` | `campaign` | `campaign` |
| ad group | `adset` | `ad_group` | `adgroup` |
| budget field | `daily_budget` / `lifetime_budget` (minor units ×100) | `budget_micros` (×1,000,000) | `budget` |
| spend | `spend` | `cost_micros` | `spend` |
| reach | `reach` (unique) | n/a (impressions only) | `reach` |
| conversions | `actions` (varies by **conversion event**) | `conversions` | `conversions` |
| attribution | **attribution window** configurable (7d click / 1d view) | modelled differently | platform default |

**Rules:**
- Store money in **minor units as integer**; never float. **Rounding** differences are a real bug class.
- Record the platform's own currency and the display currency separately.
- **Timezone** and DST: store all timestamps UTC, but *report* in the ad account's timezone. A **DST bug** here silently shifts a day's spend.
- Never sum `reach` across platforms — it double-counts people.

---

## 2.4 Migration and schema safety

- Migrations are **expand-only** first (new tables, nullable columns), matching nabra-smma's `0110`–`0112` precedent.
- **Index** on `(entity_type, entity_id, date)` for metric queries.
- **Constraint**: unique on `(external_id, platform, ad_account_id)` to make replay safe.
- **Soft delete** for campaigns that vanish upstream; never hard-delete history.
- **Versioning** on the normalisation layer so a platform API change does not silently reinterpret old rows.
- **Audit trail** on any local mutation (budget change, pause) — who, when, before, after.

---

## 2.5 Sync design

```
cron (every N minutes)
  └─ sync job per ad account
       ├─ cursor from checkpoint (incremental)
       ├─ page through provider (pagination)
       ├─ normalise → upsert with idempotency key
       ├─ advance checkpoint transactionally
       └─ enqueue derived work (anomaly detect, aggregate refresh)
```

- **Full sync** available on demand (nightly) to catch drift.
- **Rate limit** aware: respect `ZERNIO_RPM`, back off on 429.
- **Outbox** pattern for events so a crash between write and enqueue cannot lose work.
- **Materialized view** or **aggregate table** for dashboards — never scan raw metrics per page load.
- **Cache** the aggregate with explicit TTL; show the "as of" timestamp in the UI.

---

## 2.6 Exit gate

- [ ] `D-DATA-01` answered; chosen option documented
- [ ] Custom objects created in the Mgos workspace and visible in Twenty's UI
- [ ] Normalisation table implemented with unit tests per platform
- [ ] Money as integer minor units verified (no float anywhere in the path)
- [ ] Replay of the same provider payload produces zero duplicates
- [ ] Checkpoint resumes correctly after a mid-sync kill
- [ ] Aggregate view refresh measured under 200 ms for a 90-day range
- [ ] Retention policy written (how long to keep daily snapshots)
