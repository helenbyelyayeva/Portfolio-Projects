# README: PostgreSQL Queries for Ad Campaign Analysis

## Introduction

This repository contains SQL queries for analyzing ad campaign performance data from Facebook and Google Ads. The queries are designed to run on a PostgreSQL database.

## Machine and Functions Used

The queries were executed on a PostgreSQL database instance. No specific machine configuration or functions beyond standard SQL are required.

## Queries

### Query 1: Facebook Metrics Aggregation

This query calculates various metrics for Facebook ads on a daily basis. Metrics include total spend, clicks, impressions, value, CPC (Cost Per Click), CPM (Cost Per Thousand Impressions), CTR (Click Through Rate), and ROMI (Return on Marketing Investment).

### Query 2: Campaign with Highest ROMI

This query identifies the adset with the highest Return on Marketing Investment (ROMI) among those with a total spend greater than $500,000. It calculates ROMI as the ratio of total value to total spend.

### Query 3: Campaigns Metrics Aggregation

This query combines data from Facebook and Google ad campaigns to calculate aggregated metrics such as total spend, impressions, clicks, and value for each campaign on a daily basis.

### Query 4: Campaign with Highest ROMI (With Common Table Expression)

This query  identifies the adset with the highest ROMI among those with a total spend greater than $500,000. It uses a common table expression (CTE) to combine data from Facebook and Google ad campaigns.

### Query 5: Combined Campaign Metrics with Decoded UTM

This query combines data from Facebook and Google ad campaigns to calculate aggregated metrics for each ad campaign. It uses a common table expression (CTE) called COMBINED_DATA to merge data from both sources and handle null values. The SELECT statement then calculates metrics such as total spend, impressions, clicks, and value, and also decodes the UTM_CAMPAIGN value extracted from URL_PARAMETERS.

### Query 6: Monthly Campaign Metrics and Differences

This query calculates aggregated metrics for Facebook and Google ad campaigns on a monthly basis. It first creates a common table expression (CTE) named combined_data by merging data from both platforms. Then, another CTE named monthly_data aggregates the data by month and decodes the UTM_CAMPAIGN parameter. The final CTE, monthly_data_with_diff, calculates differences in CPM, CTR, and ROMI compared to the previous month. The main query selects the aggregated metrics along with the calculated differences.

## Usage

To use these queries:

1. Ensure you have PostgreSQL installed.
2. Create a database and import the necessary tables (e.g., `facebook_ads_basic_daily`, `facebook_campaign`, `facebook_adset`, `google_ads_basic_daily`) - [link](https://drive.google.com/drive/folders/1erphJvPe5WeD5NYLKIGKr8s9HFgUg8oy?usp=sharing).
3. Copy and paste the queries into your PostgreSQL client .
4. Execute the queries to analyze the ad campaign data.

## Note

These queries are provided as examples and may need to be adapted to your specific database schema and requirements.


