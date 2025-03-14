WITH customer_activity AS (
    SELECT 
        customer_id, 
        MIN(payment_month) AS first_purchase, 
        MAX(payment_month) AS last_purchase
    FROM {{ ref('stg_transactions') }}
    GROUP BY customer_id
)

SELECT 
    t.payment_month,
    COUNT(DISTINCT CASE WHEN c.first_purchase = t.payment_month THEN t.customer_id END) AS new_customers,
    COUNT(DISTINCT CASE WHEN c.last_purchase = t.payment_month THEN t.customer_id END) AS churned_customers
FROM {{ ref('stg_transactions') }} t
JOIN customer_activity c USING (customer_id)
GROUP BY t.payment_month
ORDER BY t.payment_month