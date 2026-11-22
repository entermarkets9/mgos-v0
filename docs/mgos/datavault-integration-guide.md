# DataVault integration guide

## Connect another project safely

Prepared 9 October 2026. Based on Nabra's current integration and a read-only inspection of DataVault's live column definitions. No credentials or customer records are included.

**Recommended approach:** connect your new project's backend directly to DataVault using its own read-only PostgreSQL account. Keep your new project's application database separate. Do not replace its `DATABASE_URL` with DataVault's credentials.

This guide uses Node.js and `pg` because that is Nabra's implementation. The same database settings work with another backend language and its PostgreSQL driver.

## 1. What DataVault actually is

In this project, "DataVault" means a separate external PostgreSQL database. It is not Replit's application database, a Telegram integration, or an automatically available REST service.

```text
Your browser or mobile app
    → your authenticated backend
        → dedicated DataVault connection pool
            → external PostgreSQL database

Your backend
    → your normal application database
        → users, permissions, audit logs, saved searches, CRM records
```

Nabra reads three tables: `public.properties`, `public.people`, and `public.organizations`. Most property-owner lookups read owner fields directly from `properties`; they do not require copying DataVault records into the application database.

Choose between two approaches:

| Approach | When to choose it | Requirements |
| --- | --- | --- |
| Direct PostgreSQL connection — recommended | Another trusted backend needs property or contact lookup | Dedicated read-only credentials, network access, TLS, application authorization |
| A purpose-built DataVault API | Many projects need one centrally governed integration, or direct database access is undesirable | Build and operate an authenticated service with project-scoped access, rate limits, audit logs and explicit response contracts |

Nabra's `/api/data-vault/*` routes use Nabra's own login session and `access_data_vault` permission. They are not an existing public API-key integration. Do not share an administrator's session cookie between projects or use admin login credentials as machine credentials.

## 2. Obtain access before coding

Ask the DataVault administrator for:

1. The PostgreSQL hostname, port and database name.
2. A **separate read-only login for this project**, preferably different logins for development and production.
3. Access to the specific tables or restricted views your project needs.
4. Any IP allowlisting, VPN or private-network requirements.
5. The TLS requirements and certificate authority bundle, if a private CA is used.
6. Permission to process the required property/contact data, permitted uses, retention policy and export limits.

Use the existing database, not a new empty database. A new project does not inherit another project's secrets or network permissions.

The DataVault administrator should enforce least privilege at the database level: connection access, schema usage and SELECT access only. Do not grant INSERT, UPDATE, DELETE, schema creation, ownership or superuser privileges. Request access to `people` and `organizations` only if those features are required.

Read-only transaction settings add protection, but do not replace actual read-only database permissions.

## 3. Configure server-side secrets

Use these names to stay compatible with Nabra:

| Setting | Meaning | Important detail |
| --- | --- | --- |
| `DATA_VAULT_URL` | Database hostname | Despite the name, Nabra passes this as `pg.Pool.host`, not as a full connection URI |
| `DATA_VAULT_DB` | Database name | Not a schema name or table name |
| `DATA_VAULT_USER` | Database login | Prefer a dedicated read-only role |
| `DATA_VAULT_PASS` | Database password | Store securely; never in chat, source code or browser settings |
| `DATA_VAULT_PORT` | Optional port for the example below | Defaults to 5432; Nabra does not currently set a dedicated port explicitly |
| `DATA_VAULT_CA_CERT` | Optional trusted CA PEM for the example below | Needed when the provider uses a CA not trusted by the runtime |

The last two are additions supported by the recommended example, not existing requirements in Nabra's module.

Keep all settings on the backend. Never use `VITE_*`, `NEXT_PUBLIC_*`, frontend configuration objects, downloadable files or public repositories for database credentials. Do not print the settings during troubleshooting.

If the administrator gives you a URI such as `postgresql://...`, use your driver's `connectionString` option **instead of** placing the whole URI in `DATA_VAULT_URL`. Do not mix the two configuration styles unintentionally.

### If the other project is on Replit

Add its credentials through that project's Secrets tool. Verify the credentials are configured for the published runtime too; development configuration alone is not proof that production can connect. Publish or restart the relevant run target after saving secrets so the deployed process picks them up; a process started before the secret existed will not see it until it restarts.

## 4. Connection pool example (Node.js)

Create a dedicated pool. Do not reuse the pool for your application database, and do not run application writes through this pool.

```js
import pg from "pg";

const { Pool } = pg;

const useCa = Boolean(process.env.DATA_VAULT_CA_CERT);

const pool = new Pool({
  host: process.env.DATA_VAULT_URL,   // hostname only, not a URI
  port: Number(process.env.DATA_VAULT_PORT || 5432),
  database: process.env.DATA_VAULT_DB,
  user: process.env.DATA_VAULT_USER,
  password: process.env.DATA_VAULT_PASS,
  ssl: useCa
    ? { ca: process.env.DATA_VAULT_CA_CERT, rejectUnauthorized: true }
    : { rejectUnauthorized: true },
  max: 4,                 // keep small; this is a lookup pool
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
  // Belt-and-suspenders: even a misconfigured role cannot write here.
  statement_timeout: 15_000,
});

// Optional: wrap every query so the session is read-only.
async function dataVaultQuery(text, params) {
  const client = await pool.connect();
  try {
    await client.query("SET TRANSACTION READ ONLY");
    const result = await client.query(text, params);
    return result.rows;
  } finally {
    client.release();
  }
}

export { pool as dataVaultPool, dataVaultQuery };
```

If you were given a full URI instead of discrete settings, replace the individual fields with `connectionString: process.env.DATA_VAULT_URL` and keep the `ssl` block if the URI does not already encode TLS parameters.

## 5. Safe query patterns

Select only the columns you need. Never `SELECT *` against live tables in production code paths.

```js
// Property lookup by reference — owner fields come from the same row.
const rows = await dataVaultQuery(
  `SELECT
     id, reference_number, title, property_type, status,
     price, bedrooms, bathrooms, area_sqft,
     owner_name, owner_phone, owner_email,
     city, community, created_at, updated_at
   FROM public.properties
   WHERE reference_number = $1
   LIMIT 1`,
  [referenceNumber]
);
```

Add a `WHERE` clause that matches your authorization context (for example, restrict to properties your application's user is allowed to see). DataVault's database permissions are project-level; row-level filtering is your application's responsibility.

Cache lookups in your own application database or cache layer if the same property is read repeatedly within a short window. Do not copy full DataVault tables into your application database unless you have an explicit retention and sync plan; most integrations do not need to.

## 6. Errors, timeouts and degradation

- Treat connection failures and timeouts as "lookup unavailable", not "property does not exist". Return a clear degraded state to your users rather than an empty result that looks authoritative.
- Bound retries: one immediate retry on a fresh connection, then surface the failure. Do not retry in a tight loop against an external database.
- Log the error type and query fingerprint, never the credentials or full row payloads.
- If your feature can function with stale cached data, define a maximum cache age and show the data's age where it matters (for example, price or availability).

## 7. Checklist before you ship

- [ ] Dedicated read-only login obtained for this project (separate from Nabra's and from any other project).
- [ ] Development and production use different logins, both configured in the deployment environment's secrets.
- [ ] Connection pool is separate from the application database pool; no writes go through it.
- [ ] TLS is enabled; `rejectUnauthorized` is true; custom CA provided if required.
- [ ] Queries select explicit columns and include an application-level authorization filter.
- [ ] Secrets are absent from frontend bundles, logs, screenshots and source control.
- [ ] Degraded-mode behaviour (timeout, connection refused, auth failure) is tested and user-visible where it matters.
- [ ] Retention and permitted-use terms from step 2 of §2 are reflected in what you store and for how long.

## 8. Relationship to the MGOS deployment plan

In `docs/mgos-deployment-plan.md`, the MGOS worker's DataVault connector (Phase 4, Task 4.2) pulls property inventory into MGOS custom objects keyed by an environment-qualified `externalId`. This guide describes the **connection layer** that connector sits on: the same dedicated read-only pool, the same secret names, the same TLS and least-privilege rules. The connector adds cursor/checkpoint transactionality, pagination, tombstone handling and idempotent upserts on top of the raw queries shown here — see the inventory connector contract in the plan's §0 and Phase 4 sessions for those requirements.

Do not point the MGOS connector at Nabra's session-based `/api/data-vault/*` routes. Those authenticate a human user, not a machine integration. The connector uses its own database credentials as described in this guide.
