-- Mesures EXPLAIN (ANALYZE, BUFFERS) sur les tables _big (10 080 000 lignes dans invoice_line_big)
-- À lancer deux fois : d'abord AVANT 03_indexation.sql, puis APRÈS.

-- Q1 : requête sélective sur invoice_big (31 500 lignes)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM invoice_big
WHERE customer_id = 5;

-- Q2 : jointure + agrégat sur toute la table
EXPLAIN (ANALYZE, BUFFERS)
SELECT i.billing_country, SUM(il.unit_price * il.quantity) AS ca
FROM invoice_big i
JOIN invoice_line_big il ON il.invoice_id = i.invoice_id
GROUP BY i.billing_country;

-- Q3 : très sélective sur invoice_line_big (14 lignes)
EXPLAIN (ANALYZE, BUFFERS)
SELECT il.* FROM invoice_line_big il
WHERE il.invoice_id = 1005;

-- Q4 : Q2 filtrée sur un client (environ 31 500 factures)
EXPLAIN (ANALYZE, BUFFERS)
SELECT i.billing_country, SUM(il.unit_price * il.quantity) AS ca
FROM invoice_big i
JOIN invoice_line_big il ON il.invoice_id = i.invoice_id
WHERE i.customer_id = 5
GROUP BY i.billing_country;
