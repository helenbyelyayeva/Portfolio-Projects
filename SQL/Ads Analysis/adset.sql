/*
   This query calculates various metrics for Facebook ads on a daily basis.
   Metrics include total spend, clicks, impressions, value, CPC (Cost Per Click),
   CPM (Cost Per Thousand Impressions), CTR (Click Through Rate), and ROMI
   (Return on Marketing Investment).
   
   The query filters out records where impressions, clicks, and spend are greater
   than zero, and groups the results by ad_date and campaign_id.
*/

SELECT
  ad_date,
  campaign_id,
  SUM(spend) AS total_spend,
  SUM(clicks) AS total_clicks,
  SUM(impressions) AS total_impressions,
  SUM(value) AS total_value,
  ROUND(CAST(SUM(spend) AS numeric) / SUM(clicks), 3) AS CPC,
  ROUND((CAST(SUM(spend) AS numeric) / SUM(impressions)) * 1000, 3) AS CPM,
  ROUND((CAST(SUM(clicks) AS numeric) / SUM(impressions)) * 100, 3) AS CTR,
  ROUND((((SUM(VALUE) AS NUMERIC) - SUM(SPEND)) / SUM(SPEND)), 3) AS ROMI
FROM
  public.facebook_ads_basic_daily
WHERE
  impressions > 0 AND clicks > 0 AND spend > 0
GROUP BY
  ad_date, campaign_id;


/*
   This query calculates the campaign with the maximum Return on Marketing Investment (ROMI)
   among campaigns with a total spend greater than $500,000. ROMI is calculated as the difference
   between total value and total spend divided by total spend. The query filters out records where
   spend is greater than zero and groups the results by campaign_id.
   Finally, it orders the results by max_romi in descending order and limits the output to one row.
*/


SELECT campaign_id, MAX(ROMI) AS max_romi
FROM (
  SELECT campaign_id,
  SUM(spend) AS total_spend,
  SUM(value) AS total_value,
  ROUND(((cast(SUM(VALUE) as numeric) - SUM(SPEND)) / SUM(SPEND)),3) as ROMI
  FROM public.facebook_ads_basic_daily
  WHERE impressions > 0 AND clicks > 0 AND spend > 0
  GROUP BY campaign_id
) AS campaign_totals
WHERE total_spend > 500000
GROUP BY campaign_id
ORDER BY max_romi DESC
LIMIT 1;

/*
   This query combines data from Facebook and Google ad campaigns to calculate
   aggregated metrics such as total spend, impressions, clicks, and value for each
   campaign on a daily basis.

   The WITH clause creates a common table expression (CTE) called combined_data by
   joining data from the tables public.facebook_ads_basic_daily, public.facebook_campaign,
   and public.facebook_adset for Facebook ads, and public.google_ads_basic_daily for
   Google ads. It uses the UNION operator to merge the data from both sources.

   The SELECT statement then calculates the aggregated metrics by summing up spend,
   impressions, clicks, and value for each campaign_name and ad_date from the combined_data
   CTE. The results are grouped by ad_date and campaign_name.

   Overall, this query provides a consolidated view of ad campaign performance across
   different platforms on a daily basis.
*/

WITH combined_data AS (
  SELECT ad_date, public.facebook_ads_basic_daily.campaign_id, public.facebook_ads_basic_daily.adset_id, spend, impressions, reach, clicks, leads, value, url_parameters, total, CAST(campaign_name AS text) AS campaign_name, adset_name
  FROM public.facebook_ads_basic_daily
  JOIN public.facebook_campaign ON public.facebook_ads_basic_daily.campaign_id = public.facebook_campaign.campaign_id
  JOIN public.facebook_adset ON public.facebook_ads_basic_daily.adset_id = public.facebook_adset.adset_id
  UNION
  SELECT ad_date, NULL AS campaign_id, NULL AS adset_id, spend, impressions, reach, clicks, leads, value, url_parameters, NULL AS total, CAST(campaign_name AS text) AS campaign_name, adset_name
  FROM public.google_ads_basic_daily
)

SELECT ad_date, campaign_name,
  SUM(spend) AS total_spend,
  SUM(impressions) AS total_impressions,
  SUM(clicks) AS total_clicks,
  SUM(value) AS total_value
FROM combined_data
GROUP BY ad_date, campaign_name;

/*
   This query finds the adset with the highest ROMI 
   among those with a total spend greater than $500,000. 
   It combines data from Facebook and Google ad campaigns 
   and calculates ROMI as the ratio of total value to total spend.
*/

WITH combined_data AS (
select
ad_date, url_parameters, spend, impressions,
reach, clicks, leads, value
from facebook_ads_basic_daily
join facebook_adset on facebook_adset.adset_id = facebook_ads_basic_daily.adset_id
join facebook_campaign on facebook_campaign.campaign_id = facebook_ads_basic_daily.campaign_id
union all
select
ad_date, url_parameters, spend, impressions,
reach, clicks, leads, value
from Google_ads_basic_daily
)

SELECT campaign_name, adset_name, MAX(ROMI) AS max_romi
FROM (
  SELECT campaign_name, adset_name,
    SUM(spend) AS total_spend,
    SUM(value) AS total_value,
    ROUND(((cast(SUM(VALUE) as numeric) - SUM(SPEND)) / SUM(SPEND)),3) as ROMI
  FROM combined_data
  GROUP BY campaign_name, adset_name
  HAVING SUM(spend) > 500000
) AS campaign_totals
GROUP BY campaign_name, adset_name
ORDER BY max_romi DESC
LIMIT 1;
