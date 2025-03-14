WITH raw_transactions AS (
    SELECT * FROM {{ source('food_delivery', 'transaction_details') }}
)

SELECT 
    CAST(customer_id AS INT) AS customer_id,
    TRIM(product_id) AS product_id,
    CAST(payment_month AS DATE) AS payment_month,
    CAST(revenue_type AS INT) AS revenue_type,
    COALESCE(CAST(revenue AS FLOAT), 0) AS revenue,
    CAST(quantity AS INT) AS quantity,
    dimension_1,
    dimension_2,
    dimension_3,
    dimension_4,
    dimension_5,
    dimension_6,
    dimension_7,
    dimension_8,
    dimension_9,
    dimension_10,
    companies
FROM raw_transactions
WHERE customer_id IS NOT NULL 
AND product_id IS NOT NULL