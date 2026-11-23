# nabra on MGOS — plan index

**Goal:** bring nabra-smma's ads and content-posting features into MGOS, inheriting
MGOS's design system, with Zernio as the provider. **Option B**: MGOS calls Zernio
directly, no nabra-smma service dependency.

**Owner shape (from Mohammed, 2026-11-23):**
- nabra built **on** MGOS, inheriting the MGOS design system
- Zernio MCP/SDK wired to the **Twenty AI sidebar**
- **Only manager roles** may post ads or content
- Content page in the sidebar becomes a **content calendar — read-only view**;
  actual posting is done **via AI**
- Launch becomes `/ads` — nabra's **ads analytics** page
- Writes: none in this deliverable. Plan only.

---

## Reading order

| File | Purpose |
|---|---|
| `01-KEYWORDS-brainstorm.md` | Every concept written blind, before reading code |
| `02-RESEARCH-EVIDENCE.md` | Ripgrep output: what nabra-smma actually contains |
| `03-COVERAGE-MATRIX.md` | Proof every keyword appears in ≥1 phase file |
| `PHASE-0-readiness.md` | Gates, decisions, blockers |
| `PHASE-1-zernio-client.md` | Zernio HTTP client, auth, rate limit, error model |
| `PHASE-2-data-model.md` | What mirrors into Twenty's `core` schema |
| `PHASE-3-ads-analytics.md` | `/ads` page = analytics only |
| `PHASE-4-content-calendar.md` | `/content` = calendar view, read-only |
| `PHASE-5-ai-sidebar-mcp.md` | AI sidebar + MCP tool surface (all writes here) |
| `PHASE-6-rbac-manager-gate.md` | Manager-only posting enforcement |
| `PHASE-7-design-system.md` | Inheriting MGOS tokens |
| `PHASE-8-ops-rollout.md` | Observability, rollback, failure modes |

---

## The architecture in one paragraph

MGOS owns the UI and the permissions. Zernio owns the ad platforms and the social
accounts. **All mutation happens through the AI sidebar**, which calls MCP tools backed
by a server-side Zernio client. The two sidebar pages are deliberately read-only:
`/ads` renders analytics, `/content` renders a calendar. That split is the safety
design — a mis-click in a calendar cannot spend money; a write requires an explicit
tool invocation plus a manager role plus a confirmation step.

```
MGOS sidebar
├── /ads       → analytics view (GET only)
├── /content   → calendar view (GET only)
└── AI         → MCP tools (the ONLY write path)
                    │
                    ▼
             MGOS server (manager-gated)
                    │  ZERNIO_API_KEY
                    ▼
             zernio.com/api/v1
```

---

## Status

Plan only. Nothing built, nothing deployed, no files edited in `mgos` or `nabra-smma`.
