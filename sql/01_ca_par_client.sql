/** Requête SQL 1: chiffre d'affaires par client **/
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(i.total) AS chiffre_affaires
FROM customer c
JOIN invoice i
    ON c.customer_id = i.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY chiffre_affaires DESC;