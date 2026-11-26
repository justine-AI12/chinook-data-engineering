
-- models/staging/stg_chinook__customer.sql

SELECT
    "CustomerId" AS customer_id,
    TRIM("FirstName") AS first_name,
    TRIM("LastName") AS last_name,
    LOWER(TRIM("Email")) AS email,
    TRIM("Country") AS country
FROM {{ source('chinook', 'customer') }}
