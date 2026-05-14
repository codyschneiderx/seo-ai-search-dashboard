-- gscTotals
-- Site-wide GSC totals for the AEO tab footer strip: impressions, clicks, distinct ranking queries.
SELECT
  sum(impressions)    AS impressions,
  sum(clicks)         AS clicks,
  uniqExact(query)    AS keywords
FROM {{GSC_SCHEMA}}.keyword_site_report_by_site
WHERE date >= toDate(%(start_date)s)
  AND date <= toDate(%(end_date)s)
