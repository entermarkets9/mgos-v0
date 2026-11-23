# Phase 7 — Inheriting the MGOS design system

**Objective:** the new surfaces must look like MGOS, not like nabra-smma and not like stock
Twenty. Per Mohammed: *"nabra built on MGOS and inheriting MGOS design system."*

---

## 7.1 What "inheriting the design system" actually means here

The Phase A rebrand already established the mechanism, and it is not a fork:

| Layer | Mechanism | Evidence |
|---|---|---|
| Theme | `--t-accent-*` CSS variable ramp in `src/mgos-theme.css`, loaded after Twenty's theme CSS | committed `19bdd7a1` |
| Mode | Twenty's own class toggle (`.light` / `.dark`) | `BaseThemeProvider` |
| Token vocabulary | `themeCssVariables` object → CSS custom properties | `twenty-ui/src/theme/themeCssVariables.ts` |
| Branding override precedent | `SalesfarceTheme` — variable overrides + class toggle + favicon swap | `modules/salesfarce/` |

So the rule for every new page: **use `themeCssVariables`, never a literal colour.** A
hardcoded hex in `/ads` or `/content` breaks dark mode and the monochrome brand in one shot.

---

## 7.2 Token contract for the new surfaces

| Need | Token | Never |
|---|---|---|
| Page background | `themeCssVariables.background.primary` | `#fff` |
| Card / panel | `background.secondary` | `#f5f5f5` |
| Divider | `border.color.medium` | `#ddd` |
| Primary text | `font.color.primary` | `#000` |
| Muted text | `font.color.secondary` / `.light` | `#666` |
| Accent fill | `background.transparent.blue` (remapped to monochrome by `mgos-theme.css`) | any blue literal |
| Danger | `font.color.danger` | `#e00` |
| Radius | `border.radius.sm` / `.md` | `4px` |
| Spacing | `spacing[n]` | raw `px` |
| Shadow | `boxShadow.strong` / `.light` | hand-rolled |
| Icon size | `icon.size.sm/md/lg` | `16px` |

**Monochrome consequence:** because `--t-accent-primary` is now `#e8e8e8` and
`--t-accent-accent11` is `#363636`, any UI that relies on the accent being *saturated* will
look flat. Charts, status badges and "active" states need deliberate treatment:

| Element | Monochrome approach |
|---|---|
| Positive/negative deltas | weight and arrow glyph, not colour alone |
| Chart series | distinct greys + line style (solid/dashed), not hue |
| Status | icon + label, never colour-only (also an **accessibility** win) |
| Focus ring | `#363636` at 2px, visible on both light and dark |
| Selected nav item | filled grey, not a blue bar |

Colour-only encoding fails **accessibility** (WCAG 1.4.1) and fails the **contrast**
requirement in monochrome. Designing for it now avoids retrofitting later.

---

## 7.3 Component reuse

| Need | Use | Don't build |
|---|---|---|
| Table / list | Twenty's record table primitives | a second grid |
| **Calendar view** | Twenty's calendar display, or a thin wrapper on the same tokens | a bespoke calendar library with its own styling |
| **Kanban** | Twenty's kanban primitives | |
| Empty state | Twenty `AnimatedPlaceholder` pattern | |
| Loading | **skeleton loader** on `background.transparent.lighter` | spinners with hardcoded colours |
| Feedback | Twenty **toast** | custom alert |
| Modal / **drawer** | Twenty modal + side panel | |
| **Badge** | Twenty badge with token colours | |
| **Tooltip** | Twenty tooltip | |
| **Pagination** | Twenty pagination | |
| **Filter** / **sort** UI | Twenty's | |
| **Breadcrumb** | Twenty's page header | |
| **Tab** | Twenty tab primitives | |

Anything built custom is a future inconsistency. The default answer is "use theirs".

---

## 7.4 Charts

No chart library ships in the current phase. Before adding one:

- Must consume CSS variables, or be themed explicitly for both modes.
- Must not assume a multi-hue palette (monochrome brand).
- Must support a **time series** with an "as of" annotation.
- Must lazy-load — a chart library is the largest single frontend dependency.
- Must render a non-visual fallback table for **accessibility**.

Recommendation: reuse whatever Twenty already carries for its dashboard widgets rather than
adding a second chart stack.

---

## 7.5 Iconography and branding

| Item | Rule |
|---|---|
| Nav icons | Twenty `twenty-ui/icon` set only (`IconChartHistogram`-class names) |
| MGOS **logo** | the supplied `mgos-logo.svg` / `mgos-logo-dark.svg`, not a redrawn mark |
| **favicon** | already rasterised in Phase A; do not regenerate per page |
| **brand kit** | the monochrome palette; no new colours introduced by a feature |
| **alt text** | every icon-only button gets one (Phase A already fixed email alts) |
| **logo overlay** on creatives | out of scope — that is a creative-design concern, not app UI |

---

## 7.6 Internationalisation

| Rule | Detail |
|---|---|
| **i18n** | every user string goes through `t\`…\`` / `i18n._()`; never a literal |
| Catalogues | the 35 `.po` files already carry MGOS branding from the sweep |
| **RTL** | must be verified for `/ads` and `/content`; Twenty supports it, custom CSS often breaks it |
| Plurals | use lingui plural forms, not string concatenation |
| Dates/numbers | locale-aware formatting, plus explicit **timezone** for any ad timestamp |
| Currency | format with the ad account's currency code, never assume `$` |

A hardcoded `$` in a Dubai ad account showing AED is a credibility bug.

---

## 7.7 Responsive and interaction

| Concern | Requirement |
|---|---|
| Breakpoints | follow Twenty's existing set |
| Mobile | `/ads` and `/content` must be usable on the mobile nav pattern Twenty already has |
| **keyboard navigation** | every interactive element reachable, in a sane order |
| **focus ring** | visible on both themes, 2px, token colour |
| **contrast** | WCAG AA minimum; monochrome pairs must be tested, not assumed |
| **accessibility** | landmarks, labels, live regions for async status |
| Reduced motion | respect `prefers-reduced-motion` |

---

## 7.8 Exit gate

- [ ] Zero literal colours in the new pages (lint rule or grep gate in CI)
- [ ] Both light and dark verified by screenshot
- [ ] Monochrome chart palette chosen with line-style differentiation
- [ ] Status never colour-only
- [ ] Focus ring visible and token-coloured
- [ ] RTL verified
- [ ] Currency formatted per account, not hardcoded
- [ ] Contrast checked on the grey-on-grey pairs
- [ ] No new chart library added without the criteria in 7.4 satisfied
