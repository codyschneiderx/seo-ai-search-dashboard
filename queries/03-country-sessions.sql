-- countrySessions
-- Top countries by engaged sessions. Used for the country bar list on the Organic Overview tab.
SELECT
  country,
  sum(engaged_sessions) AS sessions,
  sum(total_users)      AS users
FROM {{GA4_SCHEMA}}.demographic_country_report
WHERE date >= toDate(%(start_date)s)
  AND date <= toDate(%(end_date)s)
  AND country IS NOT NULL
  AND country != ''
GROUP BY country
ORDER BY sessions DESC
LIMIT 100
