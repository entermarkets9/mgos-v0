# Appendix B — Integrations, AI plumbing, data structures

Referenced by Phase 1 (transport), Phase 2 (sync), Phase 5 (AI surface), Phase 8 (ops).

---

## B.1 Sync and transport concepts

| Term | Meaning | Rule |
|---|---|---|
| **incremental sync** | pull only changes since the last **checkpoint** | default mode; cheap on the rate limit |
| **full sync** | re-pull everything | nightly or on demand; catches drift |
| **cursor** | opaque provider token for the next page | never parse it, never persist it across a version change |
| **pagination** | page-by-page traversal | bound the loop; a provider bug must not spin forever |
| **checkpoint** | durable sync position, advanced transactionally | crash mid-sync must resume, not restart |
| **rate limit header** | provider's own remaining-quota signal | read it, adapt, don't guess |
| **API versioning** | explicit platform API version in every path | pin it; never "latest" |
| **deprecation** | a platform sunsetting a version | tracked per platform with a calendar; tested before it breaks us |
| **service token** | credential MGOS uses to call a service on behalf of itself | scoped, rotatable, never a user token |
| **vault** | secret store (Doppler in this estate) | no secrets in env files in the repo, no secrets in the DB |
| **secret rotation** | periodic credential change with a dual-accept window | webhook secrets accept old+new during rotation |
| **outbox** | write-then-emit pattern | prevents lost events between DB write and queue publish |
| **dead letter queue** (**DLQ**) | terminal failures parked for review | with **PII redaction** |

---

## B.2 AI and agent surface

| Term | Meaning in this system |
|---|---|
| **tool calling** / **function calling** | the model invoking a defined server-side function; the only way the AI acts |
| **MCP** | Model Context Protocol — how Twenty's AI discovers our tools |
| **MCP server** | our process exposing the tool catalogue |
| **MCP tool** | one callable function with a narrow schema |
| **SDK** | `twenty-client-sdk` 2.61.0, present in the repo |
| **tool schema** | explicit fields, enums, required properties — never a free-form object |
| **prompt** | user-facing instructions; never a security boundary |
| **system prompt** | fixed instructions; states that capability is server-decided |
| **context window** | finite; long audits must summarise, not stuff |
| **RAG** / **retrieval** | pulling workspace records into context (property, listing, enquiry) |
| **embedding** / **vector store** | semantic search over listings and past campaigns |
| **knowledge base** | the searchable corpus; DataVault-style document queries land here |
| **guardrail** | hard refusal rules that do not depend on the model |
| **natural language query** | "spend in Dubai Marina last month" → read tool |
| **generate creative copy** | draft headline/primary text; must pass the policy pre-check |
| **suggest audience** | propose targeting from the listing's attributes, with an estimate |
| **campaign analysis** | explain utilisation, pacing, deviation — read-only |
| **auto-optimize** | platform-side bidding; we surface that it is on, we do not silently change it |

**The invariant across all of B.2:** the model may *propose*, the server decides. No prompt
text can grant a capability, raise a budget, or skip a confirmation.

---

## B.3 Data structures

| Term | Use here |
|---|---|
| **junction** | many-to-many: campaign ↔ listing, post ↔ asset |
| **optimistic locking** | version column on mutable rows; a concurrent edit fails rather than silently overwrites |
| **event log** | append-only record of launches, publishes, budget changes |
| **materialized view** | pre-computed KPI aggregates for `/ads` |
| **aggregate table** | pre-rolled daily metrics per entity |
| **snapshot** | point-in-time metric row; the unit of history |
| **soft delete** | `deletedAt` on entities that vanish upstream; history is never destroyed |
| **audit trail** | who changed what, when, before/after |
| **index** | on `(entity_type, entity_id, date)` and on external ids |
| **constraint** | unique `(external_id, platform, ad_account_id)` — makes replay safe |
| **transaction** | local writes that must land together (post + slot + outbox row) |

---

## B.4 Real-estate domain joins

The commercial reason MGOS beats a generic ads tool. These joins are why the
campaign-to-listing mapping must exist from day one.

| Join | Enables |
|---|---|
| campaign → **listing** | **listing performance** per campaign |
| creative → **listing** | which creative sells which property |
| campaign → **property listing** type (**off-plan**, **buy**, **rent**) | segment performance by inventory type |
| enquiry → campaign | cost per **lead**, cost per **enquiry** |
| deal → enquiry → campaign | cost per **deal**, true **commission**-adjusted ROAS |
| **developer** → project → campaign | developer-level spend reporting |
| **agent** (broker) → campaign | per-broker spend and results |
| **pipeline** stage → campaign | where ad leads actually convert or stall |
| **creative-to-listing mapping** | the join itself; must be captured at launch |

**Naming note:** `agent` is overloaded in this system — AI agent vs real-estate agent.
In the data model, reserve `agent` for the broker and use `assistant` or `ai_agent` for the
AI. Ambiguity here causes real permission bugs.
