
-- models/marts/dim_customers.sql
-- Grain : une ligne par client

{{ config(materialized='table') }}

SELECT
    customer_id,
    first_name,
    last_name,
    email,
    country
FROM {{ ref('stg_chinook__customer') }}
