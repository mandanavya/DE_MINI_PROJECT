WITH cleaned_data AS (
    SELECT
        TRIM(company) AS company,
        CAST(customer_id AS INTEGER) AS customer_id,
        TRIM(customername) AS customer_name
    FROM {{ source('food_delivery', 'customers') }}
    WHERE customer_id IS NOT NULL AND customername IS NOT NULL
),

verified_names AS (
    SELECT
        customer_id,
        INITCAP(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(customer_name, '[^a-zA-Z\s]', ' '), '\d+', ''), '\s+', ' ')) AS customer_name,
        company,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_name) AS row_num
    FROM cleaned_data
)

SELECT
    customer_id,
    customer_name,
    company
FROM verified_names
WHERE row_num = 1
ORDER BY customer_id