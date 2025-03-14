WITH raw_product AS (
    SELECT * FROM {{ source('food_delivery', 'products') }}
)
SELECT DISTINCT 
    UPPER(TRIM(product_id)) AS product_id,
    UPPER(TRIM(product_family)) AS product_family,
    UPPER(TRIM(product_sub_family)) AS product_sub_family
FROM raw_product
WHERE product_id IS NOT NULL