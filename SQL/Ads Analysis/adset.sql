/*
   This query calculates various metrics for Facebook ads on a daily basis.
   Metrics include total spend, clicks, impressions, value, CPC (Cost Per Click), CPM (Cost Per Thousand Impressions), CTR (Click Through Rate), and ROMI
   (Return on Marketing Investment).
   
   The query filters out records where impressions, clicks, and spend are greater than zero, and groups the results by ad_date and campaign_id.
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
   This query combines Facebook and Google ad campaign data to calculate total spend, impressions, clicks, and value per campaign daily.
   It uses a common table expression (CTE) called combined_data to merge data from both platforms using the UNION operator.
   Metrics are then aggregated by campaign_name and ad_date from the combined_data CTE.
   The result offers a concise overview of daily ad campaign performance across platforms.
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
   This query finds the adset with the highest ROMI among those with a total spend greater than $500,000. 
   It combines data from Facebook and Google ad campaigns  and calculates ROMI as the ratio of total value to total spend.
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

/*
   This query combines data from Facebook and Google ad campaigns to calculate aggregated metrics for each ad campaign. 
   It uses a common table expression (CTE) called COMBINED_DATA to merge data from both sources and handle null values. 
   The SELECT statement then calculates metrics such as total spend, impressions, clicks, and value, 
   and also decodes the UTM_CAMPAIGN value extracted from URL_PARAMETERS. 
*/


WITH COMBINED_DATA AS (
SELECT
	AD_DATE,
	PUBLIC.FACEBOOK_ADS_BASIC_DAILY.CAMPAIGN_ID,
	PUBLIC.FACEBOOK_ADS_BASIC_DAILY.ADSET_ID,
	COALESCE(SPEND,0) AS SPEND,
	COALESCE(IMPRESSIONS,0) AS IMPRESSIONS,
	COALESCE(REACH,0) AS REACH,
	COALESCE(CLICKS,0) AS CLICKS,
	COALESCE(LEADS,0) AS LEADS,
	COALESCE(VALUE,0) AS VALUE,
	URL_PARAMETERS,
	TOTAL,
	CAST(CAMPAIGN_NAME AS TEXT) AS CAMPAIGN_NAME,
	ADSET_NAME
FROM
	PUBLIC.FACEBOOK_ADS_BASIC_DAILY
JOIN PUBLIC.FACEBOOK_CAMPAIGN ON
	PUBLIC.FACEBOOK_ADS_BASIC_DAILY.CAMPAIGN_ID = PUBLIC.FACEBOOK_CAMPAIGN.CAMPAIGN_ID
JOIN PUBLIC.FACEBOOK_ADSET ON
	PUBLIC.FACEBOOK_ADS_BASIC_DAILY.ADSET_ID = PUBLIC.FACEBOOK_ADSET.ADSET_ID
UNION
SELECT
	AD_DATE,
	NULL AS CAMPAIGN_ID,
	NULL AS ADSET_ID,
	COALESCE(SPEND,0) AS SPEND,
	COALESCE(IMPRESSIONS,0) AS IMPRESSIONS,
	COALESCE(REACH,0) AS REACH,
	COALESCE(CLICKS,0) AS CLICKS,
	COALESCE(LEADS,0) AS LEADS,
	COALESCE(VALUE,0) AS VALUE,
	URL_PARAMETERS,
	NULL AS TOTAL,
	CAST(CAMPAIGN_NAME AS TEXT) AS CAMPAIGN_NAME,
	ADSET_NAME
FROM
	PUBLIC.GOOGLE_ADS_BASIC_DAILY
)
SELECT
	AD_DATE,
 CASE
        WHEN LOWER(SUBSTRING(URL_PARAMETERS, 'utm_campaign=([^&#$]+)')) = 'nan' THEN NULL
        WHEN LOWER(SUBSTRING(URL_PARAMETERS FROM 'utm_campaign=([^&]*)')) LIKE '%d1%82%d1%80%d0%b5%d0%bd%d0%b4%' THEN REPLACE(LOWER(SUBSTRING(URL_PARAMETERS FROM 'utm_campaign=([^&]*)')), '%d1%82%d1%80%d0%b5%d0%bd%d0%b4', 'trend')
        WHEN LOWER(SUBSTRING(URL_PARAMETERS FROM 'utm_campaign=([^&]*)')) LIKE '%d0%b1%d1%80%d0%b5%d0%bd%d0%b4%' THEN REPLACE(LOWER(SUBSTRING(URL_PARAMETERS FROM 'utm_campaign=([^&]*)')), '%d0%b1%d1%80%d0%b5%d0%bd%d0%b4', 'brand')
        ELSE LOWER(SUBSTRING(URL_PARAMETERS FROM 'utm_campaign=([^&]*)'))
    END AS UTM_CAMPAIGN,
	SUM(SPEND) AS TOTAL_SPEND,
	SUM(IMPRESSIONS) AS TOTAL_IMPRESSIONS,
	SUM(CLICKS) AS TOTAL_CLICKS,
	SUM(VALUE) AS TOTAL_VALUE,
	CASE
		WHEN SUM(CLICKS) > 0 THEN ROUND(CAST(SUM(SPEND) AS NUMERIC) / SUM(CLICKS),
		3)
	END AS CPC,
	CASE
		WHEN SUM(IMPRESSIONS) > 0 THEN ROUND((CAST(SUM(SPEND) AS NUMERIC) / SUM(IMPRESSIONS)) * 1000,
		3)
	END AS CPM,
	CASE
		WHEN SUM(IMPRESSIONS) > 0 THEN ROUND((CAST(SUM(CLICKS) AS NUMERIC) / SUM(IMPRESSIONS)) * 100,
		3)
	END AS CTR,
	CASE
		WHEN SUM(SPEND) > 0 THEN ROUND(((CAST(SUM(VALUE) AS NUMERIC) - SUM(SPEND)) / SUM(SPEND)) * 100,
		3)
	END AS ROMI
FROM
	COMBINED_DATA
GROUP BY
	AD_DATE,
	UTM_CAMPAIGN;

/*
   This query calculates aggregated metrics for Facebook and Google ad campaigns on a monthly basis.
   It first creates a common table expression (CTE) named combined_data by merging data from both platforms.
   Then, another CTE named monthly_data aggregates the data by month and decodes the UTM_CAMPAIGN parameter.
   The final CTE, monthly_data_with_diff, calculates differences in CPM, CTR, and ROMI compared to the previous month.
   The main query selects the aggregated metrics along with the calculated differences.
*/





WITH combined_data AS (
    SELECT
        TO_CHAR(DATE_TRUNC('month', ad_date::DATE), 'YYYY-MM-DD') AS ad_date,
        PUBLIC.FACEBOOK_ADS_BASIC_DAILY.CAMPAIGN_ID,
        PUBLIC.FACEBOOK_ADS_BASIC_DAILY.ADSET_ID,
        COALESCE(SPEND,0) AS SPEND,
        COALESCE(IMPRESSIONS,0) AS IMPRESSIONS,
        COALESCE(REACH,0) AS REACH,
        COALESCE(CLICKS,0) AS CLICKS,
        COALESCE(LEADS,0) AS LEADS,
        COALESCE(VALUE,0) AS VALUE,
        URL_PARAMETERS,
        TOTAL,
        CAST(CAMPAIGN_NAME AS TEXT) AS CAMPAIGN_NAME,
        ADSET_NAME
    FROM PUBLIC.FACEBOOK_ADS_BASIC_DAILY
    JOIN PUBLIC.FACEBOOK_CAMPAIGN ON PUBLIC.FACEBOOK_ADS_BASIC_DAILY.CAMPAIGN_ID = PUBLIC.FACEBOOK_CAMPAIGN.CAMPAIGN_ID
    JOIN PUBLIC.FACEBOOK_ADSET ON PUBLIC.FACEBOOK_ADS_BASIC_DAILY.ADSET_ID = PUBLIC.FACEBOOK_ADSET.ADSET_ID
    UNION
    SELECT
        TO_CHAR(DATE_TRUNC('month', ad_date::DATE), 'YYYY-MM-DD') AS ad_date,
        NULL AS CAMPAIGN_ID,
        NULL AS ADSET_ID,
        COALESCE(SPEND,0) AS SPEND,
        COALESCE(IMPRESSIONS,0) AS IMPRESSIONS,
        COALESCE(REACH,0) AS REACH,
        COALESCE(CLICKS,0) AS CLICKS,
        COALESCE(LEADS,0) AS LEADS,
        COALESCE(VALUE,0) AS VALUE,
        URL_PARAMETERS,
        NULL AS TOTAL,
        CAST(CAMPAIGN_NAME AS TEXT) AS CAMPAIGN_NAME,
        ADSET_NAME
    FROM PUBLIC.GOOGLE_ADS_BASIC_DAILY
),
monthly_data AS (
    SELECT
        TO_CHAR(DATE_TRUNC('month', ad_date::DATE), 'YYYY-MM-01') AS ad_month,
       CASE
        WHEN LOWER(SUBSTRING(URL_PARAMETERS, 'utm_campaign=([^&#$]+)')) = 'nan' THEN NULL
        WHEN LOWER(SUBSTRING(URL_PARAMETERS FROM 'utm_campaign=([^&]*)')) LIKE '%d1%82%d1%80%d0%b5%d0%bd%d0%b4%' THEN REPLACE(LOWER(SUBSTRING(URL_PARAMETERS FROM 'utm_campaign=([^&]*)')), '%d1%82%d1%80%d0%b5%d0%bd%d0%b4', 'trend')
        WHEN LOWER(SUBSTRING(URL_PARAMETERS FROM 'utm_campaign=([^&]*)')) LIKE '%d0%b1%d1%80%d0%b5%d0%bd%d0%b4%' THEN REPLACE(LOWER(SUBSTRING(URL_PARAMETERS FROM 'utm_campaign=([^&]*)')), '%d0%b1%d1%80%d0%b5%d0%bd%d0%b4', 'brand')
        ELSE LOWER(SUBSTRING(URL_PARAMETERS FROM 'utm_campaign=([^&]*)'))
    END AS UTM_CAMPAIGN,
        SUM(SPEND) AS TOTAL_SPEND,
        SUM(IMPRESSIONS) AS TOTAL_IMPRESSIONS,
        SUM(CLICKS) AS TOTAL_CLICKS,
        SUM(VALUE) AS TOTAL_VALUE,
        CASE
            WHEN SUM(CLICKS) > 0 THEN ROUND(CAST(SUM(SPEND) AS NUMERIC) / SUM(CLICKS), 3)
        END AS CPC,
        CASE
            WHEN SUM(IMPRESSIONS) > 0 THEN ROUND(CAST(SUM(SPEND) AS NUMERIC) / SUM(IMPRESSIONS) * 1000, 3)
        END AS CPM,
        CASE
            WHEN SUM(IMPRESSIONS) > 0 THEN ROUND(CAST(SUM(CLICKS) AS NUMERIC) / SUM(IMPRESSIONS) * 100, 3)
        END AS CTR,
        CASE
            WHEN SUM(SPEND) > 0 THEN ROUND(((CAST(SUM(VALUE) AS NUMERIC) - SUM(SPEND)) / SUM(SPEND)) * 100, 3)
        END AS ROMI
    FROM combined_data
    GROUP BY ad_month, UTM_CAMPAIGN
),
monthly_data_with_diff AS (
    SELECT
        ad_month,
        UTM_CAMPAIGN,
        TOTAL_SPEND,
        TOTAL_IMPRESSIONS,
        TOTAL_CLICKS,
        TOTAL_VALUE,
        CTR,
        CPC,
        CPM,
        ROMI,
        (CPM - LAG(CPM) OVER (PARTITION BY UTM_CAMPAIGN ORDER BY ad_month)) AS CPM_DIFF,
        (CTR - LAG(CTR) OVER (PARTITION BY UTM_CAMPAIGN ORDER BY ad_month)) AS CTR_DIFF,
        (ROMI - LAG(ROMI) OVER (PARTITION BY UTM_CAMPAIGN ORDER BY ad_month)) AS ROMI_DIFF
    FROM monthly_data
)
SELECT
    ad_month,
    UTM_CAMPAIGN,
    TOTAL_SPEND,
    TOTAL_IMPRESSIONS,
    TOTAL_CLICKS,
    TOTAL_VALUE,
    CTR,
    CPC,
    CPM,
    ROMI,
    CPM_DIFF,
    CTR_DIFF,
    ROMI_DIFF
FROM monthly_data_with_diff;

