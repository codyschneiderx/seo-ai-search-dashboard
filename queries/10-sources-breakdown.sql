-- sourcesBreakdown
-- Sessions per source, bucketed into AI vs Traditional. Used for the AI Engine Mix donut + mix bars.
SELECT
  CASE
    WHEN session_source IN ('chatgpt.com', 'perplexity.ai', 'perplexity',
                            'gemini.google.com', 'claude.ai') THEN 'AI'
    WHEN session_source IN ('google', 'bing', 'yahoo', 'duckduckgo',
                            'ecosia.org', 'search.brave.com') THEN 'Traditional'
    WHEN session_source LIKE '%yahoo%' THEN 'Traditional'
    ELSE NULL
  END AS bucket,
  session_source,
  sum(sessions)         AS sessions,
  sum(engaged_sessions) AS engaged_sessions
FROM {{GA4_SCHEMA}}.traffic_acquisition_session_source_report
WHERE date >= toDate(%(start_date)s)
  AND date <= toDate(%(end_date)s)
GROUP BY bucket, session_source
HAVING bucket IS NOT NULL
ORDER BY bucket, sessions DESC
