-- organicKpis
-- Total organic sessions / engaged / key events / users for current period + previous period (one query).
-- Drives the 4 KPI cards on the Organic Overview tab.
-- Replace {{GA4_SCHEMA}} with the GA4 schema name returned by explore_schema()
SELECT
  CASE WHEN date >= toDate(%(start_date)s) THEN 'current' ELSE 'previous' END AS period,
  sum(sessions)         AS sessions,
  sum(engaged_sessions) AS engaged_sessions,
  sum(key_events)       AS key_events,
  sum(total_users)      AS total_users
FROM {{GA4_SCHEMA}}.traffic_acquisition_session_medium_report
WHERE session_medium = 'organic'
  AND date >= toDate(%(start_date)s) - (toDate(%(end_date)s) - toDate(%(start_date)s) + 1)
  AND date <= toDate(%(end_date)s)
GROUP BY period
ORDER BY period
