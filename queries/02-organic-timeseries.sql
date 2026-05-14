-- organicTimeseries
-- Daily organic sessions + key events for current + previous period.
-- Powers the two time-series charts on the Organic Overview tab (current line + dashed previous).
SELECT
  date,
  CASE WHEN date >= toDate(%(start_date)s) THEN 'current' ELSE 'previous' END AS period,
  sum(sessions)   AS sessions,
  sum(key_events) AS key_events
FROM {{GA4_SCHEMA}}.traffic_acquisition_session_medium_report
WHERE session_medium = 'organic'
  AND date >= toDate(%(start_date)s) - (toDate(%(end_date)s) - toDate(%(start_date)s) + 1)
  AND date <= toDate(%(end_date)s)
GROUP BY date, period
ORDER BY date
