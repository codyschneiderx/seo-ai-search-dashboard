-- searchTermSaveMoney
-- The headline "save money" panel. Joins Google Ads search_term_keyword_stats (what users
-- actually typed when triggering your ads) against GSC keyword_site_report_by_site (organic).
-- Returns paid search terms where the same query has organic rank <= 10.
--
-- IMPORTANT: use search_term_keyword_stats (actual user queries) NOT keyword_stats (your bid keywords).
-- One bid keyword usually expands to 20-50 user search terms, so search_term gives far more
-- overlap candidates and is the right grain for this insight.
WITH paid_terms AS (
  SELECT
    lower(search_term)         AS term,
    sum(cost_micros) / 1e6     AS spend,
    sum(clicks)                AS paid_clicks,
    sum(impressions)           AS paid_imp
  FROM {{ADS_SCHEMA}}.search_term_keyword_stats
  WHERE date >= toDate(%(start_date)s)
    AND date <= toDate(%(end_date)s)
  GROUP BY term
  HAVING spend > 0
),
organic AS (
  SELECT
    lower(query)                                              AS q,
    sum(position * impressions) / nullIf(sum(impressions), 0) AS avg_pos,
    sum(impressions)                                          AS o_imp,
    sum(clicks)                                               AS o_clk
  FROM {{GSC_SCHEMA}}.keyword_site_report_by_site
  WHERE date >= toDate(%(start_date)s)
    AND date <= toDate(%(end_date)s)
  GROUP BY q
)
SELECT
  p.term       AS query,
  o.avg_pos    AS organic_position,
  p.spend      AS ad_spend,
  p.paid_clicks,
  o.o_imp      AS organic_impressions,
  o.o_clk      AS organic_clicks
FROM paid_terms p
JOIN organic o ON p.term = o.q
WHERE o.avg_pos <= 10
ORDER BY p.spend DESC
LIMIT 50
