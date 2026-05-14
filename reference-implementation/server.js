// Express proxy for the SEO & AI Search Dashboard.
//
// Holds Graphed published-query embed URLs server-side (they contain secret tokens)
// and exposes them at /api/data/<key>. Forwards ?start_date= and ?end_date= so the
// frontend date picker can override the published defaults.
//
// To fill in the URLs:
//   1. For each SQL file in ../queries/, replace {{GA4_SCHEMA}} / {{GSC_SCHEMA}} / {{ADS_SCHEMA}}
//      with the schema IDs from your Graphed workspace (call explore_schema() via the MCP).
//   2. Run each via the Graphed MCP's query() tool to get a query_id.
//   3. Call publish_query(query_id) to get an embed_url with token.
//   4. Paste the embed URL below in place of __REPLACE_ME__.
//
// Or let an agent do it for you. See SKILL.md in the repo root.

const express = require('express');
const app = express();
const PORT = process.env.PORT || 3456;

const QUERIES = {
  organicKpis:           '__REPLACE_ME_AFTER_PUBLISHING__',  // 01-organic-kpis.sql
  organicTimeseries:     '__REPLACE_ME_AFTER_PUBLISHING__',  // 02-organic-timeseries.sql
  countrySessions:       '__REPLACE_ME_AFTER_PUBLISHING__',  // 03-country-sessions.sql
  deviceBreakdown:       '__REPLACE_ME_AFTER_PUBLISHING__',  // 04-device-breakdown.sql
  browserBreakdown:      '__REPLACE_ME_AFTER_PUBLISHING__',  // 05-browser-breakdown.sql
  osBreakdown:           '__REPLACE_ME_AFTER_PUBLISHING__',  // 06-os-breakdown.sql
  dayOfWeekOrganic:      '__REPLACE_ME_AFTER_PUBLISHING__',  // 07-day-of-week-organic.sql
  pageEngagement:        '__REPLACE_ME_AFTER_PUBLISHING__',  // 08-page-engagement.sql
  aiVsTradTimeseries:    '__REPLACE_ME_AFTER_PUBLISHING__',  // 09-ai-vs-traditional-timeseries.sql
  sourcesBreakdown:      '__REPLACE_ME_AFTER_PUBLISHING__',  // 10-sources-breakdown.sql
  sourcesTimeseries:     '__REPLACE_ME_AFTER_PUBLISHING__',  // 11-sources-timeseries.sql
  topAiPages:            '__REPLACE_ME_AFTER_PUBLISHING__',  // 12-top-ai-pages.sql
  gscTotals:             '__REPLACE_ME_AFTER_PUBLISHING__',  // 13-gsc-totals.sql
  avgPositionTimeseries: '__REPLACE_ME_AFTER_PUBLISHING__',  // 14-avg-position-timeseries.sql
  investInAds:           '__REPLACE_ME_AFTER_PUBLISHING__',  // 15-invest-in-ads.sql
  searchTermSaveMoney:   '__REPLACE_ME_AFTER_PUBLISHING__',  // 16-save-money-search-terms.sql
};

app.use(express.static('.'));

app.get('/api/data/:key', async (req, res) => {
  const baseUrl = QUERIES[req.params.key];
  if (!baseUrl || baseUrl.startsWith('__REPLACE_ME')) {
    return res.status(404).json({
      error: 'Unknown or unpublished query key',
      hint: 'Fill in the QUERIES map in server.js with published embed URLs from your Graphed workspace.',
    });
  }
  try {
    const url = new URL(baseUrl);
    for (const [k, v] of Object.entries(req.query)) {
      url.searchParams.set(k, v);
    }
    const r = await fetch(url);
    res.json(await r.json());
  } catch (e) {
    res.status(502).json({ error: 'Upstream fetch failed', detail: String(e) });
  }
});

app.listen(PORT, () => console.log(`SEO & AI Search Dashboard at http://localhost:${PORT}`));
