WITH MonthlyRevenue AS (
   SELECT
       user_id,
       DATE_TRUNC('MONTH', payment_date)::DATE AS payment_month,
       SUM(revenue_amount_usd) AS monthly_revenue
   FROM
       project.games_payments
   GROUP BY
       user_id,
       DATE_TRUNC('MONTH', payment_date)::DATE
),
ContractionCTE AS (
   SELECT
       user_id,
       payment_month,
       monthly_revenue,
       LAG(monthly_revenue) OVER (PARTITION BY user_id ORDER BY payment_month) AS previous_monthly_revenue,
       LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) AS previous_paid_month,
       LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) AS next_paid_month,
       DATE_TRUNC('MONTH', payment_month - INTERVAL '1' MONTH)::DATE AS previous_calendar_month
   FROM
       MonthlyRevenue
)
SELECT
   gu.user_id,
   gu.game_name,
   gu."language",
   gu.has_older_device_model,
   gu.age,
   cr.payment_month,
   LAG(cr.monthly_revenue) OVER (PARTITION BY gu.user_id ORDER BY cr.payment_month) AS previous_monthly_revenue,
   LAG(cr.payment_month) OVER (PARTITION BY gu.user_id ORDER BY cr.payment_month) AS previous_paid_month,
   LEAD(cr.payment_month) OVER (PARTITION BY gu.user_id ORDER BY cr.payment_month) AS next_paid_month,
   DATE_TRUNC('MONTH', cr.payment_month - INTERVAL '1' MONTH)::DATE AS previous_calendar_month,
   DATE_TRUNC('MONTH', cr.payment_month + INTERVAL '1' MONTH)::DATE AS next_calendar_month,
   cr.monthly_revenue AS revenue_amount_usd
FROM
   project.games_paid_users gu
LEFT JOIN
   ContractionCTE cr ON gu.user_id = cr.user_id
ORDER BY
   gu.user_id, cr.payment_month;

-----paid user count total
SELECT COUNT(DISTINCT user_id) AS unique_users_count
FROM project.games_paid_users;

--user count and mrr  by month  ---
   WITH MonthlyUserCounts AS (
    SELECT
        DATE_TRUNC('MONTH', payment_date)::DATE AS payment_month,
        COUNT(DISTINCT user_id) AS user_count,
        SUM(revenue_amount_usd) AS monthly_revenue
    FROM
        project.games_payments
    GROUP BY
       payment_month
    ORDER BY
      payment_month
)

SELECT
    payment_month,
    user_count,
    monthly_revenue
FROM
    MonthlyUserCounts;
  
   ---appu---   
WITH MonthlyUserCounts AS (
    SELECT
        DATE_TRUNC('MONTH', payment_date)::DATE AS payment_month,
        COUNT(DISTINCT user_id) AS user_count,
        SUM(revenue_amount_usd) AS monthly_revenue
    FROM
        project.games_payments
    GROUP BY
       payment_month
    ORDER BY
        payment_month
)

SELECT
    payment_month,
    ROUND(
        CASE
            WHEN user_count = 0
            THEN 0
            ELSE monthly_revenue / user_count
        END,
        2
    ) AS arppu
FROM
    MonthlyUserCounts;
   
 -------- new users and mrr   
  WITH FirstPurchaseDates AS (
    SELECT
        user_id,
        MIN(payment_date) AS first_purchase_date
    FROM
        project.games_payments
    GROUP BY
        user_id
)

SELECT
    DATE_TRUNC('MONTH', fpd.first_purchase_date)::DATE AS purchase_date,
    COUNT(DISTINCT fpd.user_id) AS new_paid_users,
    SUM(gp.revenue_amount_usd) AS new_mrr
FROM
    FirstPurchaseDates fpd
JOIN
    project.games_payments gp ON fpd.user_id = gp.user_id
WHERE
    DATE_TRUNC('MONTH', fpd.first_purchase_date)::DATE = DATE_TRUNC('MONTH', gp.payment_date)::DATE
GROUP BY
    DATE_TRUNC('MONTH', fpd.first_purchase_date)::DATE
ORDER BY
    DATE_TRUNC('MONTH', fpd.first_purchase_date)::DATE;


-----churn users
WITH RevenueLagLeadMonths AS (
    SELECT
        user_id,
        game_name,
        DATE_TRUNC('MONTH', payment_date)::DATE AS payment_date,
        DATE_TRUNC('MONTH', payment_date + INTERVAL '1' MONTH)::DATE AS next_calendar_month,
        DATE_TRUNC('MONTH', LEAD(payment_date) OVER (PARTITION BY user_id ORDER BY payment_date))::DATE AS next_paid_month
    FROM
        project.games_payments
      
)
SELECT
    next_calendar_month,
    COUNT(DISTINCT user_id) AS unique_users
FROM
    RevenueLagLeadMonths
WHERE
     next_paid_month IS NULL OR next_paid_month != next_calendar_month and payment_date != next_paid_month
GROUP BY
    next_calendar_month
ORDER BY
    next_calendar_month;
   
   
------churnusers rate ----  Churn Rate(June) = Churned Users(June) / Paid users(May)
   
WITH RevenueLagLeadMonths AS (
    SELECT
        user_id,
        game_name,
        DATE_TRUNC('MONTH', payment_date)::DATE AS payment_date,
        DATE_TRUNC('MONTH', payment_date + INTERVAL '1' MONTH)::DATE AS next_calendar_month,
        DATE_TRUNC('MONTH', LEAD(payment_date) OVER (PARTITION BY user_id ORDER BY payment_date))::DATE AS next_paid_month
    FROM
        project.games_payments
)

SELECT
    next_calendar_month AS payment_month,
    COUNT(DISTINCT CASE WHEN next_paid_month IS NULL OR (next_paid_month != next_calendar_month and payment_date != next_paid_month) THEN user_id END) AS churned_users,
    COUNT(DISTINCT user_id) AS current_month_user_count,
    TO_CHAR(
        CASE
            WHEN COUNT(DISTINCT user_id) = 0
            THEN 0
            ELSE
                COUNT(DISTINCT CASE WHEN next_paid_month IS NULL OR (next_paid_month != next_calendar_month and payment_date != next_paid_month) THEN user_id END)::FLOAT
                /
                COUNT(DISTINCT user_id) 
        END,
        '0.000'
    ) AS churn_ratio
FROM
    RevenueLagLeadMonths
GROUP BY
    next_calendar_month
ORDER BY
    next_calendar_month;


------churnusers rate ----  Churn Rate(June) = Churned Users(June) / Paid users(June)
WITH RevenueLagLeadMonths AS (
    SELECT
        user_id,
        game_name,
        DATE_TRUNC('MONTH', payment_date)::DATE AS payment_date,
        DATE_TRUNC('MONTH', payment_date + INTERVAL '1' MONTH)::DATE AS next_calendar_month,
        DATE_TRUNC('MONTH', LEAD(payment_date) OVER (PARTITION BY user_id ORDER BY payment_date))::DATE AS next_paid_month
    FROM
        project.games_payments
)

SELECT
    next_calendar_month AS payment_month,
    COUNT(DISTINCT CASE WHEN next_paid_month IS NULL OR (next_paid_month != next_calendar_month and payment_date != next_paid_month) THEN user_id END) AS churned_users,
    LEAD(COUNT(DISTINCT user_id)) OVER (ORDER BY next_calendar_month) AS next_month_user_count,
    TO_CHAR(
        CASE
            WHEN LAG(COUNT(DISTINCT user_id)) OVER (ORDER BY next_calendar_month) = 0
            THEN 0
            ELSE
                COUNT(DISTINCT CASE WHEN next_paid_month IS NULL OR (next_paid_month != next_calendar_month and payment_date != next_paid_month) THEN user_id END)::FLOAT
                /
                LEAD(COUNT(DISTINCT user_id)) OVER (ORDER BY next_calendar_month)
        END,
        '0.000'
    ) AS churn_ratio
FROM
    RevenueLagLeadMonths
GROUP BY
    next_calendar_month
ORDER BY
    next_calendar_month;


-----churn mrr
   
WITH RevenueLagLeadMonths AS (
    SELECT
        user_id,
        date(date_trunc('month', payment_date)) as payment_month,
        SUM(revenue_amount_usd) AS total_revenue
    FROM
        project.games_payments
    GROUP BY
        user_id, payment_month
),
NEXT AS(
SELECT
        *,
        date(payment_month + interval '1' month) as next_calendar_month,
        lead(payment_month) over(partition by user_id order by payment_month) as next_paid_month
    FROM
        RevenueLagLeadMonths
)
SELECT
    next_calendar_month AS payment_month,
    SUM(
        CASE
            WHEN next_paid_month IS NULL OR next_paid_month != next_calendar_month
            THEN total_revenue
            ELSE 0
        END
    ) AS churned_revenue
FROM
    NEXT
GROUP BY
    next_calendar_month
ORDER BY
    next_calendar_month;
   
 ----- churn mrr rate  Churn Rate(June) = Churned Users(June) / Paid users(May)
   
WITH RevenueLagLeadMonths AS (
    SELECT
        user_id,
        date(date_trunc('month', payment_date)) as payment_month,
        SUM(revenue_amount_usd) AS total_revenue
    FROM
        project.games_payments
    GROUP BY
        user_id, payment_month
),
NEXT AS (
    SELECT
        *,
        date(payment_month + interval '1' month) as next_calendar_month,
        lead(payment_month) over(partition by user_id order by payment_month) as next_paid_month
    FROM
        RevenueLagLeadMonths
)
SELECT
    next_calendar_month AS payment_month,
    SUM(
        CASE
            WHEN next_paid_month IS NULL OR next_paid_month != next_calendar_month
            THEN total_revenue
            ELSE 0
        END
    ) AS churned_revenue,
   SUM(total_revenue)  AS mrr_previous_month,
  ROUND(
        CASE
            WHEN LAG(SUM(total_revenue)) OVER (ORDER BY next_calendar_month) = 0
            THEN 0
            ELSE SUM(
                CASE
                    WHEN next_paid_month IS NULL OR next_paid_month != next_calendar_month
                    THEN total_revenue
                    ELSE 0
                END
            ) / SUM(total_revenue)
        END,
        3
    ) AS revenue_churn_rate
FROM
    NEXT
GROUP BY
    next_calendar_month
ORDER BY
    next_calendar_month;

   
----- churn mrr rate  Churn Rate(June) = Churned Users(June) / Paid users(June)
   
WITH RevenueLagLeadMonths AS (
    SELECT
        user_id,
        date(date_trunc('month', payment_date)) as payment_month,
        SUM(revenue_amount_usd) AS total_revenue
    FROM
        project.games_payments
    GROUP BY
        user_id, payment_month
),
NEXT AS (
    SELECT
        *,
        date(payment_month + interval '1' month) as next_calendar_month,
        lead(payment_month) over(partition by user_id order by payment_month) as next_paid_month
    FROM
        RevenueLagLeadMonths
)
SELECT
    next_calendar_month AS payment_month,
    SUM(
        CASE
            WHEN next_paid_month IS NULL OR next_paid_month != next_calendar_month
            THEN total_revenue
            ELSE 0
        END
    ) AS churned_revenue,
    lead(SUM(total_revenue)) OVER (ORDER BY next_calendar_month) AS mrr_previous_month,
  ROUND(
        CASE
            WHEN LAG(SUM(total_revenue)) OVER (ORDER BY next_calendar_month) = 0
            THEN 0
            ELSE SUM(
                CASE
                    WHEN next_paid_month IS NULL OR next_paid_month != next_calendar_month
                    THEN total_revenue
                    ELSE 0
                END
            ) / lead(SUM(total_revenue)) OVER (ORDER BY next_calendar_month)
        END,
        3
    ) AS revenue_churn_rate
FROM
    NEXT
GROUP BY
    next_calendar_month
ORDER BY
    next_calendar_month;
   
  
--expansion and contraction mrr 

WITH MonthlyRevenue AS (
    SELECT
        user_id,
        date(date_trunc('month', payment_date)) as payment_month,
        SUM(revenue_amount_usd) AS monthly_revenue
    FROM
        project.games_payments
    GROUP BY
        user_id, payment_month
),

ContractionCTE AS (
    SELECT
        user_id,
        payment_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (PARTITION BY user_id ORDER BY payment_month) AS previous_monthly_revenue,
        LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) AS previous_paid_month,
        lead(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) as next_paid_month,
        date(payment_month - interval '1' month) as previous_calendar_month
    FROM
        MonthlyRevenue
)

SELECT
    payment_month,
 ROUND(SUM(
        CASE
            WHEN previous_paid_month = previous_calendar_month and monthly_revenue > previous_monthly_revenue  
            THEN monthly_revenue
            ELSE 0
        END
    )) AS total_expansion,
ROUND(SUM(
        CASE
            WHEN previous_paid_month = previous_calendar_month and monthly_revenue < previous_monthly_revenue  
            THEN monthly_revenue
            ELSE 0
        END
    )) AS total_contraction
FROM
    ContractionCTE 
GROUP BY
    payment_month
ORDER BY
    payment_month;
    
 -----expansion and contraction user count
WITH MonthlyRevenue AS (
    SELECT
        user_id,
        date(date_trunc('month', payment_date)) as payment_month,
        SUM(revenue_amount_usd) AS monthly_revenue
    FROM
        project.games_payments
    GROUP BY
        user_id, payment_month
),

ContractionCTE AS (
    SELECT
        user_id,
        payment_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (PARTITION BY user_id ORDER BY payment_month) AS previous_monthly_revenue,
        LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) AS previous_paid_month,
        lead(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) as next_paid_month,
        date(payment_month - interval '1' month) as previous_calendar_month
    FROM
        MonthlyRevenue
)

SELECT
    payment_month,
    ROUND(COUNT(DISTINCT
        CASE
            WHEN previous_paid_month = previous_calendar_month and monthly_revenue > previous_monthly_revenue  
            THEN user_id
            ELSE NULL
        END
    )) AS total_expansion,
    ROUND(COUNT(DISTINCT
        CASE
            WHEN previous_paid_month = previous_calendar_month and monthly_revenue < previous_monthly_revenue  
            THEN user_id
            ELSE NULL
        END
    )) AS total_contraction
FROM
    ContractionCTE 
GROUP BY
    payment_month
ORDER BY
    payment_month;
 
   
 -----Customer LifeTime (LT) 
   

WITH RevenueLagLeadMonths AS (
    SELECT
        user_id,
        game_name,
        DATE_TRUNC('MONTH', payment_date)::DATE AS payment_date,
        DATE_TRUNC('MONTH', payment_date + INTERVAL '1' MONTH)::DATE AS next_calendar_month,
        DATE_TRUNC('MONTH', LEAD(payment_date) OVER (PARTITION BY user_id ORDER BY payment_date))::DATE AS next_paid_month
    FROM
        project.games_payments
)

SELECT
    next_calendar_month AS payment_month,
    TO_CHAR(
        CASE
            WHEN LAG(COUNT(DISTINCT user_id)) OVER (ORDER BY next_calendar_month) = 0
            THEN 0
            ELSE
                1 / (
                    COUNT(DISTINCT CASE WHEN next_paid_month IS NULL OR (next_paid_month != next_calendar_month and payment_date != next_paid_month) THEN user_id END)::FLOAT
                    /
                    LEAD(COUNT(DISTINCT user_id)) OVER (ORDER BY next_calendar_month)
                )
        END,
        '0.00'
    ) AS customer_lifetime
FROM
    RevenueLagLeadMonths
GROUP BY
    next_calendar_month
ORDER BY
    next_calendar_month;
   
   
----Customer LifeTime Value (LTV)  
WITH RevenueLagLeadMonths AS (
    SELECT
        user_id,
        revenue_amount_usd,
        DATE_TRUNC('MONTH', payment_date)::DATE AS payment_date,
        DATE_TRUNC('MONTH', payment_date + INTERVAL '1' MONTH)::DATE AS next_calendar_month,
        DATE_TRUNC('MONTH', LEAD(payment_date) OVER (PARTITION BY user_id ORDER BY payment_date))::DATE AS next_paid_month
    FROM
        project.games_payments
)

SELECT
    next_calendar_month AS payment_month,
    CASE
        WHEN LAG(COUNT(DISTINCT user_id)) OVER (ORDER BY next_calendar_month) = 0
        THEN 0
        ELSE
            1 / (
                COUNT(DISTINCT CASE WHEN next_paid_month IS NULL OR (next_paid_month != next_calendar_month and payment_date != next_paid_month) THEN user_id END)::FLOAT
                /
                LEAD(COUNT(DISTINCT user_id)) OVER (ORDER BY next_calendar_month)
            )
    END
    *
    CASE
        WHEN LEAD(COUNT(DISTINCT user_id)) OVER (ORDER BY next_calendar_month) = 0
        THEN 0
        ELSE
            LEAD(SUM(revenue_amount_usd)) OVER (ORDER BY next_calendar_month)::FLOAT
            /
            LEAD(COUNT(DISTINCT user_id)) OVER (ORDER BY next_calendar_month)
    END AS arppu_lifetime_product
FROM
    RevenueLagLeadMonths
GROUP BY
    next_calendar_month
ORDER BY
    next_calendar_month;





