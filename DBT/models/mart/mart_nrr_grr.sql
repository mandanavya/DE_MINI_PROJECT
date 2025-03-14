
WITH revenue_per_month AS (
 
    SELECT 
        customer_id,
        DATE_TRUNC('month', payment_month) AS month,
        SUM(revenue) AS total_revenue
    FROM {{ source('food_delivery', 'transaction_details') }}
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, month
),
customer_revenue_changes AS (
    SELECT 
        customer_id,
        month,
        total_revenue,
        LAG(total_revenue) OVER (PARTITION BY customer_id ORDER BY month) AS prev_revenue,
        CASE 
            WHEN LAG(total_revenue) OVER (PARTITION BY customer_id ORDER BY month) > 0 
                 AND total_revenue = 0 THEN 1 ELSE 0 
        END AS churned_customer,
        GREATEST(total_revenue - COALESCE(prev_revenue, 0), 0) AS upsell_expansion,
        GREATEST(COALESCE(prev_revenue, 0) - total_revenue, 0) AS contraction_revenue
    FROM revenue_per_month
),
revenue_metrics AS (

    SELECT 
        month,
        SUM(COALESCE(prev_revenue, 0)) AS starting_revenue,
        SUM(upsell_expansion) AS expansion_revenue,
        SUM(contraction_revenue) AS contraction_revenue,
        SUM(churned_customer * COALESCE(prev_revenue, 0)) AS churned_revenue
    FROM customer_revenue_changes
    GROUP BY month
)
SELECT 
    month,
    starting_revenue,
    expansion_revenue,
    contraction_revenue,
    churned_revenue,
    -- Net Revenue Retention (NRR) = (Starting Revenue + Expansion - Contraction - Churn) / Starting Revenue
    ROUND((starting_revenue + expansion_revenue - contraction_revenue - churned_revenue) / NULLIF(starting_revenue, 0), 4) AS NRR,
    -- Gross Revenue Retention (GRR) = (Starting Revenue - Churn) / Starting Revenue
    ROUND((starting_revenue - churned_revenue) / NULLIF(starting_revenue, 0), 4) AS GRR
FROM revenue_metrics