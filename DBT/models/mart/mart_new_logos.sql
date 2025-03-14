WITH first_purchase AS (
    SELECT 
        customer_id,
        MIN(payment_month) AS first_purchase_date
    FROM {{ ref('stg_transactions') }}
    GROUP BY customer_id
),

new_logos AS (
    SELECT
        customer_id,
        EXTRACT(YEAR FROM first_purchase_date) AS fiscal_year
    FROM first_purchase
)

SELECT 
    fiscal_year,
    COUNT(DISTINCT customer_id) AS new_logos
FROM new_logos
GROUP BY fiscal_year
ORDER BY fiscal_year