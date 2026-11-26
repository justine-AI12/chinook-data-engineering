
-- models/marts/fct_sales.sql
-- Grain : une ligne par ligne de facture

{{ config(materialized='table') }}

SELECT
    invoice_line_id,
    invoice_id,
    customer_id,
    track_id,
    CAST(TO_CHAR(invoice_date, 'YYYYMMDD') AS INTEGER) AS date_key,
    quantity,
    unit_price,
    montant_ligne AS montant
FROM {{ ref('int_chinook__ventes_enrichis') }}
