WITH product_purchase_history AS (
    SELECT 
        t.customer_id,
        t.product_id,
        t.payment_month,
        COALESCE(LAG(t.product_id) OVER (
            PARTITION BY t.customer_id ORDER BY t.payment_month
        ), 'NEW') AS previous_product
    FROM {{ ref('stg_transactions') }} t
),
cross_sell_analysis AS (
    SELECT 
        previous_product AS cross_sell_from,
        product_id AS cross_sell_to,
        COUNT(*) AS cross_sell_count
    FROM product_purchase_history
    WHERE previous_product <> product_id
    GROUP BY previous_product, product_id
    ORDER BY cross_sell_count DESC
),
customer_churn AS (
    SELECT
        customer_id,
        COUNT(DISTINCT product_id) AS product_churn_count
    FROM product_purchase_history
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.customer_name,
    cc.product_churn_count,
    cs.cross_sell_count
FROM customer_churn cc
LEFT JOIN (
    SELECT 
        customer_id,
        COUNT(*) AS cross_sell_count
    FROM product_purchase_history
    WHERE previous_product <> product_id
    GROUP BY customer_id
) cs ON cc.customer_id = cs.customer_id
JOIN {{ ref('stg_customers') }} c ON cc.customer_id = c.customer_id
ORDER BY cs.cross_sell_count DESC, cc.product_churn_count DESC