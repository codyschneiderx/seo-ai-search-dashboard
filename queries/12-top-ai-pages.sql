-- topAiPages
-- Landing pages that AI engines (ChatGPT / Perplexity / Gemini / Claude) are referring users to.
-- Joins source-filtered landing pages with overall page engagement to get engagement rate per page.
-- This is the "what content do AI engines cite?" insight — the AEO money panel.
WITH ai_pages AS (
  SELECT
    landing_page,
    sum(sessions) AS ai_sessions
  FROM {{GA4_SCHEMA}}.landing_page_daily_session_source_medium
  WHERE date >= toDate(%(start_date)s)
    AND date <= toDate(%(end_date)s)
    AND (session_source_medium LIKE 'chatgpt.com%'
      OR session_source_medium LIKE 'perplexity%'
      OR session_source_medium LIKE 'gemini.google.com%'
      OR session_source_medium LIKE 'claude.ai%')
    AND landing_page IS NOT NULL
    AND landing_page != ''
    AND landing_page != '(not set)'
  GROUP BY landing_page
)
SELECT
  ai_pages.landing_page AS landing_page,
  ai_pages.ai_sessions  AS ai_sessions,
  toFloat64(pe.eng) / nullIf(toFloat64(pe.s), 0) AS engagement_rate
FROM ai_pages
LEFT JOIN (
  SELECT
    page_path,
    sum(sessions)         AS s,
    sum(engaged_sessions) AS eng
  FROM {{GA4_SCHEMA}}.page_engagement_report
  WHERE date >= toDate(%(start_date)s)
    AND date <= toDate(%(end_date)s)
  GROUP BY page_path
) pe ON pe.page_path = ai_pages.landing_page
ORDER BY ai_sessions DESC
LIMIT 25
