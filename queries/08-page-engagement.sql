-- pageEngagement
-- Top pages by total sessions with engaged sessions, users, and bounce rate.
-- Drives the "Most Visited Pages" table on Organic Overview.
-- Not source-filtered (GA4 export doesn't carry source on page_engagement_report).
SELECT
  page_path,
  sum(sessions)         AS total_sessions,
  sum(total_users)      AS total_users,
  sum(engaged_sessions) AS total_engaged,
  sum(engaged_sessions) / nullIf(sum(sessions), 0)       AS engagement_rate,
  1 - (sum(engaged_sessions) / nullIf(sum(sessions), 0)) AS bounce_rate
FROM {{GA4_SCHEMA}}.page_engagement_report
WHERE date >= toDate(%(start_date)s)
  AND date <= toDate(%(end_date)s)
  AND page_path IS NOT NULL
  AND page_path != ''
GROUP BY page_path
ORDER BY total_sessions DESC
LIMIT 25
