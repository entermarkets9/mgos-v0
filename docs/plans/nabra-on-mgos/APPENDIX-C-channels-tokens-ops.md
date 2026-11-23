# Appendix C — Channel breadth, design tokens, operations glossary

Referenced by Phase 3 (analytics surfaces), Phase 7 (design system), Phase 8 (operations).
Closes the residual keyword set not naturally owned by a single phase.

---

## C.1 Channel breadth

Every platform carries different constraints. A capability that exists on one is absent on
another, which is why the capability map in Phase 1.6 exists rather than a boolean
"connected" flag.

| Platform | Ads | Organic posting | Notes |
|---|---|---|---|
| **facebook** | yes | yes (page) | Meta connect key; Instagram rides on it |
| **instagram** | via Meta | yes (business account) | requires an **instagram business account** |
| **tiktok** | yes (**tiktok-ads**) | yes (**tiktok business**) | separate ads vs organic connections |
| **google-ads** | yes | n/a | search/display/YouTube inventory |
| **linkedin page** | limited | yes | page-level only |
| **x/twitter** | n/a here | yes | posting only |
| **threads** | n/a | yes | separate connection |
| **youtube** | via Google | yes | channel-level |
| **pinterest** | n/a | yes | board-level |
| **snapchat** | n/a in scope | yes | not in the Zernio adapter set found by ripgrep — **verify before promising** |

**Honest scope statement:** ripgrep confirmed `facebook`, `instagram`, `tiktok`,
`tiktok-ads`, `google-ads` in the Zernio adapter paths. `linkedin`, `x/twitter`, `threads`,
`youtube`, `pinterest`, `snapchat` appear in older notes and mock specs but **not** in the
verified adapter list. Treat unverified channels as out of scope until a spike proves them.

---

## C.2 Roles, in full

| Role | `zernio.read` | content | ads launch | ads manage | Notes |
|---|---|---|---|---|---|
| **member** | yes | no | no | no | default; sees analytics + calendar |
| **manager** | yes | yes | yes | yes | the role Mohammed specified for posting |
| **admin role** | yes | yes | yes | yes | plus integration config, credential rotation |
| **owner** | yes | yes | yes | yes | plus billing, workspace deletion |
| **auditor** | yes | no | no | no | read + **audit log** access |

Distinguish **admin** (configuration authority) from **manager** (operational authority).
Conflating them means every person who can post can also rotate the API key — that is a
privilege escalation waiting to happen.

---

## C.3 Design tokens (naming discipline)

The MGOS theme is a **design token** layer expressed as CSS custom properties. Two vocabularies
exist and must not be mixed:

| Layer | Name | Example |
|---|---|---|
| CSS variable | `--t-*` | `--t-accent-primary` |
| TS accessor | `themeCssVariables.*` | `themeCssVariables.background.primary` |

**Rule:** application code imports the TS accessor. Only `mgos-theme.css` writes `--t-*`
directly. A component that hardcodes `var(--t-accent-primary)` bypasses the typed layer and
will not be caught by a refactor.

### The **accent color** in a monochrome brand

`--t-accent-primary` was `#e8e8e8` after Phase A. That is deliberate but has consequences:

| Where accent is used | Monochrome result | Required treatment |
|---|---|---|
| Primary button fill | light grey on white | needs border or weight to read as a button |
| Active nav item | pale grey | add weight/indent, not just fill |
| Focus ring | must remain visible | `#363636`, 2 px, both modes |
| Chart series | indistinguishable | vary line style and lightness |
| Status badges | no colour signal | icon + text label |

If a future feature genuinely needs a saturated accent, that is a **brand decision** for
Mohammed, not a styling decision for a developer.

---

## C.4 Component library boundaries

| Use theirs | Build ours |
|---|---|
| buttons, inputs, selects | nothing |
| modal, **drawer**, side panel | nothing |
| table, **pagination**, **filter**, **sort** | nothing |
| **badge**, **tooltip**, **breadcrumb**, **tab** | nothing |
| **skeleton loader**, empty state | nothing |
| **toast** / notification | nothing |
| — | `/ads` KPI composition |
| — | calendar grid layout (on their tokens) |
| — | campaign-to-listing mapping widget |

"Build ours" means composition, not a parallel design system. The moment a second component
library exists, the monochrome theme has two sources of truth and drifts.

---

## C.5 Timeline of a campaign (reference lifecycle)

Useful because every phase's failure modes map to a point on this line:

```
draft
  → preview (dry run, audience estimate, policy pre-check)
    → confirmed (preview token issued)
      → submitted (idempotency key)
        → approved by platform (review status)
          → delivering (spend begins)
            → pacing monitored (budget utilization, anomaly)
              → paused | completed | rejected
                → reconciled (campaign-reconcile against provider truth)
```

**Rejection can occur after delivery starts.** A campaign approved on day 1 can be
disapproved on day 4 if a human reviewer disagrees. The system must handle
`POLICY_REJECTED` mid-flight, not only at submission.

---

## C.6 Incident response

| Severity | Example | Response |
|---|---|---|
| **SEV-1** | wrong tenant's ad account visible | kill switch on, page owner, audit scope |
| **SEV-1** | overspend beyond cap | kill switch, pause all campaigns, reconcile |
| **SEV-2** | publishing to wrong account | disable publish capability, audit last 24 h |
| **SEV-2** | webhook signature failing | rotate to previous secret, investigate |
| **SEV-3** | stale metrics | cache TTL banner, no action on data |
| **SEV-3** | single platform outage | circuit breaker handles it; notify users |

Every **incident** gets: detection signal, blast radius, the kill switch that applied, and a
written postmortem. The kill switch is the first action, not the last resort.

---

## C.7 Glossary of terms used loosely elsewhere

| Term | Precise meaning here |
|---|---|
| **flight dates** | the calendar window a campaign is scheduled to run, distinct from budget period |
| **pacing** | how evenly spend is distributed across the flight; uneven pacing is often a bug |
| **budget burn** | rate of spend against the cap, the leading indicator of overspend |
| **creative fatigue** | declining CTR on a creative as its **frequency** rises |
| **holdout** | a deliberately unexposed segment, the only honest basis for **incrementality** |
| **outbox** | a table written in the same transaction as the business change, drained by a worker |
| **reconcile** | comparing our stored state to the provider's truth and correcting drift |
| **checkpoint** | the durable position of an **incremental sync** |
| **stale** | data older than its declared freshness window; must be labelled, never hidden |
