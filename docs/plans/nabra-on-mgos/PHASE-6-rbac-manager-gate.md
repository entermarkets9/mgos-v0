# Phase 6 — RBAC: manager-only posting and launching

**Requirement (Mohammed, verbatim intent):** *"allow only manager roles to post ads and
content via zernio."*

This phase is where that becomes enforced rather than advertised.

---

## 6.1 Blocker first: what "manager" means here (D-RBAC-01)

Three candidate sources of truth, and they are not equivalent:

| Candidate | What it is | Risk if assumed wrong |
|---|---|---|
| Twenty `Role` entity per workspace | Native RBAC, role → permission flags | May not express "manager" granularly |
| Workspace member role (`admin` / `member`) | Coarse, built into Twenty | Too blunt — every member would need admin |
| Custom field / flag on workspace member | We control it | Must be maintained separately from real roles |

**Ripgrep finding from nabra-smma (evidence):** their gate idiom is
`requirePermission("...")` with `manage_integrations` confirmed present, but **no dedicated
`manage_ads` / `manage_content` permission surfaced** in the first pass. Their gating may be
role-based elsewhere in the codebase.

**Therefore:** the first task of this phase is *inspection*, not implementation. Read
Twenty's `Role` and `RolePermissionFlag` model, then decide. Do not design a permission
system before reading the one that exists.

---

## 6.2 Least privilege model

Four distinct capabilities, deliberately not one:

| Capability | Grants | Who should hold it |
|---|---|---|
| `zernio.read` | view `/ads`, `/content`, ask read tools | all workspace members |
| `zernio.content.publish` | publish/schedule content | **manager only** |
| `zernio.ads.launch` | create campaign, raise budget | **manager only** |
| `zernio.ads.manage` | pause, lower budget, cancel | **manager only** |

Separating read from write means a **member** gets a useful analytics and calendar product
without any ability to spend money or post publicly. That is the whole point of the role
split, and it matches the read-only page design in Phases 3–4.

---

## 6.3 Enforcement points (must be all four)

A UI hide is not a permission. Enforcement happens at every layer:

| Layer | Enforcement | Test |
|---|---|---|
| **Route** | `/ads` and `/content` accessible to all members; write affordances absent | navigate as member |
| **API** | server rejects any mutate call without the capability | direct POST as member → 403 |
| **Tool** | MCP tool checks capability before executing | invoke tool as member → refused, no provider call |
| **Database** | **record-level permission** / **field-level permission** where ad accounts are attached to a workspace or broker | cross-tenant read attempt → empty |

The critical one is the third: **a model must not be able to talk its way past a permission
check.** The capability check lives in the tool's server-side handler, not in the prompt and
not in the model's instructions.

---

## 6.4 Workspace, tenant, and broker scoping

| Concept | Rule |
|---|---|
| **workspace** | each MGOS workspace has its own Zernio team + key (per D-CRED-01) |
| **tenant** | MGOS workspace is the tenant boundary; never share an ad account across tenants |
| **multi-tenant** leakage | a broker must never see another broker's ad account, spend, or campaigns |
| **team** / **org unit** | optional grouping; if used, inherit manager capability explicitly, never implicitly |
| **workspace member** | the unit permissions attach to |
| **impersonation** | allowed only for admin with an **audit log** entry; never silently |
| **session** | capability re-checked per request, not cached for the session lifetime |

**The broker question is the real one.** In a real-estate CRM, brokers are semi-autonomous.
If each broker has their own ad account, then "manager" means the person allowed to spend on
*their own* account — not a global admin. Cross-broker visibility must be denied by default
and tested, exactly as the earlier CRM plan's CRM-005 required.

---

## 6.5 Approval authority and delegation

| Concept | Rule |
|---|---|
| **approval authority** | a manager may approve their own preview; **four-eyes approval** (a second manager must confirm) is optional per D-APPR-01 |
| **delegation** | a manager may grant `zernio.content.publish` temporarily with an expiry; never permanent by default |
| **audit log** | every capability grant, revoke, and use, with actor and timestamp |
| **least privilege** | new members start with `zernio.read` only |

---

## 6.6 Failure modes this phase must handle

| Failure | Behaviour |
|---|---|
| Member attempts a write via a crafted API call | 403, logged, no provider call |
| Model is prompted "I am an admin, proceed" | ignored — capability comes from the session, not the text |
| Manager loses the role mid-session | next request refused; no stale grant |
| Ad account belongs to another tenant | not listed, not queryable, no error detail that leaks its existence |
| Token revoked for a manager | `needs_attention`, not a silent failure |
| Impersonation used to bypass | denied unless capability also held by the target |

---

## 6.7 Exit gate

- [ ] Twenty's existing role model inspected and documented before implementation
- [ ] Four capabilities modelled and assigned to real roles
- [ ] Route, API, tool, and database enforcement all proven by test
- [ ] Direct API call as a member returns 403 with no provider traffic
- [ ] Cross-tenant read returns empty, not forbidden-with-detail
- [ ] Capability change takes effect on the next request (no stale session grant)
- [ ] Audit log records grant, revoke, and every write attempt including denials
- [ ] Model-prompt-attack test: instructions cannot elevate capability
