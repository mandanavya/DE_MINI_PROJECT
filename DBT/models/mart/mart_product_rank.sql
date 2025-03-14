WITH product_revenue AS (
    SELECT
        t.product_id,
        SUM(t.revenue) AS total_revenue
    FROM {{ ref('stg_transactions') }} t
    GROUP BY t.product_id
),
ranked_products AS (
    SELECT
        r.product_id,
        r.total_revenue,
        RANK() OVER (ORDER BY r.total_revenue DESC) AS product_rank
    FROM product_revenue r
)

SELECT 
    *
FROM ranked_products