-- Passage à l'échelle : copies _big (4 500 duplications)
CREATE TABLE invoice_big AS
SELECT i.invoice_id + g * 1000 AS invoice_id,
       i.customer_id,
       i.invoice_date + g * INTERVAL '1 day' AS invoice_date,
       i.billing_country,
       i.total
FROM invoice i
CROSS JOIN generate_series(0, 4499) AS g;

CREATE TABLE invoice_line_big AS
SELECT il.invoice_line_id + g * 10000 AS invoice_line_id,
       il.invoice_id + g * 1000 AS invoice_id,
       il.track_id,
       il.unit_price,
       il.quantity
FROM invoice_line il
CROSS JOIN generate_series(0, 4499) AS g;

VACUUM ANALYZE invoice_big;
VACUUM ANALYZE invoice_line_big;
