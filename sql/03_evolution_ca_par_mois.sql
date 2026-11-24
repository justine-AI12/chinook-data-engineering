/** Requ^te 3: Evolution du chiffre d'affaires par mois **/
SELECT
    DATE_TRUNC('month', i.invoice_date) AS mois,
    SUM(il.unit_price * il.quantity) AS chiffre_affaires
FROM invoice i
JOIN invoice_line il
    ON i.invoice_id = il.invoice_id
GROUP BY DATE_TRUNC('month', i.invoice_date)
ORDER BY mois;