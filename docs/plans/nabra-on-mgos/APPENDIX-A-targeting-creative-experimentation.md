# Appendix A — Targeting, audiences, creative, experimentation

Referenced by Phase 5 (launch tool schema) and Phase 2 (normalisation).
Every term here exists because a real launch form needs it.

---

## A.1 Account and identity layer

| Term | Meaning in MGOS | Where it enters |
|---|---|---|
| **ad account id** | Platform's stable identifier, e.g. Meta `act_123`, Google `customers/456` | stored on the Ad Account object, used in every API path |
| **business manager** | Meta's container above ad accounts; also Google MCC | needed for `business page` and page-level permissions |
| **business page** | The Facebook Page an ad or post attaches to | required on every Meta creative; wrong page = wrong brand |
| **refresh token** | Long-lived credential used to mint short-lived `access token`s | stored encrypted; expiry tracked; `TOKEN_EXPIRED` when refresh fails |

**Rule:** ad account id and business manager are configuration, not user input. A broker
picking their account from a dropdown of pre-bound accounts is safer than typing an id.

---

## A.2 Targeting dimensions

Every dimension below is a **targeting** field on the launch form and must round-trip
through the preview so the user sees what they are buying.

| Dimension | Detail | Trap |
|---|---|---|
| **demographics** | age, gender | minimum ages differ per platform |
| **geo targeting** | countries, regions, cities, postcodes | real-estate is hyper-local: radius matters more than country |
| **radius targeting** | centre point + radius | a 50 km radius in Dubai spans water; validate against the listing's actual area |
| **language targeting** | language codes | Dubai campaigns often need Arabic **and** English |
| **interest targeting** | platform interest graph | interest supply varies wildly by market |
| **device targeting** | mobile / desktop / tablet | may be restricted in some objectives |
| **placement** | feed, story, search, display network | automatic vs manual placement changes CPM dramatically |
| **dayparting** | hour-of-day scheduling | different from campaign **flight dates** |

### Audiences

| Audience type | Definition | Build complexity |
|---|---|---|
| **custom audience** | uploaded list or site visitors | needs consent basis + hashing |
| **lookalike audience** | platform-derived similar users from a seed | requires a seed of minimum size |
| **retargeting** | previous visitors / engagers | needs **pixel** or platform tag firing |
| **exclusion audience** | never show to these | must be applied at ad-set level, not campaign |
| **frequency cap** | max impressions per person per window | protects against **creative fatigue** |

### Measurement plumbing that makes audiences work

| Term | Meaning |
|---|---|
| **pixel** | Meta's on-site tag; without it there is no retargeting and no conversion signal |
| **custom conversion** | a named event defined from raw events (e.g. "enquiry submitted") |
| **conversion event** | what the campaign optimises toward |
| **tracking template** | URL-parameter pattern applied platform-side |
| **UTM parameters** | our own attribution into the CRM |
| **landing page** / **destination URL** | where the click goes |
| **deep link** | app or specific page target, not the homepage |

**Non-negotiable for MGOS:** the launch tool must require a `listing ref` and a
`campaign tag`. Without those two fields the campaign-to-listing mapping is lost forever and
the real-estate analytics in Phase 3 cannot be built retroactively.

---

## A.3 Creative formats

| Format | Constraints | Notes |
|---|---|---|
| **image** | per-platform **aspect ratio** (1:1, 4:5, 9:16), **file size limit** | reuse across placements only within tolerance |
| **video** | **duration limit**, **codec**, resolution, bitrate | needs **transcode** per platform |
| **carousel** | 2–10 cards, each with own copy | strong for property galleries |
| **collection** | product/listing grid | limited availability by market |
| **reel** | 9:16 vertical, short-form | highest reach in the region |
| **story format** | 9:16, ephemeral | **safe zone** matters — UI overlays eat the top/bottom ~15% |
| **ad copy** | **headline**, **primary text**, **description** | character limits per platform |
| **call to action** (**CTA**) | enumerated per platform | "Enquire" vs "Learn more" changes intent |
| **asset library** | reusable media store | dedupe by hash to avoid re-uploading |
| **variation** | a creative variant within an ad | the unit an **A/B test** compares |

**Safe zone** is not cosmetic: text or logo inside the Story UI band is invisible. The
preview must render each placement's overlay guides.

---

## A.4 Experimentation

| Term | Definition | MGOS support |
|---|---|---|
| **A/B test** | two variants, one variable | require one changed variable only |
| **split test** | platform-native budget split | delegated to platform, we read the result |
| **multivariate** | 3+ combinations | warn: needs traffic volume to reach significance |
| **holdout** | segment deliberately not exposed | needed for **incrementality** claims |
| **incrementality** | lift caused by ads vs would have happened anyway | requires holdout; without it ROAS is correlation |

**Honest-position rule:** MGOS must not present platform-reported ROAS as incremental
revenue. Label it "platform-attributed" and, where a holdout exists, show both.

---

## A.5 Objective and bidding

| Term | Notes |
|---|---|
| **campaign objective** | awareness / traffic / engagement / leads / **app promotion** / sales — drives everything downstream |
| **optimization goal** | within objective, what the algorithm optimises |
| **bid strategy** | lowest cost, cost cap, bid cap, target |
| **bid cap** | hard ceiling per auction |
| **target CPA** | desired cost per acquisition |
| **target ROAS** | desired return on ad spend |
| **daily budget** / **lifetime budget** | mutually exclusive on most platforms |
| **budget utilization** | actual spend ÷ planned spend; a campaign at 40% utilisation is mis-set, not cheap |
| **end date** | when the **flight dates** close |
| **campaign analysis** | the AI's job: explain utilisation, pacing, and deviation |
| **auto-optimize** | platform-side auto-bidding; must be visible that we did **not** set a manual bid |
