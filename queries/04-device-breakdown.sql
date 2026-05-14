-- deviceBreakdown
-- Engaged sessions per device category. Used for the Device donut.
SELECT
  device_category       AS device,
  sum(engaged_sessions) AS sessions,
  sum(total_users)      AS users
FROM {{GA4_SCHEMA}}.tech_device_category_report
WHERE date >= toDate(%(start_date)s)
  AND date <= toDate(%(end_date)s)
  AND device_category IS NOT NULL
GROUP BY device_category
ORDER BY sessions DESC
