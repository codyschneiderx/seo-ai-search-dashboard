-- avgPositionTimeseries
-- Daily impressions, clicks, and weighted average position from GSC.
-- Drives the Avg Position Evolution chart on the Budget tab + the sparklines on the AEO tab's GSC strip.
-- Weighted avg position: sum(position * impressions) / sum(impressions) — a plain avg() would treat
-- a 1-impression query the same as a 10,000-impression query.
-- Note the renamed outer aliases (total_impressions, total_clicks) to avoid ClickHouse's
-- "aggregate inside aggregate" error.
SELECT
  date,
  sum(position * impressions) / nullIf(sum(impressions), 0) AS avg_position,
  sum(impressions) AS total_impressions,
  sum(clicks)      AS total_clicks
FROM {{GSC_SCHEMA}}.keyword_site_report_by_site
WHERE date >= toDate(%(start_date)s)
  AND date <= toDate(%(end_date)s)
GROUP BY date
ORDER BY date
