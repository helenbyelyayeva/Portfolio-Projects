### Google Analytics 4 Data Analysis Using BigQuery

## Introduction

This repository provides SQL queries for extracting and analyzing data from Google Analytics 4 (GA4) for an e-commerce website. The queries are designed to prepare data for business intelligence (BI) reporting and to calculate various conversion metrics.

## Queries

#### Task 1: Data Preparation for BI Reports

The first task involves querying a public dataset containing data collected through Google Analytics 4 for an e-commerce website. The query retrieves information about events, users, and sessions, focusing on events related to session start, product view, adding items to cart, checkout initiation, shipping information addition, payment information addition, and purchase. The resulting table includes the following fields:

- **event_timestamp**: The timestamp of the event.
- **user_pseudo_id**: An anonymous identifier for the user in GA4.
- **session_id**: The session identifier for the event in GA4.
- **event_name**: The name of the event.
- **country**: The country of the user visiting the site.
- **device_category**: The category of the device used by the user.
- **source**: The source of the website visit.
- **medium**: The medium of the website visit.
- **campaign**: The name of the campaign for the website visit.

#### Task 2: Conversion Calculation by Date and Traffic Channels

The second task involves calculating conversion metrics from session start to purchase. The query creates a table with the following fields:

- **event_date**: The date of the session start event.
- **source**: The source of the website visit.
- **medium**: The medium of the website visit.
- **campaign**: The name of the campaign for the website visit.
- **user_sessions_count**: The count of unique sessions by unique users for the respective date and traffic channel.
- **visit_to_cart**: The conversion rate from session start to adding items to cart for the respective date and traffic channel.
- **visit_to_checkout**: The conversion rate from session start to checkout initiation for the respective date and traffic channel.
- **visit_to_purchase**: The conversion rate from session start to purchase for the respective date and traffic channel.

#### Task 3: Comparing Conversion Rates for Different Landing Pages

The third task involves extracting page paths from the session start events and calculating conversion metrics based on data from 2020. For each unique landing page, the metrics to calculate include:

- **user_sessions_count**: The count of unique sessions by unique users.
- **user_purchase_count**: The count of purchases.
- **visit_to_purchase**: The conversion rate from session start to purchase.

## Note

These SQL queries provide insights into user behavior and conversion rates, enabling businesses to make informed decisions based on their GA4 data.

