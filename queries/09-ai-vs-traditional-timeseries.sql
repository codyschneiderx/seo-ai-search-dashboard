-- aiVsTradTimeseries
-- Daily sessions per bucket (AI vs Traditional) for current + previous period.
-- The workhorse query for the AEO tab — drives the hero callout, 4 KPI cards, sparklines, and the big stacked area chart.
WITH classified AS (
  SELECT
    date,
    CASE
      WHEN session_source IN ('chatgpt.com', 'perplexity.ai', 'perplexity',
                              'gemini.google.com', 'claude.ai') THEN 'AI'
      WHEN session_source IN ('google', 'bing', 'yahoo', 'duckduckgo',
                              'ecosia.org', 'search.brave.com') THEN 'Traditional'
      WHEN session_source LIKE '%yahoo%' THEN 'Traditional'
      ELSE NULL
    END AS bucket,
    sessions,
    engaged_sessions
  FROM {{GA4_SCHEMA}}.traffic_acquisition_session_source_report
  WHERE date >= toDate(%(start_date)s) - (toDate(%(end_date)s) - toDate(%(start_date)s) + 1)
    AND date <= toDate(%(end_date)s)
)
SELECT
  date,
  bucket,
  CASE WHEN date >= toDate(%(start_date)s) THEN 'current' ELSE 'previous' END AS period,
  sum(sessions)         AS sessions,
  sum(engaged_sessions) AS engaged_sessions
FROM classified
WHERE bucket IS NOT NULL
GROUP BY date, bucket, period
ORDER BY date
