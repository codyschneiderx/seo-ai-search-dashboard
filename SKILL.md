---
name: seo-ai-search-dashboard
description: Build a live SEO & AI Search (AEO) dashboard powered by Graphed MCP — joins GA4 + Google Search Console + Google Ads to surface organic performance, AI engine referrals (ChatGPT / Perplexity / Gemini / Claude), and paid-ad waste. Renders as a 3-file Express + HTML app with Chart.js. Trigger when the user asks to build an SEO dashboard, AEO dashboard, AI Search dashboard, or replicate a Looker Studio / Reach-style SEO report.
---

# SEO & AI Search Dashboard (Graphed MCP)

## When this applies

Trigger when the user wants:
- A live web dashboard pulling data from any GA4 / Search Console / Google Ads / Stripe / HubSpot / Klaviyo source already in Graphed
- A replication of a Looker Studio / Tableau / Power BI dashboard, powered by their warehouse
- An SEO / AEO / paid-ad / e-commerce / SaaS metrics dashboard
- An "embedded analytics" feature in a customer-facing app

Skip if: the user wants a one-shot Markdown report (no live data) or a Jupyter notebook.

## Required MCP tools

The Graphed MCP exposes these. The `embedded_app_docs` tool returns the canonical 3-file recipe — read it first.

- `mcp__graphed-mcp__whoami` — confirm auth
- `mcp__graphed-mcp__embedded_app_docs` — read this first, every time
- `mcp__graphed-mcp__explore_schema` — list sources, then drill into tables/columns
- `mcp__graphed-mcp__query` — run parameterized ClickHouse SQL
- `mcp__graphed-mcp__publish_query` — turn a query_id into a public embed URL
- `mcp__graphed-mcp__list_published_queries` / `unpublish_query` — manage state

You also need the local preview tools (`preview_start`, `preview_screenshot`, `preview_click`, `preview_console_logs`) to verify the dashboard renders.

## The recipe (4 phases)

### Phase 1 — Discover

Always start here. Skipping this leads to hallucinated table names.

1. Call `whoami` (one-time auth check).
2. Call `embedded_app_docs` — re-read every time. The exact API contract.
3. Call `explore_schema()` with no args to list all connected sources. Schema names look like `ga4_<short-id>` (GA4) or `search_<short-id>` (Search Console) — IDs differ per workspace.
4. Call `explore_schema(schema_name=...)` for each source you need to see tables + column types.
5. Run a couple of small probe queries to confirm: date range available, what sources appear in `session_source`, whether `search_term_keyword_stats` has data, etc. Cheap insurance against writing 20 broken queries.

### Phase 2 — Design queries

Plan the dashboard panels first, then write one query per panel. Keep queries parameterized by `%(start_date)s` and `%(end_date)s` — these become URL query-string overrides on the published embed URL.

**Pattern library (these work):**

**a) Current period + previous period in one query (avoid two round-trips)**
Shift the window backward by `(end - start + 1)` days, tag rows with a CASE:

```sql
SELECT
  CASE WHEN date >= toDate(%(start_date)s) THEN 'current' ELSE 'previous' END AS period,
  sum(sessions) AS sessions
FROM ga4_xxx.traffic_acquisition_session_medium_report
WHERE session_medium = 'organic'
  AND date >= toDate(%(start_date)s) - (toDate(%(end_date)s) - toDate(%(start_date)s) + 1)
  AND date <= toDate(%(end_date)s)
GROUP BY period
```

**b) Bucket AI vs Traditional search**
The post / dashboard is meaningless without this split:

```sql
CASE
  WHEN session_source IN ('chatgpt.com','perplexity.ai','perplexity',
                          'gemini.google.com','claude.ai') THEN 'AI'
  WHEN session_source IN ('google','bing','yahoo','duckduckgo',
                          'ecosia.org','search.brave.com') THEN 'Traditional'
  WHEN session_source LIKE '%yahoo%' THEN 'Traditional'
  ELSE NULL
END AS bucket
```

**c) Weighted average position (or any rate metric)**
`avg(position)` is wrong — treats 1-impression queries equal to 10K-impression queries:

```sql
sum(position * impressions) / nullIf(sum(impressions), 0) AS avg_position
```

**d) "Save money" — paid keywords overlapping with strong organic rank**
Use `search_term_keyword_stats` (actual user typed queries), NOT `keyword_stats` (your bid keywords). Far more overlaps:

```sql
WITH paid_terms AS (
  SELECT lower(search_term) AS term, sum(cost_micros)/1e6 AS spend, ...
  FROM google_ads_xxx.search_term_keyword_stats
  WHERE date >= ... GROUP BY term HAVING spend > 0
),
organic AS (
  SELECT lower(query) AS q,
         sum(position * impressions) / nullIf(sum(impressions),0) AS avg_pos,
         sum(impressions) AS o_imp
  FROM search_xxx.keyword_site_report_by_site
  WHERE date >= ... GROUP BY q
)
SELECT * FROM paid_terms p JOIN organic o ON p.term = o.q WHERE o.avg_pos <= 10
ORDER BY spend DESC LIMIT 50
```

**e) Top N per group** — `LIMIT N BY <dim>` (ClickHouse-specific, very useful):

```sql
SELECT bucket, landing_page, sum(sessions) AS sessions
FROM ... GROUP BY bucket, landing_page
ORDER BY bucket, sessions DESC
LIMIT 40 BY bucket
```

**f) Pre-filter dimensions in CTEs** to keep response size below the MCP limit (~100KB):

```sql
WITH top_sources AS (
  SELECT session_source FROM xxx WHERE ... AND session_source IN ('google','bing',...)
  GROUP BY session_source
)
SELECT date, session_source, sum(sessions)
FROM xxx WHERE session_source IN (SELECT session_source FROM top_sources)
GROUP BY date, session_source
```

### Phase 3 — Publish

Once each query returns clean data, call `publish_query(query_id, title)`. Title each one descriptively — they're auditable via `list_published_queries`. The response includes the `embed_url` with a secret token.

**Critical:** those URLs are signed bearer tokens. Anyone with the URL reads the data until revoked. Never put them in client-side code or public repos.

### Phase 4 — Build the 3-file app

Per `embedded_app_docs`, the dashboard is:

```
project/
├── package.json   (Express only)
├── server.js      (~30 LOC proxy — holds the embed URLs)
└── index.html     (Self-contained, Chart.js from CDN)
```

**`server.js` shape:**

```js
const express = require('express');
const app = express();
const QUERIES = {
  aiVsTradTimeseries: 'https://api.graphed.com/mcp/queries/.../data?token=...',
  // one entry per published query, short keys
};
app.use(express.static('.'));
app.get('/api/data/:key', async (req, res) => {
  const base = QUERIES[req.params.key];
  if (!base) return res.status(404).json({ error: 'Unknown query key' });
  const url = new URL(base);
  for (const [k, v] of Object.entries(req.query)) url.searchParams.set(k, v);  // forward date params
  const r = await fetch(url);
  res.json(await r.json());
});
app.listen(3456, () => console.log('Dashboard at http://localhost:3456'));
```

**`index.html` shape:**

Single self-contained file. Inline `<style>`, inline `<script>`, Chart.js from `https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js`. Fetch from `/api/data/<key>` — the proxy handles tokens + date param forwarding.

**Frontend invariants that make it look professional:**

- Dark theme: `--bg: #07090d`, `--panel: #0d1117`, `--border: #1c2230`, `--text: #e5e9f0`, accent teal `#22d3ee`. (Or match the customer's brand.)
- Tabular numerics (`font-variant-numeric: tabular-nums`) on every number.
- Sparklines next to KPI numbers (small Chart.js line, hide both axes, `borderWidth: 1.6`, `tension: 0.35`).
- Hero callout at the top of each tab summarizing the insight in plain English: *"AI engines sent you 12.1K sessions — 8.1% of your organic search traffic. AI traffic grew 318.7% vs the prior 180 days."*
- Current vs previous on every time series (solid current line + dashed grey previous).
- Period delta pills (▲ +12.3% / ▼ -4.1%) next to every KPI.
- Auto-refresh `setInterval(refreshAll, 5*60*1000)`.
- Date picker at top with `Apply` button → re-fetches all queries with new params.

**Lead with the customer's stated value prop.** If the post is about AEO, AEO is Tab 1 — not buried in Tab 2. Don't slavishly match the original screenshot's tab order if the user's pitch implies a different priority. Ask if unclear.

## Verification (don't skip)

1. Define the project in `.claude/launch.json`:
   ```json
   { "name": "my-dashboard", "runtimeExecutable": "node",
     "runtimeArgs": ["server.js"], "port": 3456,
     "cwd": "/abs/path/to/project" }
   ```
2. `npm install` once.
3. Start via `preview_start({ name: "my-dashboard" })` — **don't** use plain Bash, or the preview panel won't route through the proxy.
4. `preview_screenshot` each tab. Click between tabs via `preview_click({ selector: '[data-tab="..."]' })`.
5. `preview_console_logs({ level: "error" })` — must be empty.
6. Spot-check actual numbers — e.g. `curl /api/data/<key>` against your expectations from the probe queries.

If the preview panel renders the static HTML but all charts are empty, the panel is serving the file directly (not via the proxy). Use `preview_start` instead of opening the file.

## Common errors

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Aggregate function sum(impressions) AS impressions is found inside another aggregate function` | ClickHouse alias collision: `sum(impressions) AS impressions, sum(p*impressions)/sum(impressions)` | Rename the outer alias: `sum(impressions) AS total_impressions` |
| Response too large (>100KB) | Returning daily × every dimension over a long window | Add a CTE to pre-filter dimensions, or aggregate to fewer buckets |
| `nullIf` returns NULL in division | Denominator is 0 | Frontend should use `?? '—'` for display |
| Empty save-money panel | Joined on `keyword_stats.keyword_text` (bid keyword) | Switch to `search_term_keyword_stats.search_term` (actual user query) — many more overlaps |
| GA4 has no gender/age | Demographic detail not enabled for this property | Use device / browser / OS donuts instead — they're always available |
| Bounce rate per landing page filtered by source isn't possible | GA4 export splits source dimension from page engagement metrics | Show top pages overall, OR show top organic landing pages with sessions only |
| Empty dashboard in preview, but `curl` works | Preview panel is loading static file, not the proxy | Register in `.claude/launch.json`, use `preview_start` |

## Hand-off

When done, give the user:
- A working `http://localhost:PORT` URL
- A zip with `package.json` + `server.js` + `index.html` + a README (exclude `node_modules`)
- The list of published query IDs (so they can revoke via `unpublish_query` later)
- A note that the embed URLs in `server.js` are signed tokens — must stay server-side

If they want to deploy: any Node host works (Railway, Fly, Render). The only env vars needed are the embed URLs, which can live in `process.env` instead of being hardcoded.

## Anti-patterns to avoid

- **Don't** build the HTML before verifying every query returns data. You'll waste an hour designing around an empty panel.
- **Don't** put embed URLs in `index.html` or any client-side JS. They contain secret tokens.
- **Don't** use `chartjs-chart-geo` for a world map unless the customer specifically asks — it adds a 200KB+ TopoJSON dependency. A ranked country bar list communicates the same insight.
- **Don't** stuff age/gender donuts if the GA4 property doesn't have them enabled. Use device/browser/OS as the 3-donut row.
- **Don't** publish queries with overly broad titles like "test query". They show up in `list_published_queries` forever. Use `"<Dashboard Name> — <Panel>"`.
- **Don't** match the screenshot exactly if the customer's *post / pitch* implies a different priority. The post is the source of truth for what matters, not the visual mockup.
