-- dayOfWeekOrganic
-- Organic sessions grouped by day of week (1 = Monday … 7 = Sunday). Used for the DoW bar chart.
SELECT
  toDayOfWeek(date) AS dow,
  sum(sessions)     AS sessions
FROM {{GA4_SCHEMA}}.traffic_acquisition_session_medium_report
WHERE session_medium = 'organic'
  AND date >= toDate(%(start_date)s)
  AND date <= toDate(%(end_date)s)
GROUP BY dow
ORDER BY dow
