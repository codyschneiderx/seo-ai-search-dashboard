# Reference Implementation

The working 3-file Express + HTML app. **Does not run as-is** — `server.js` has placeholder embed URLs that need to be filled in with URLs scoped to your own Graphed workspace.

## Wire it up

### Option A: let an agent do it

Hand the parent repo to a coding agent and say:

> *Build the SEO & AI Search dashboard from this repo, pointed at my Graphed workspace.*

The agent reads `../SKILL.md` and `../GRAPHED_MCP.md`, then:
1. Runs each SQL file in `../queries/` against your workspace (replacing schema placeholders)
2. Publishes each query to get embed URLs
3. Fills in the `QUERIES` map in `server.js`

### Option B: do it yourself

1. Install the [Graphed MCP](https://www.graphed.com) in your Claude Code / Cursor / Cline config and authenticate.
2. Connect GA4 + Google Search Console + Google Ads to your Graphed workspace.
3. Discover your schema IDs: ask your agent to call `explore_schema()`. You'll get back a list like:
   ```
   Available schemas:
   - graphed.com (schema: ga4_abc1234)
   - https://www.graphed.com/ (schema: search_xyz5678)
   - Google Ads (schema: google_ads_def9012)
   ```
4. For each `.sql` file in `../queries/`:
   - Open it, replace `{{GA4_SCHEMA}}`, `{{GSC_SCHEMA}}`, `{{ADS_SCHEMA}}` with your actual IDs.
   - Run it via the MCP's `query()` tool with `parameters: { start_date: "...", end_date: "..." }`. Returns a `query_id`.
   - Call `publish_query(query_id, title)`. Returns an `embed_url` containing a signed token.
5. Paste each `embed_url` into the matching slot in `server.js`'s `QUERIES` map (the comments name the source `.sql` file).
6. Run it:
   ```bash
   npm install
   npm start
   ```
7. Open `http://localhost:3456`.

## File breakdown

- **`server.js`** — ~40-line Express proxy. Holds the embed URLs server-side, forwards `?start_date=` / `?end_date=` from the frontend so the date picker works without re-publishing.
- **`index.html`** — Single self-contained file. Inline `<style>` (dark theme, Chart.js sparklines, Tailwind-style grid), inline `<script>` (no build step), Chart.js 4 from CDN. Fetches from `/api/data/<key>`.
- **`package.json`** — Express is the only dependency.

## Security

The embed URLs in `server.js`, once you fill them in, are **signed bearer tokens**. Anyone with access to that file can pull data from your Graphed workspace until you revoke.

- Never commit a filled-in `server.js` to a public repo.
- Use environment variables in production:
  ```js
  const QUERIES = {
    organicKpis: process.env.GRAPHED_URL_ORGANIC_KPIS,
    // ...
  };
  ```
- Revoke any URL anytime via the MCP's `unpublish_query(query_id)`.

## Deployment

Any Node host. Railway / Fly / Render / Vercel serverless all work. Set the embed URLs as env vars, not in code. Express + 16 env vars + `node server.js` is the whole deploy surface.

## Customizing

- **Different brand** — search `index.html` for `--teal: #22d3ee` and the `Reach` text. Replace.
- **Different metrics** — write a new `.sql` file, publish, add to `QUERIES`, add a new card / chart block in `index.html` that fetches `/api/data/yourNewKey`.
- **Different data sources** — the same pattern works for any Graphed-connected source. Replace GA4/GSC/Ads queries with Stripe / HubSpot / Klaviyo equivalents.
