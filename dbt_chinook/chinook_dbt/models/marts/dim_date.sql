
-- models/marts/dim_date.sql
-- Grain : une ligne par date de vente distincte

{{ config(materialized='table') }}

SELECT DISTINCT
    CAST(TO_CHAR(invoice_date, 'YYYYMMDD') AS INTEGER) AS date_key,
    CAST(invoice_date AS DATE) AS date_jour,
    EXTRACT(YEAR FROM invoice_date)::INTEGER AS annee,
    EXTRACT(QUARTER FROM invoice_date)::INTEGER AS trimestre,
    EXTRACT(MONTH FROM invoice_date)::INTEGER AS mois,
    EXTRACT(ISODOW FROM invoice_date)::INTEGER AS jour_semaine,
    EXTRACT(ISODOW FROM invoice_date) IN (6, 7) AS est_weekend
FROM {{ ref('int_chinook__ventes_enrichis') }}
WHERE invoice_date IS NOT NULL
