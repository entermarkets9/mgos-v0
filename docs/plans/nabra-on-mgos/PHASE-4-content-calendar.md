# Phase 4 — `/content` content calendar (read-only view)

**Objective:** a content calendar in the MGOS sidebar. Per Mohammed: *"content page in the
sidebar becomes a content calendar (just a view) but posting is done via AI."*

**Hard rule: this page is a view. It cannot post, schedule, edit, or delete.** Every write
lives in Phase 5.

---

## 4.1 Route registration

Same mechanism as Phase 3, proven by the Calculator preflight.

| Step | File | Change |
|---|---|---|
| 1 | `AppPath.ts` | `Content = '/content'` |
| 2 | `pages/content/ContentCalendarPage.tsx` | new page |
| 3 | `createWorkspaceRouteObjects.tsx` | lazy import + route object |
| 4 | `core."navigationMenuItem"` | `LINK` row, `name='Content'`, `link='/content'` |

**Prerequisite:** the nav-item visibility bug from Phase 3 must be fixed first. Two sidebar
items hitting the same bug is two workarounds instead of one fix.

---

## 4.2 What the calendar shows

A month/week **calendar view** of planned and published **content post**s, across every
connected **social account**.

| Column / cell content | Source |
|---|---|
| Date cell with **slot** counts | content slot table |
| Per-post chip: platform icon, account handle, **status** colour | content post |
| **scheduled** / **draft** / **published** / **failed** distinction | post status enum |
| Time in the **timezone** of the target account, with the account tz shown | post + account |
| **thumbnail** of the **creative** asset | media reference |
| **caption** preview on hover | post body |
| **hashtags** / **mentions** extracted and shown as chips | caption parse |

---

## 4.3 Status model (must be explicit, not implied)

| Status | Meaning | Who set it |
|---|---|---|
| `draft` | exists, nothing scheduled | AI or imported |
| `scheduled` | has a future **publishAt** | AI |
| `publishing` | in flight | system |
| `published` | confirmed by platform | system via webhook/poll |
| `failed` | terminal failure | system, with reason |
| `needs_attention` | e.g. **token revoked**, account disconnected | system |

`needs_attention` exists because a **failed publish** caused by a revoked **access token** is
not the user's content problem — it needs a reconnect, and burying it as "failed" hides the fix.

---

## 4.4 Calendar semantics that get people fired

| Trap | Handling |
|---|---|
| **Timezone** mismatch | Store UTC, display in account tz, print the tz label on the cell |
| **DST bug** | A post scheduled 09:00 local on a DST-change day must land at 09:00 local, not shift an hour |
| **Queue** vs fixed time | Distinguish "next free slot" from "exactly 14:30" — different promises |
| **Cross-posting** duplicates | One intent, N platform posts; show as one item expanding to children |
| **reschedule** ripple | Moving a slot must show what else moves |
| **slot** collision | Two posts to the same account at the same minute must warn, not silently both publish |
| **approval workflow** pending | A post awaiting approval renders differently from scheduled |
| **first comment**, **link in bio** | Optional per-platform fields; Calendar shows whether they exist |

---

## 4.5 Filters and views

| Filter | Values |
|---|---|
| Account | any connected **social account** |
| Platform | facebook, instagram, **linkedin page**, **tiktok business**, **x/twitter**, threads, youtube, pinterest |
| Status | any of the six above |
| **Campaign tag** / **content pillar** | taxonomy fields on the post |
| View | month / week / agenda list |

**Kanban** and **table** views are reasonable additions later; calendar is the required one.

---

## 4.6 What the page deliberately cannot do

- No compose box.
- No drag-to-schedule. (A drag is a write.)
- No delete.
- No "publish now".

If a user wants to act, the page offers a single affordance: **"Ask the assistant"**, which
deep-links into the AI sidebar pre-filled with the relevant post as context. That keeps one
write path, one audit trail, one permission check.

---

## 4.7 Performance

| Metric | Target |
|---|---|
| Month view render | < 400 ms |
| Asset thumbnails | lazy, responsive, cached |
| 12-month back-scroll | paginated query, not one giant fetch |
| Publish status freshness | webhook-driven; fall back to poll every 5 min |

---

## 4.8 Exit gate

- [ ] `/content` registered and renders in the Twenty shell
- [ ] Sidebar entry visible
- [ ] All six statuses render distinctly
- [ ] Timezone label on every cell; DST boundary unit-tested
- [ ] No mutating HTTP method reachable from this route (test asserts it)
- [ ] Cross-posted item renders as one parent with N children
- [ ] "Ask the assistant" deep-link carries post context
