# MGOS rebrand — plan and readiness (2026-11-23)

**Target:** rebrand Twenty → MGOS in `entermarkets9/mgos`, verify on sh2 dev, ship to sh5b.
**Author:** Vizier. **Status:** plan written, awaiting go.
**Surface measured on the live tree**, not estimated.

---

## 1. Brand assets — FOUND

Located in `C:\Users\jacks\Downloads` on GTR6 (2026-10-12):

| File | Size | Purpose |
|---|---|---|
| `mgos-logo.svg` | 3,264 B | Light-surface logo (light grey tile `#D9D9D9`, dark glyph `#363636`) |
| `mgos-logo-dark.svg` | 3,264 B | Dark-surface logo (dark tile `#363636`, light glyph `#D9D9D9`) |

Both are 512×512, `viewBox="0 0 512 512"`, rounded square tile (`rx="51"`), containing the
**MGOS** wordmark plus a glyph. Copied to `media/mgos-brand/` on the gateway.

### 1.1 The gap these logos expose

**The palette is monochrome.** The only two colours in either SVG are `#D9D9D9` and
`#363636`. There is **no accent / primary colour**.

That matters because Twenty's UI depends on a brand colour in many places: primary buttons,
active nav highlight, focus rings, links, checkboxes, chart series, badges. If I invent one,
I am making a brand decision that is yours. This is **readiness gate G-2**.

Options if you do not supply one:
- (a) Keep Twenty's blue as an interim accent and swap later — least risk, obvious placeholder.
- (b) Use `#363636` as primary (monochrome brand) — bold, but active states get subtle.
- (c) You give me a hex value now.

### 1.2 Also missing

- **Favicon sizes.** Twenty expects `android-launchericon-{48,72,96,144};192;512`, `ios/192`,
  Windows tiles, and `favicon.ico`. I can rasterise these from the SVG, but I need your nod
  on (i) whether the tile background stays `#D9D9D9` at 16–32 px (it will look washed out on
  dark browser chrome) and (ii) whether a simplified glyph-only mark exists for small sizes.
- **Font.** The wordmark in the SVG is outlined paths, so the UI font is unconstrained. I will
  keep Twenty's font stack unless you say otherwise.

---

## 2. Measured rebrand surface

Everything below was counted on the live tree at `e660c71e`.

| Item | Count | Rebrand treatment |
|---|---|---|
| Packages named `twenty-*` | **16** | Phase B |
| `twenty.com` string occurrences | **2,993** | mix: Phase A (user-facing) + keep (canonical URLs) |
| `twentyhq` occurrences | **1,903** | mostly `keep-upstream-ref` |
| Migration files mentioning twenty | **667** | **keep** — persisted identifiers |
| Front locale catalogs (`.po`) | **35** | Phase A |
| Email package files mentioning twenty | **113** | Phase A |
| Server source files mentioning `Twenty` | **877** | mixed |
| Icon/logo assets in `twenty-front/public/images` | many | Phase A |
| Navigation/route enum entries | `AppPath` | already has Calculator precedent |

### 2.1 Concrete branding anchors (exact file:line)

```
packages/twenty-front/index.html
  15: <meta name="theme-color" content="#000000" />
  16: <meta name="description" content="A modern open-source CRM" />
  21: og:description  "A modern open-source CRM"
  22: og:title        "Twenty"
  29: twitter:description
  30: twitter:title  "Twenty"
  31: <title>Twenty</title>
  18: og:image        https://raw.githubusercontent.com/twentyhq/twenty/main/docs/static/img/social-card.png

packages/twenty-front/public/manifest.json
  2: "short_name": "Twenty"
  3: "name": "Twenty"

packages/twenty-front/src/locales/*.po   (35 files)
  e.g. msgid "Twenty works better with your team"
       msgid "Twenty Cloud" / "Twenty fields" / "Twenty team"
       msgid "Registered with Twenty as the official {appName}"
```

`{appName}` is already interpolated — Twenty built a hook for exactly this. Locating the
`appName` constant is step 1 of Phase A, because it may rebrand many surfaces at once.

---

## 3. Phase plan

### Phase A — visible branding (the phase you can judge)

Order matters: find the interpolation hooks first, so we change one constant instead of 200 files.

1. **Locate `appName` / product-name constants.** Grep for `APP_NAME`, `appName`, and the
   `useLingui` derivation. If a single constant feeds titles and emails, this is a one-line change
   with wide effect.
2. **`index.html`** — title, description, og/twitter tags, og:image (host the MGOS social card
   locally rather than pointing at `twentyhq`).
3. **`manifest.json`** — `name`, `short_name`, theme/background colour from brand.
4. **Icons** — rasterise both SVGs into the full favicon/PWA set. Replace the `twenty` glyph
   assets in `public/images`.
5. **Logo component** — find where the wordmark renders in the app shell (login screen,
   sidebar/workspace switcher, empty states) and swap to the MGOS SVG component.
6. **Emails** (113 files) — sender name, footer, templates. These are user-visible in inboxes.
7. **Locale catalogs** (35 `.po`) — replace `Twenty` msgids/msgstrs. Keep `{appName}` interpolation
   intact. Recompile with lingui.
8. **Auth pages** — sign-in/sign-up/verify/reset, plus page `<title>`s.
9. **Theme tokens** — wire the brand accent (blocked on G-2).

**Exit gate:** login page, app shell, sidebar, emails and page titles all read MGOS; no visible
"Twenty" anywhere a user can see; build green; dev server renders.

### Phase B — internal rename (deferred by default)

16 package names, directory names, symbols. **Recommendation: do not start this until Phase A is
accepted.** It is a large mechanical diff that risks the build for zero user-visible gain, and it
makes every future upstream merge harder.

### Phase C — never

- **Migrations (667 files).** Renaming strands data.
- **Redis queue names, storage prefixes, stored metadata keys.** Renaming orphans queued jobs.
- **`our` license headers, `LICENSE` files, third-party attribution.** Legal requirement.
- **Upstream git remotes, changelog refs.** Provenance and merge base.

---

## 4. Readiness gates

| ID | Gate | Owner | Status |
|---|---|---|---|
| G-1 | Brand logo assets supplied | Mohammed | ✅ **met** — two SVGs found |
| G-2 | **Accent/primary colour** | Mohammed | ❌ **blocking Phase A step 9** |
| G-3 | Favicon small-size treatment (tile bg at 16–32 px) | Mohammed | ❌ blocking step 4 |
| G-4 | Scope confirmed: Phase A first, Phase B deferred | Mohammed | ⏳ recommended, not confirmed |
| G-5 | Persisted identifiers untouched | Vizier (recommended) | ⏳ needs your confirm |
| G-6 | License headers/notices preserved (AGPL) | Vizier (recommended) | ⏳ needs your confirm |
| G-7 | Where it lands: repo → sh2 → sh5b | Mohammed | ⏳ assumption, unconfirmed |
| G-8 | Working tree clean before big diff | Vizier | ⚠️ 3 uncommitted files (Calculator) |

### 4.1 G-8 detail — commit the Calculator first

```
 M packages/twenty-front/src/modules/app/routing/utils/createWorkspaceRouteObjects.tsx
 M packages/twenty-shared/src/types/AppPath.ts
?? packages/twenty-front/src/pages/calculator/
```

A rebrand diff on top of uncommitted work makes any breakage unattributable. **Recommend
committing the Calculator work first** (it is proven and written up), so the rebrand diff is
isolated and revertable.

---

## 5. What I need from you to start

1. **Accent colour** — a hex, or pick "keep Twenty blue for now" / "use `#363636` monochrome".
2. **Favicons** — confirm the tile background stays, or prefer glyph-only at small sizes.
3. **Scope** — "Phase A only" (recommended) or "Phase A then B now".
4. **Identifiers + licences** — confirm: data layer and licence notices untouched.
5. **Order** — confirm repo → sh2 dev verify → sh5b ship.

If you say **"go with your recommendations"**, I will:
- keep Twenty's blue as interim accent (clearly marked for swap),
- rasterise favicons with the tile retained at ≥96 px and glyph-only below,
- do Phase A only,
- leave every persisted identifier and licence notice alone,
- commit the Calculator first, then rebrand on a branch,
- verify on sh2, then hand you the sh5b build step.

---

## 6. Risk register

| Risk | Severity | Mitigation |
|---|---|---|
| Locale edits break lingui compile | Medium | Edit msgid+msgstr pairs together, recompile, diff count |
| Package rename breaks the build (Phase B) | High | Deferred; if done, one package per commit with a build gate |
| Renaming a persisted key silently orphans data | **Critical** | Explicit denylist; never touch `migrations/`, queue names, storage prefixes |
| AGPL notice removal | **Critical** | Never delete headers/LICENSE; rebrand strings only |
| Upstream merges become painful | Medium | Keep Phase B optional; prefer interpolation over forking strings |
| Icon mismatch on dark browser chrome | Low | Provide both logo variants; test on both themes |
