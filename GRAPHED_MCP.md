# The Graphed MCP

Primer for agents that need to use the Graphed MCP to build dashboards.

## What is Graphed?

[Graphed](https://www.graphed.com) is an AI-powered data analytics platform. The three pieces:

1. **Pipeline** — Fivetran-style connectors syncing data from 350+ sources (GA4, Search Console, Google Ads, Stripe, HubSpot, Klaviyo, Shopify, Salesforce, Snowflake, custom DBs, etc.) into a ClickHouse warehouse.
2. **Warehouse** — ClickHouse. Hourly syncs for most sources.
3. **AI agent + visualization** — natural-language interface that builds dashboards, charts, and reports. Plus the MCP described here, which lets *your* agent talk to the warehouse directly.

The MCP is the developer surface. It exposes the warehouse as parameterized SQL queries and lets you publish those queries as public embed URLs.

## Auth

Install via your agent's MCP config. Graphed handles auth via OAuth on first use; subsequent calls are token-based and transparent to the agent.

Run `whoami` once at the start of any session to confirm you're authenticated and see which Graphed account you're operating against.

## Tools

The MCP exposes 7 tools.

### `whoami()`

Returns the authenticated user + account. Use as the first call in any session.

### `embedded_app_docs()`

Returns the canonical documentation for building an embedded web app from Graphed data. **Always call this first** before building a dashboard. It contains the 3-file template (package.json / server.js / index.html) and the exact API contract.

### `explore_schema(schema_name?, table_name?)`

Three modes:

```
explore_schema()                              # list all connected sources
explore_schema("ga4_abc1234")                  # list tables in a schema
explore_schema("ga4_abc1234", "events_report") # list columns in a table
```

Source IDs differ per workspace — `ga4_abc1234` is one customer's GA4, another customer might have `ga4_xyz9a8`. Always start with no-args `explore_schema()` to discover what's actually connected.

Returned schema names follow a pattern: `<source-type>_<short-id>`. Common ones:

| Source | Schema prefix |
| --- | --- |
| Google Analytics 4 | `ga4_` |
| Google Search Console | `search_` |
| Google Ads | `google_ads_` |
| Facebook/Meta Ads | `fb_ads_` |
| LinkedIn Ads | `linkedin_ads_` |
| Stripe | `stripe_` |
| HubSpot | `hubspot_` |
| Amplitude | `amplitude_` |
| PostHog | `posthog_` |
| SendGrid | `sendgrid_` |
| Instantly | `instantly_` |
| Custom CSV | `spreadsheet_` |

### `query(sql, parameters)`

Runs read-only ClickHouse SQL against the warehouse. Returns a `query_id` plus the result rows.

```
query({
  sql: "SELECT date, sum(sessions) FROM ga4_xxx.events_report WHERE date >= %(start_date)s GROUP BY date",
  parameters: { start_date: "2026-02-13", end_date: "2026-05-13" }
})
```

**Parameter binding** uses Python-style `%(name)s` placeholders, NOT `$1` or `?`. The parameters object keys must match the placeholder names.

**Always parameterize date ranges** as `%(start_date)s` / `%(end_date)s` — these become URL query-string overrides on the published embed URL, which is what makes the date picker on the frontend work without re-publishing.

ClickHouse-specific syntax to know:
- `toDate(string)` to cast strings to dates
- `nullIf(x, 0)` for safe division
- `argMax(value, ordering)` for "latest by"
- `LIMIT N BY <dim>` for top-N-per-group in one query
- Alias collision: `sum(impressions) AS impressions, sum(p * impressions)/sum(impressions)` is rejected as "aggregate inside aggregate". Rename the alias: `sum(impressions) AS total_impressions`.

### `publish_query(query_id, title)`

Takes a `query_id` from a previous `query()` call and returns a public URL like:

```
https://api.graphed.com/mcp/queries/<id>/data?token=<token>
```

This URL is the data feed for your dashboard. It's a signed bearer token — anyone with the URL can read the data until you revoke. **Never put it in client-side code**; the standard pattern is an Express proxy holding the URL server-side.

The URL accepts parameter overrides via query string:

```
https://api.graphed.com/mcp/queries/<id>/data?token=<token>&start_date=2026-04-01&end_date=2026-05-01
```

If you don't pass overrides, the query runs with the parameter defaults from when you called `query()`.

### `list_published_queries(cursor?, limit?)`

Paginated list of all your published queries with IDs, titles, and creation dates. Use to audit what's currently public.

### `unpublish_query(query_id)`

Revokes the embed URL immediately. The query itself isn't deleted — you can re-publish later. Use to rotate tokens, kill abandoned queries, or revoke access if a URL leaks.

## The 3-step embed pattern

This is the canonical recipe from `embedded_app_docs()`:

```
1. query()          → SQL + params → returns rows + query_id
2. publish_query()  → query_id    → returns public embed URL (with token)
3. Build a 3-file Express app that proxies the embed URLs (token stays server-side)
```

That's it. No schema design, no ETL, no ORM, no framework, no build step. See the reference implementation in this repo for the exact code shape.

## When NOT to use the MCP

- One-shot Markdown reports — call `query()` once, paste the data, skip publishing
- Bulk extracts to CSV — there's no `download_csv` tool; either use the result rows directly or query the warehouse some other way
- Sources not connected to the workspace — call `explore_schema()` first to confirm what's available

## Limits to be aware of

- **Response size cap (~100KB).** A query that returns daily × 9 sources × 90 days × 6 metric columns will overflow. Pre-filter dimensions in a CTE before grouping.
- **Read-only.** Only SELECT. No INSERT / UPDATE / DELETE / CREATE.
- **Embed URLs don't rotate automatically.** Treat them like API keys — revoke and re-issue on a schedule if you want.

## Discovery tips

- Many GA4 properties don't have Age / Gender enabled. Don't assume `demographic_age_report` exists — call `explore_schema("ga4_xxx")` to confirm. (Device / Browser / OS are usually always there.)
- `keyword_stats` in Google Ads is the keywords you *bid* on. `search_term_keyword_stats` is what users *typed* — far richer for save-money / paid-vs-organic joins.
- Search Console has `keyword_site_report_by_site` (query level) and `keyword_page_report` (query × page). Use the right one for the dimension you need.
- `(not set)` is a common GA4 sentinel for missing dimension values. Filter it out in WHERE clauses or you'll get a giant ugly row on top of every donut.
