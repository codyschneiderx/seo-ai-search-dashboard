-- sourcesTimeseries
-- Daily sessions for the top 8 search sources. CTE pre-filters dimensions to keep response < 100KB.
-- Drives the "Sources Sessions Breakdown Evolution" multi-line chart.
WITH top_sources AS (
  SELECT session_source
  FROM {{GA4_SCHEMA}}.traffic_acquisition_session_source_report
  WHERE date >= toDate(%(start_date)s)
    AND date <= toDate(%(end_date)s)
    AND session_source IN ('google', 'bing', 'chatgpt.com', 'perplexity.ai',
                           'gemini.google.com', 'duckduckgo', 'yahoo', 'claude.ai')
  GROUP BY session_source
)
SELECT
  date,
  session_source,
  sum(sessions) AS sessions
FROM {{GA4_SCHEMA}}.traffic_acquisition_session_source_report
WHERE date >= toDate(%(start_date)s)
  AND date <= toDate(%(end_date)s)
  AND session_source IN (SELECT session_source FROM top_sources)
GROUP BY date, session_source
ORDER BY date, session_source
