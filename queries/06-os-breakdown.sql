-- osBreakdown
-- Engaged sessions per operating system. Used for the Operating System donut.
SELECT
  operating_system      AS os,
  sum(engaged_sessions) AS sessions
FROM {{GA4_SCHEMA}}.tech_operating_system_report
WHERE date >= toDate(%(start_date)s)
  AND date <= toDate(%(end_date)s)
GROUP BY os
ORDER BY sessions DESC
LIMIT 10
