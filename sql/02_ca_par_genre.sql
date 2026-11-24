/** Requête 2 : chiffre d'affaires par genre musical **/
SELECT
    g.name AS genre_musical,
    SUM(il.unit_price * il.quantity) AS chiffre_affaires
FROM invoice_line il
JOIN track t
    ON il.track_id = t.track_id
JOIN genre g
    ON t.genre_id = g.genre_id
GROUP BY g.genre_id, g.name
ORDER BY chiffre_affaires DESC;