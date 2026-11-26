
-- Test métier : le CA de la table de faits
-- doit correspondre au CA de la source brute.

WITH ca_source AS (
    SELECT
        SUM("UnitPrice" * "Quantity") AS total_ca
    FROM {{ source('chinook', 'invoice_line') }}
),

ca_mart AS (
    SELECT
        SUM(montant) AS total_ca
    FROM {{ ref('fct_sales') }}
)

SELECT
    s.total_ca AS ca_source,
    m.total_ca AS ca_mart
FROM ca_source AS s
CROSS JOIN ca_mart AS m
WHERE ABS(s.total_ca - m.total_ca) > 0.01
