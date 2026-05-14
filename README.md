# SEO & AI Search Dashboard (Graphed MCP template)

A live SEO + AEO (AI Search) dashboard, powered by the [Graphed MCP](https://www.graphed.com). Built to be handed to a coding agent (Claude Code, Cursor, Cline, etc.) that will wire it up to **your own** Graphed workspace.

## What you get

Three tabs, sixteen panels:

**Tab 1 — AI Search Performance (AEO)**
- Hero callout: *"AI engines sent you X sessions — Y% of your organic search traffic"*
- 4 KPI cards w/ sparklines: AI Sessions, AI Share of Organic, AI Engagement Rate, Traditional Sessions
- AI vs Traditional sessions over time (stacked area)
- AI Engine Mix (donut + horizontal bars for ChatGPT, Perplexity, Gemini, Claude)
- Sources Sessions Breakdown Evolution (multi-line)
- Top AI-Cited Pages (which landing pages AI engines actually link to)
- GSC strip: Impressions, Clicks, Ranking Keywords, Avg CTR

**Tab 2 — Where You're Wasting Ad Budget**
- Hero callout w/ total ad spend and overlapping-organic spend
- Save Money table: paid search terms where you already rank top 10 organically
- Invest in Ads table: high-impression queries ranking 10–30 (page 2+ opportunities)
- Average Position Evolution

**Tab 3 — Organic Overview**
- 4 organic KPIs w/ current-vs-previous deltas
- Sessions and Key Events time series (current + dashed previous)
- Sessions by Country (top 20)
- Device / Browser / Operating System donuts
- Sessions by Day of Week
- Most Visited Pages table (Sessions, Engaged, Users, Bounce rate)

## How an agent should use this repo

This repo is a **template**, not a deployable app. Each Graphed workspace has different schema IDs (e.g. `ga4_abc1234` for one customer, `ga4_xyz9876` for another), and embed URLs are signed per-workspace, so the agent must re-run the queries against the target workspace.

Hand the repo to your agent and say:

> *"Build the SEO & AI Search dashboard from this repo, pointed at my Graphed workspace."*

The agent should:

1. Read [`SKILL.md`](./SKILL.md) and [`GRAPHED_MCP.md`](./GRAPHED_MCP.md)
2. Confirm Graphed MCP is connected (call `whoami`)
3. Confirm GA4 + Google Search Console + Google Ads are connected to your workspace (call `explore_schema()` to see source IDs)
4. For each file in [`queries/`](./queries), replace the `{{GA4_SCHEMA}}` / `{{GSC_SCHEMA}}` / `{{ADS_SCHEMA}}` placeholders with your actual schema names, then call `query()` + `publish_query()` to get an embed URL
5. Copy [`reference-implementation/`](./reference-implementation) to a new directory, fill in the `QUERIES` map in `server.js` with the generated embed URLs
6. `npm install && npm start` → open `http://localhost:3456`

If you don't have Graphed yet: sign up at [graphed.com](https://www.graphed.com), connect GA4 + Google Search Console + Google Ads (15-minute OAuth flow each), wait for the initial sync, then point your agent at this repo.

## What's in each folder

| Path | What it is |
| --- | --- |
| [`SKILL.md`](./SKILL.md) | The playbook — drop into `~/.claude/skills/seo-ai-search-dashboard/SKILL.md` and Claude Code will auto-trigger on relevant prompts |
| [`GRAPHED_MCP.md`](./GRAPHED_MCP.md) | Primer on what the Graphed MCP is and the tools it exposes |
| [`queries/`](./queries) | All 16 ClickHouse SQL queries, one per file, parameterized by `%(start_date)s` and `%(end_date)s`. Schema names are templated as `{{GA4_SCHEMA}}` etc. |
| [`reference-implementation/`](./reference-implementation) | The working `package.json` / `server.js` / `index.html` with placeholder embed URLs the agent fills in |
| `screenshots/` | Visual targets for what the rendered dashboard should look like |

## Patterns this template demonstrates

- Parameterized SQL queries via Graphed's `query()` MCP tool
- Token-scoped public embed URLs via `publish_query()`
- 3-file Express + HTML app pattern (no build step, no framework)
- Current-vs-previous period comparison in a single query
- AI engine bucketing (ChatGPT / Perplexity / Gemini / Claude vs Google / Bing / etc.)
- Paid-vs-organic keyword join via `search_term_keyword_stats`
- Weighted average position
- Chart.js sparklines inside KPI cards

## License

MIT — fork it, customize it, sell it. If you want to credit, link [graphed.com](https://www.graphed.com).
