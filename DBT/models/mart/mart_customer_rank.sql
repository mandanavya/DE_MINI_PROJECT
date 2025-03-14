WITH customer_map AS (
    SELECT 
        customer_id, 
        region
    FROM {{ source('food_delivery', 'country_region') }}
)

SELECT 
    c.customer_id, 
    c.customer_name, 
    cm.region,
    SUM(t.revenue) AS total_revenue,
    RANK() OVER (ORDER BY SUM(t.revenue) DESC) AS revenue_rank,
FROM {{ ref('stg_transactions') }} t
JOIN {{ ref('stg_customers') }} c ON t.customer_id = c.customer_id
JOIN customer_map cm ON c.customer_id = cm.customer_id
GROUP BY c.customer_id, c.customer_name, cm.region
ORDER BY revenue_rank