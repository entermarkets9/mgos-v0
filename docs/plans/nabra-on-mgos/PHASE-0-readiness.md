# Phase 0 — Readiness and gates

**Objective:** resolve every blocking decision and establish preconditions before any source
change, credential provisioning, or billable action. Nothing in Phases 1–8 starts until
this phase's exit gate passes.

---

## 0.1 Measured starting state

| Fact | Value | Source |
|---|---|---|
| MGOS repo | `entermarkets9/mgos`, HEAD `b15ddf17` | git |
| Base | `twentyhq/twenty` @ `4bac2940`, SDK `twenty-client-sdk` 2.61.0 | package.json |
| Dev host | sh2 `192.168.100.181`, 12 vCPU, 12 GiB, 154 G free | ssh probe |
| Dev runtime | front :3001, server :3020, Node **26.13.1** (required `^26.5.1`) | running |
| Dev DB | `mgos` on sh2 localhost Postgres, role `mgos` | psql |
| Workspace | `Mgos` / `mgos` / `5e3…`-class uuid, ACTIVE | `core.workspace` |
| Custom UI proof | `/calculator` route renders inside Twenty shell | committed `b5b4832d` |
| Branding | MGOS, monochrome accent `#e8e8e8`/`#363636` | committed `19bdd7a1` |

Nabra-smma reference source: `C:\codespace\nabra-smma` on GTR6. Not modified.

---

## 0.2 Decisions required (owner: Mohammed)

| ID | Decision | Default if unresolved |
|---|---|---|
| **D-SCOPE-01** | Confirm the read-only/read-write split: `/ads` and `/content` are **views only**, all mutation via AI sidebar | BLOCKED — do not build write paths |
| **D-CRED-01** | Zernio **team + API key + webhook secret per environment**. Dev, staging, production must never share one | BLOCKED — no provider calls |
| **D-RBAC-01** | How "manager" is defined in MGOS: Twenty `Role` entity, workspace member role, or a custom flag | BLOCKED — Phase 6 cannot start |
| **D-DATA-01** | Mirror Zernio entities into Twenty `core` schema as custom objects, or fetch live per request | BLOCKED — Phase 2 cannot start |
| **D-AI-01** | Which surface: Twenty's built-in AI chat with an MCP server, or our own `/ai` route calling tools | BLOCKED — Phase 5 cannot start |
| **D-COST-01** | Spend cap per connected ad account, and whether MGOS may ever raise a budget | BLOCKED — no launch capability |
| **D-APPR-01** | Approval model for a launch: inline confirm, four-eyes, or both | BLOCKED — Phase 5 exit |

---

## 0.3 Gates

| Gate | Requirement | Blocks |
|---|---|---|
| **G-1** | `D-SCOPE-01` agreed in writing | everything |
| **G-2** | Dev Zernio team created; `ZERNIO_API_KEY` + `ZERNIO_WEBHOOK_SECRET` (32+ hex bytes, **we** generate it) in Doppler | Phase 1 |
| **G-3** | Public HTTPS URL for the webhook receiver, or an explicit decision to poll instead | Phase 1 webhook path |
| **G-4** | `D-RBAC-01` resolved, and the existing role model inspected before assuming it | Phase 6 |
| **G-5** | `D-DATA-01` resolved | Phase 2 |
| **G-6** | Spend cap value recorded, with an owner | Phase 5 |
| **G-7** | Dry-run/sandbox behaviour defined per platform (Meta, Google, TikTok all differ) | Phase 5 |

**Exit gate:** every gate above PASS or explicitly BLOCKED with a named owner. A BLOCKED
gate is a stop, not an implicit approval.

---

## 0.4 Risks identified before any code

| Risk | Severity | Why it matters |
|---|---|---|
| Real ad spend triggered from a CRM UI | **Critical** | Irreversible external action, real money. D-COST-01 + dry-run + confirm. |
| Zernio exclusive-mode boot failure | High | In nabra-smma, missing key/secret **stops the server booting**. Must not reproduce that in MGOS. |
| Cross-tenant ad account leakage | **Critical** | A broker seeing another broker's ad account is a data breach, not a bug. |
| Webhook replay / duplicate post | High | Idempotency key required; nabra-smma has it, MGOS would be rebuilding it. |
| Rate limit exhaustion | Medium | Zernio: 600/min for 3–2,000 accounts. Client budget in nabra is 500. |
| Token revocation mid-flight | High | A disconnected account must fail loudly, never silently retry forever. |
| Content posted to the wrong account | **Critical** | Wrong audience, wrong creative, wrong platform. Confirmation must show the destination. |

---

## 0.5 What this phase explicitly does not do

- No Zernio API calls.
- No schema migrations.
- No new nav items.
- No changes to `nabra-smma`.
- No credentials created without `D-CRED-01` answered.

---

## 0.6 Deliverables

1. Filled decision table (all 7 IDs resolved or BLOCKED).
2. Gate matrix with PASS/BLOCKED and owner.
3. Recorded spend cap and its owner.
4. Written statement of the read-only vs write split (D-SCOPE-01) — this is the single most
   important artefact, because it defines what users can do without AI.
