
-- models/intermediate/int_chinook__ventes_enrichis.sql

-- Grain : une ligne par ligne de facture

SELECT
    il.invoice_line_id,
    i.invoice_id,
    i.customer_id,
    i.invoice_date,
    il.track_id,
    t.track_name,
    t.genre_name,
    il.quantity,
    il.unit_price,
    il.unit_price * il.quantity AS montant_ligne

FROM {{ ref('stg_chinook__invoice_line') }} AS il

INNER JOIN {{ ref('stg_chinook__invoice') }} AS i
    ON il.invoice_id = i.invoice_id

LEFT JOIN {{ ref('int_chinook__tracks_enrichis') }} AS t
    ON il.track_id = t.track_id
