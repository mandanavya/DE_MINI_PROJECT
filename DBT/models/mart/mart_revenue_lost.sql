WITH filtered_transactions AS (
    SELECT
        t.customer_id,
        t.product_id,
        p.product_sub_family,
        p.product_family,
        t.payment_month,
        t.revenue,
        t.quantity,
        LAG(t.revenue) OVER (PARTITION BY t.customer_id, p.product_sub_family ORDER BY t.payment_month) AS previous_revenue,
        LAG(t.quantity) OVER (PARTITION BY t.customer_id, t.product_id ORDER BY t.payment_month) AS previous_quantity,
        MAX(t.payment_month) OVER (PARTITION BY t.customer_id) AS last_purchase_month,
        MIN(t.payment_month) OVER (PARTITION BY t.customer_id) AS first_purchase_month
    FROM {{ ref('stg_transactions') }} t
    JOIN {{ ref('stg_products') }} p
      ON t.product_id = p.product_id
    WHERE t.revenue_type = 1 
),
product_churn AS (
    SELECT
        customer_id,
        product_sub_family,
        product_family,
        COUNT(DISTINCT product_id) AS churned_products
    FROM filtered_transactions
    WHERE DATEADD(MONTH, 1, last_purchase_month) < (SELECT MAX(payment_month) FROM {{ ref('stg_transactions') }})
    GROUP BY customer_id, product_sub_family, product_family
),
customer_churn AS (
    SELECT
        customer_id,
        CASE
            WHEN MAX(payment_month) < (SELECT MAX(payment_month) FROM {{ ref('stg_transactions') }}) THEN 1
            ELSE 0
        END AS is_churned
    FROM filtered_transactions
    GROUP BY customer_id
),
downsell AS (
    SELECT
        customer_id,
        product_sub_family,
        COUNT(DISTINCT product_id) AS total_downsells
    FROM filtered_transactions
    WHERE revenue < previous_revenue 
      AND previous_revenue IS NOT NULL
    GROUP BY customer_id, product_sub_family
),
downgrade AS (
    SELECT
        customer_id,
        product_id,
        product_sub_family,
        COUNT(DISTINCT product_id) AS total_downgrades
    FROM filtered_transactions
    WHERE quantity < previous_quantity
      AND previous_quantity IS NOT NULL
    GROUP BY customer_id, product_id, product_sub_family
),
monthly_revenue AS (
    SELECT
        customer_id,
        SUM(revenue) AS total_revenue
    FROM filtered_transactions
    GROUP BY customer_id
),
combined_metrics AS (
    SELECT
        c.customer_id,
        c.customer_name,
        COALESCE(pc.churned_products, 0) AS churned_products,
        COALESCE(cc.is_churned, 0) AS is_churned,
        COALESCE(ds.total_downsells, 0) AS total_downsells,
        COALESCE(dg.total_downgrades, 0) AS total_downgrades,
        ds.product_sub_family,
        COALESCE(mr.total_revenue, 0) AS total_revenue
    FROM {{ ref('stg_customers') }} c
    LEFT JOIN product_churn pc
      ON c.customer_id = pc.customer_id
    LEFT JOIN customer_churn cc
      ON c.customer_id = cc.customer_id
    LEFT JOIN downsell ds
      ON c.customer_id = ds.customer_id
    LEFT JOIN downgrade dg
      ON c.customer_id = dg.customer_id AND ds.product_sub_family = dg.product_sub_family
    LEFT JOIN monthly_revenue mr
      ON c.customer_id = mr.customer_id 
)
SELECT *
FROM combined_metrics
ORDER BY total_downsells DESC, total_downgrades DESC, churned_products DESC