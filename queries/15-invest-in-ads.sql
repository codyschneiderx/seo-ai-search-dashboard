-- investInAds
-- GSC queries with high impressions but ranking 10-30 (page 2+).
-- These are queries you're visible for but not getting organic clicks on — real paid-ad opportunity.
-- HAVING filters at the aggregated level (impressions > 200 AND weighted avg position 10-30).
SELECT
  query,
  sum(impressions)                                          AS total_impressions,
  sum(clicks)                                               AS total_clicks,
  sum(position * impressions) / nullIf(sum(impressions), 0) AS avg_position
FROM {{GSC_SCHEMA}}.keyword_site_report_by_site
WHERE date >= toDate(%(start_date)s)
  AND date <= toDate(%(end_date)s)
  AND query IS NOT NULL
  AND query != ''
GROUP BY query
HAVING total_impressions > 200
   AND avg_position BETWEEN 10 AND 30
ORDER BY total_impressions DESC
LIMIT 30
