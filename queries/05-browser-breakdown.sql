-- browserBreakdown
-- Engaged sessions per browser. Used for the Browser donut.
SELECT
  browser,
  sum(engaged_sessions) AS sessions
FROM {{GA4_SCHEMA}}.tech_browser_report
WHERE date >= toDate(%(start_date)s)
  AND date <= toDate(%(end_date)s)
GROUP BY browser
ORDER BY sessions DESC
LIMIT 10
