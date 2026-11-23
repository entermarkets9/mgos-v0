# Phase 5 — AI sidebar and MCP tool surface (the only write path)

**Objective:** every mutation in the system — launch campaign, pause, change budget, publish
content, schedule content — happens here and nowhere else. The two sidebar pages are views.

This is the architectural keystone. It is also where Mohammed's instruction lands: *"posting
is done via AI"* and *"maybe u just add zernio MCP/SDK with the twenty AI sidebar."*

---

## 5.1 Why this split is correct (and not just an opinion)

nabra-smma already separates read tools from mutation tools at its AI layer:

```
server/ai/sdk-tools/ads-read-tools.ts        ← reads
server/ai/sdk-tools/ads-launch-tools.ts      ← mutations
server/ai/sdk-tools/campaign-mutation-tools.ts ← mutations
```

That is independent evidence the read/write split is the natural seam in this domain, not
something imposed on it. We are keeping a boundary that already exists.

---

## 5.2 Surface options (D-AI-01)

| Option | How | Pros | Cons |
|---|---|---|---|
| **5A — Twenty built-in AI chat** | Register an MCP server; Twenty's chat discovers tools | Native UX, no new chat UI | Tool schemas must fit Twenty's MCP client; less control over confirmation UX |
| **5B — our own `/ai` route** | Custom page + our own tool loop | Full control over confirm/preview/undo | We build a chat UI, streaming, history |
| **5C — hybrid** | MCP server for discovery, our route for the risky writes | Native feel for reads, hard gate on writes | Two surfaces to audit |

**Recommendation: 5C.** Read tools via Twenty's chat (cheap, native), writes through a
dedicated route we control. The confirmation UX for an irreversible ad spend must be ours.

---

## 5.3 Tool catalogue

Every tool: name, description, input schema, required permission, whether it mutates,
whether it needs confirmation, and its **dry run** behaviour.

### Read tools (safe, no confirmation)

| Tool | Input | Returns |
|---|---|---|
| `zernio_list_ad_accounts` | — | connected ad accounts + status |
| `zernio_list_social_accounts` | — | connected social accounts + scopes + expiry |
| `zernio_campaign_list` | platform?, account?, status?, date range | campaigns |
| `zernio_campaign_insights` | campaign id, date range, breakdown | metrics |
| `zernio_audience_estimate` | platform, targeting spec | estimated **reach**, **impressions**, **CPM** |
| `zernio_content_calendar` | date range, account? | posts + statuses |
| `zernio_asset_list` | — | media library items |

### Mutation tools (permission + confirmation + dry run)

| Tool | Input | Risk |
|---|---|---|
| `zernio_campaign_create` | objective, budget, schedule, targeting, creative refs, **campaign tag**, **listing ref** | **spends money** |
| `zernio_campaign_pause` | campaign id | stops delivery |
| `zernio_campaign_budget_update` | campaign id, new budget | changes spend rate |
| `zernio_content_publish` | account, caption, assets, optional **first comment** | public post |
| `zernio_content_schedule` | account, caption, assets, **publishAt**, timezone | future public post |
| `zernio_content_cancel` | post id | cancels scheduled |
| `zernio_account_connect` | platform | opens **OAuth** flow |

---

## 5.4 The confirmation protocol (non-negotiable)

Every mutation tool returns a **preview** first, not an action:

```
1. AI proposes           → tool called with dry_run=true
2. Preview rendered      → exact destination, budget, dates, creative, audience size
3. Human confirms        → explicit affirmative, not a default-yes
4. Tool executes         → real call, idempotency key attached
5. Result reported       → success / partial success / failure per platform
6. Undo offered          → if reversible (pause, cancel), one-click
```

**Preview must show, at minimum:**
- which **ad account** / **social account** (name + id, not just "your account")
- the **daily budget** and **lifetime budget**, in the account's **currency**
- **flight dates** in the account's **timezone**
- the **audience** summary and estimated **reach**
- the **creative** thumbnail and **headline** / **primary text**
- for content: the exact **caption**, **hashtags**, platform, and time

A confirmation that does not show the destination is not a confirmation.

**Anti-pattern to avoid:** any tool that mutates when `dry_run` is omitted. Default must be
dry-run; execution requires an explicit flag **and** a confirmation token issued by the
preview step, so a model cannot skip the preview by simply omitting a field.

---

## 5.5 Guardrails on the model

| Guardrail | Implementation |
|---|---|
| **Human in the loop** for every mutation | Confirmation token, server-verified |
| **Action preview** mandatory | Server refuses execute without a matching preview id |
| Budget ceiling enforced server-side | Model cannot raise beyond `D-COST-01` cap; server clamps and reports |
| **Spend cap** hard stop | Independent of the model; a database-level check |
| No tool reads raw credentials | Tools never return API keys or tokens |
| **Prompt** injection resistance | Tool results are data; the model must not treat listing text or captions as instructions |
| **RAG** / context | If workspace context is injected, mark it clearly as untrusted content |
| **Guardrail** on output | Refuse to generate creative that trips the policy pre-check |
| Audit | every tool call logged with actor, args, result, timestamp |

---

## 5.6 MCP server shape (if 5A/5C)

```
packages/twenty-server/src/modules/nabra-zernio/mcp/
├── server.ts           MCP transport, auth
├── tools.read.ts       read tools
├── tools.write.ts      mutation tools (guarded)
├── schemas/            per-tool input schemas
└── context.ts          workspace, role, ad-account scope resolution
```

Tool schemas must be **narrow**. A tool that accepts a free-form object is a tool the model
will misuse. Explicit fields, enums for platforms and objectives, required campaign tag.

---

## 5.7 Natural-language capabilities worth supporting

These are the questions a broker will actually ask, and each maps to a read tool:

- "How much did we spend on Meta last week?"
- "Which listing got the most enquiries from ads this month?"
- "What's my cost per lead in Dubai Marina?"
- "Pause the campaign that's over CPA target."
- "Draft a post for the new Al Furjan project, schedule it Thursday 9am."
- "Why did CTR drop on Tuesday?" → **anomaly explanation** from ad-health data.

The last one is where MGOS earns its keep: the AI can join ad metrics to the CRM's own
**property** and **enquiry** data, which no generic ads tool can do.

---

## 5.8 Exit gate

- [ ] Every mutation tool refuses to execute without a valid preview token
- [ ] Budget ceiling enforced server-side and tested with an over-cap request
- [ ] Confirmation preview shows account name, budget, currency, dates, timezone, audience
- [ ] `dry_run` defaults true; omitting the flag never mutates
- [ ] Idempotency key present on every mutating call; duplicate submission is a no-op
- [ ] Tool results never include credentials
- [ ] Prompt-injection test: a caption containing instructions does not alter tool behaviour
- [ ] Audit log captures actor, tool, args hash, result, timestamp
- [ ] Partial success surfaced distinctly from success and failure
