/*This query selects certain types of events from a Google Analytics dataset for ecommerce. 
 It looks at events like session start, purchases, and adding items to the cart. The data includes details like session ID, 
 timestamp, user ID, country, and device type. It focuses on events from 2021.*/

SELECT
  event_name,
  ( SELECT value.int_value FROM UNNEST(event_params) WHERE KEY = 'ga_session_id') AS session_id,
  FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP_MICROS(event_timestamp)) AS event_timestamp_seconds,
  user_pseudo_id,
  geo.country AS country,
  device.category AS device_category,
  traffic_source.source AS SOURCE,
  traffic_source.name AS campaign,
  traffic_source.medium AS medium,
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  event_name IN ( 'session_start', 'view_item', 'add_to_cart', 'begin_checkout', 'add_payment_info', 'add_shipping_info', 'purchase' )
  AND _table_suffix BETWEEN '20210101'AND '20211231'
LIMIT
  40

/*This query analyzes events related to e-commerce activities, such as session starts, adding items to cart, beginning checkout, and purchases. 
It calculates various metrics such as the number of unique sessions, the count of sessions that involve adding to cart, beginning checkout, and completing purchases. 
Finally, it computes conversion rates from session start to adding items to cart, beginning checkout, and making purchases.*/

with cr_events as (
  select
    timestamp_micros(event_timestamp) as event_timestamp,
    event_name,
    user_pseudo_id ||
      cast((select value.int_value from e.event_params where key = 'ga_session_id') as string)
      as user_session_id,
    traffic_source.source,
    traffic_source.medium,
    traffic_source.name as campaign
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
  where
    event_name in ('session_start', 'add_to_cart', 'begin_checkout', 'purchase')
),


events_count as (
  select
    date(event_timestamp) as event_date,
    source,
    medium,
    campaign,
    count(distinct user_session_id) as user_sessions_count,
    count(distinct case when event_name = 'add_to_cart' then user_session_id end) as added_to_cart_count,
    count(distinct case when event_name = 'begin_checkout' then user_session_id end) as began_checkout_count,
    count(distinct case when event_name = 'purchase' then user_session_id end) as purchased_count
  from cr_events
  group by 1,2,3,4
)


select
  event_date,
  source,
  medium,
  campaign,
  user_sessions_count,
  added_to_cart_count / user_sessions_count as visit_to_cart,
  began_checkout_count / user_sessions_count as visit_to_checkout,
  purchased_count / user_sessions_count as visit_to_purchase,
from events_count
LIMIT
  40;

/*This query extracts session and purchase data from e-commerce events, focusing on the period from January 1, 2020, to December 31, 2020.
 It calculates the conversion rate from session start to purchase for each page path, presenting the top 40 paths with the highest conversion rates.*/


WITH session_purchase AS (
  SELECT
    REGEXP_EXTRACT(
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'),
      r'(?:\w+\:\/\/)?[^\/]+\/([^\?#]*)'
    ) AS page_path,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    user_pseudo_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20200101' AND '20201231'
),
session_data AS (
  SELECT
    DISTINCT page_path,
    user_pseudo_id,
    session_id
  FROM session_purchase
  WHERE event_name = 'session_start'
),
purchase_data AS (
  SELECT
    user_pseudo_id,
    session_id
  FROM session_purchase
  WHERE event_name = 'purchase'
)
SELECT
  page_path,
  COUNT(DISTINCT s.user_pseudo_id ) AS user_sessions_count,
  COUNT(DISTINCT p.user_pseudo_id ) AS user_purchase_count,
  ROUND(
    COUNT(DISTINCT p.user_pseudo_id ) / COUNT(DISTINCT s.user_pseudo_id ),
    3
  ) AS visit_to_purchase
FROM session_data s
LEFT JOIN purchase_data p
USING (user_pseudo_id, session_id)
GROUP BY page_path
ORDER BY visit_to_purchase DESC
LIMIT 40;