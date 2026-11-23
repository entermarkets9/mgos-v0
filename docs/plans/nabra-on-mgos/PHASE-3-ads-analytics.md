# Phase 3 — `/ads` analytics page

**Objective:** a read-only ads analytics page in the MGOS sidebar. **Analytics only.** No
launch, no budget edit, no pause. Every mutation lives in Phase 5's AI path.

Per Mohammed: *"launch becomes /ads page which is just nabra's analytics page for ads."*

---

## 3.1 Route registration (mechanism already proven)

The Calculator preflight established the pattern; reuse it exactly.

| Step | File | Change |
|---|---|---|
| 1 | `packages/twenty-shared/src/types/AppPath.ts` | `Ads = '/ads'` |
| 2 | `packages/twenty-front/src/pages/ads/AdsAnalyticsPage.tsx` | new page |
| 3 | `createWorkspaceRouteObjects.tsx` | lazy import + route object with `workspaceSurfaces: MAIN_AND_SIDE_PANEL` |
| 4 | `core."navigationMenuItem"` | one `LINK` row, `name='Ads'`, `link='/ads'` |

**Known open issue to close first:** the Calculator row exists with `isActive=t` but does not
render in the sidebar on first load. Root cause is one of: client-side nav cache, or the
nullable `userWorkspaceId` join. Fix this before adding a second item, or `/ads` inherits
the same bug. Options: create the item through the UI's own "Edit navigation" flow and diff
what extra state it writes, or set `userWorkspaceId` explicitly.

---

## 3.2 Page composition

Wholly read-only. Sections in order of usefulness:

| Section | Content | Data |
|---|---|---|
| **Account strip** | connected **ad account**s, platform icon, status, currency | live (account state must be fresh) |
| **KPI row** | **spend**, **impressions**, **reach**, **clicks**, **CTR**, **CPC**, **CPM**, **CPA**, **ROAS** | aggregated snapshot |
| **Time series** | daily trend, one line per selected metric | aggregate table |
| **Breakdown** | by **campaign**, **ad set**, **ad**, **platform**, **placement** | aggregate table |
| **Top performers** | best **creative** by CTR and by conversions | aggregate table |
| **Alerts** | active **anomaly** and **threshold** breaches | ad-health rules |
| **Report export** | **export CSV**, **scheduled report**, **share link** | on demand |

Every widget shows an **"as of"** timestamp. Stale data presented as live is worse than no data.

---

## 3.3 Metric definitions (must be stated in the UI, not assumed)

| KPI | Definition | Trap |
|---|---|---|
| **spend** | platform-reported cost, normalised to display currency | **currency mismatch** if accounts differ |
| **impressions** | ad served count | summable across platforms |
| **reach** | unique people | **NOT summable** across platforms or campaigns without dedupe |
| **clicks** | link clicks (platform-specific definition) | Google and Meta count differently |
| **CTR** | clicks ÷ impressions | must use the same clicks definition |
| **CPC** | spend ÷ clicks | divide-by-zero when clicks = 0 |
| **CPM** | spend ÷ impressions × 1000 | |
| **CPA** | spend ÷ **conversions** | depends entirely on **conversion event** choice |
| **ROAS** | conversion value ÷ spend | requires a value, not just a count |
| **frequency** | impressions ÷ reach | meaningless without reach |
| **attribution** | click + view window | **attribution window** changes all conversion math |

**Rules:**
- Show the **attribution window** in the header, not buried in a tooltip.
- Never blend **last-click** and **first-click** in one number.
- **View-through** conversions shown separately from **click-through**.
- **Blended** ROAS labelled as blended, never compared directly to platform ROAS.
- Zero-denominator returns `—`, not `0`, and definitely not `Infinity`.

---

## 3.4 Filtering, segmentation, comparison

| Feature | Requirement |
|---|---|
| Date range | presets + custom; respects ad account **timezone** |
| **Segment** | by platform, campaign, ad set, **audience**, **placement**, device |
| **Breakdown** | **dimension** selector; multi-dimension capped for performance |
| **Cohort** | by campaign start date |
| **Benchmark** | vs previous period, clearly labelled |
| **Funnel** | impressions → clicks → landing views → conversions → **drop-off** |
| Saved views | per user, not global |
| **Filter** / **sort** / **pagination** | standard table behaviour, keyboard accessible |

---

## 3.5 Real-estate specific views

This is where MGOS beats a generic ads dashboard, because Twenty already holds the
**property listing**, **project**, **broker** and **enquiry** records.

| View | Join |
|---|---|
| Campaign → **listing** performance | campaign tag or **UTM parameters** → listing id |
| **Top performing listing** | creative → listing mapping, ranked by conversions |
| **Area campaign** / **community campaign** | geo **targeting** metadata |
| **funnel** from ad → **lead** → **enquiry** → **deal** → **commission** | cross-object |
| **cost per lead** vs **cost per deal** | blended across ad + CRM data |

The campaign-to-listing mapping is a **required** piece of metadata at launch time, or this
whole section is unbuildable later. It must be captured in the launch tool schema (Phase 5).

---

## 3.6 Explicit non-goals on this page

- No launch button.
- No budget input.
- No pause/resume.
- No creative upload.

A read-only analytics page cannot spend money. That is the point of the split. If a user
needs to act, the page tells them to ask the AI assistant.

---

## 3.7 Performance requirements

| Metric | Target |
|---|---|
| First contentful paint | < 1.5 s on the sh2 dev box |
| KPI row render | < 300 ms from cached aggregate |
| 90-day series query | < 200 ms (materialized view) |
| CSV export of 100k rows | streamed, not buffered in memory |
| Page usable while Zernio is down | yes — serves last cached aggregate with a warning banner |

---

## 3.8 Exit gate

- [ ] `/ads` registered, renders inside the Twenty shell
- [ ] Sidebar entry visible (depends on the nav-item fix)
- [ ] All KPI definitions documented in-page
- [ ] Reach non-summability enforced (sum button disabled across platforms)
- [ ] Zero-denominator renders `—`
- [ ] Attribution window surfaced in the header
- [ ] Page loads with Zernio unreachable, showing cached data + explicit warning
- [ ] No mutating HTTP method reachable from this route (verified by test)
