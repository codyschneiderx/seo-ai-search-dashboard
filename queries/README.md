# Queries

16 ClickHouse SQL queries that power the dashboard. Each is parameterized by `%(start_date)s` and `%(end_date)s`.

Schema names are templated as `{{GA4_SCHEMA}}`, `{{GSC_SCHEMA}}`, `{{ADS_SCHEMA}}`. Replace these with the actual schema names from your Graphed workspace (run `explore_schema()` via the MCP to find them — they look like `ga4_abc1234`).

## Mapping: file → panel → JS key

The "JS key" is the short name used in [`reference-implementation/server.js`](../reference-implementation/server.js)'s `QUERIES` map and the frontend's `/api/data/<key>` calls.

| File | Powers | Tab | JS key |
| --- | --- | --- | --- |
| `01-organic-kpis.sql` | 4 KPI cards (sessions / engaged / key events / users) with current-vs-previous deltas | Organic | `organicKpis` |
| `02-organic-timeseries.sql` | Sessions and Key Events line charts (current + dashed previous) | Organic | `organicTimeseries` |
| `03-country-sessions.sql` | Sessions by Country (top 20 bar list) | Organic | `countrySessions` |
| `04-device-breakdown.sql` | Device donut | Organic | `deviceBreakdown` |
| `05-browser-breakdown.sql` | Browser donut | Organic | `browserBreakdown` |
| `06-os-breakdown.sql` | Operating System donut | Organic | `osBreakdown` |
| `07-day-of-week-organic.sql` | Day of Week bar chart | Organic | `dayOfWeekOrganic` |
| `08-page-engagement.sql` | Most Visited Pages table (sessions / engaged / users / bounce rate) | Organic | `pageEngagement` |
| `09-ai-vs-traditional-timeseries.sql` | Hero callout + all 4 AEO KPI cards w/ sparklines + AI vs Traditional stacked area | AEO | `aiVsTradTimeseries` |
| `10-sources-breakdown.sql` | AI Engine Mix donut + horizontal mix bars | AEO | `sourcesBreakdown` |
| `11-sources-timeseries.sql` | Sources Sessions Breakdown Evolution (multi-line) | AEO | `sourcesTimeseries` |
| `12-top-ai-pages.sql` | Top AI-Cited Pages table | AEO | `topAiPages` |
| `13-gsc-totals.sql` | Impressions / Clicks / Keywords / CTR KPI strip | AEO | `gscTotals` |
| `14-avg-position-timeseries.sql` | Avg Position Evolution + GSC sparklines | AEO + Budget | `avgPositionTimeseries` |
| `15-invest-in-ads.sql` | "Where You Should Invest" table | Budget | `investInAds` |
| `16-save-money-search-terms.sql` | "Where You're Wasting Ad Budget" hero + table | Budget | `searchTermSaveMoney` |

## Agent workflow

```python
# pseudocode
schemas = explore_schema()                                # discover GA4/GSC/Ads schema IDs
ga4_id  = pick(schemas, prefix="ga4_")
gsc_id  = pick(schemas, prefix="search_")
ads_id  = pick(schemas, prefix="google_ads_")

embed_urls = {}
for sql_file in sorted(queries_dir):
    sql = read(sql_file).replace("{{GA4_SCHEMA}}", ga4_id) \
                        .replace("{{GSC_SCHEMA}}", gsc_id) \
                        .replace("{{ADS_SCHEMA}}", ads_id)
    result = mcp.query(sql, parameters={"start_date": "...", "end_date": "..."})
    pub    = mcp.publish_query(result.query_id, title=f"SEO Dashboard — {sql_file.stem}")
    embed_urls[js_key(sql_file)] = pub.embed_url

# Then write embed_urls into reference-implementation/server.js QUERIES map
```

## Patterns demonstrated

- **Current vs previous period in one query** (`01`, `02`, `09`) — shift the WHERE window back by `(end - start + 1)` days and tag rows with a `CASE`.
- **AI vs Traditional bucketing** (`09`, `10`) — `CASE WHEN session_source IN (...)` classifies search sources. Add a new AI engine by editing one line.
- **Weighted average position** (`14`, `15`, `16`) — `sum(position * impressions) / nullIf(sum(impressions), 0)`.
- **CTE pre-filtering** (`11`, `16`) — restrict the dimensional space before grouping, to keep results under the response size limit.
- **Search term × organic query join** (`16`) — the "save money" insight. Uses `search_term_keyword_stats` (what users typed), not `keyword_stats` (what you bid).
- **Aggregate alias renames** (`14`, `15`) — `sum(impressions) AS total_impressions` (not `AS impressions`) because ClickHouse rejects aggregate-inside-aggregate alias collisions.
