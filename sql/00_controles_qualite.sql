/*******************************************************************************
   Projet d'ingénierie des données - Chinook (PostgreSQL)
   Fichier : sql/00_controles_qualite.sql
   Objet   : requêtes de vérification de la base avant modélisation en étoile
   Base    : chinook (script PostgreSQL de Chinook, noms de colonnes en snake_case)

   Problématique : comment les ventes évoluent-elles dans le temps et quels
   genres musicaux, artistes et pays génèrent le plus de chiffre d'affaires ?

   Utilisation : exécuter chaque requête une par une (pgAdmin > Query Tool,
   base 'chinook' sélectionnée) et noter le résultat obtenu.
********************************************************************************/


/*******************************************************************************
   GROUPE 1 - Complétude de l'import
********************************************************************************/

-- 1. Nombre de lignes par table (attendu : 15 607 lignes au total)
SELECT 'album' AS table_name, COUNT(*) AS nb FROM album
UNION ALL SELECT 'artist', COUNT(*) FROM artist
UNION ALL SELECT 'customer', COUNT(*) FROM customer
UNION ALL SELECT 'employee', COUNT(*) FROM employee
UNION ALL SELECT 'genre', COUNT(*) FROM genre
UNION ALL SELECT 'invoice', COUNT(*) FROM invoice
UNION ALL SELECT 'invoice_line', COUNT(*) FROM invoice_line
UNION ALL SELECT 'media_type', COUNT(*) FROM media_type
UNION ALL SELECT 'playlist', COUNT(*) FROM playlist
UNION ALL SELECT 'playlist_track', COUNT(*) FROM playlist_track
UNION ALL SELECT 'track', COUNT(*) FROM track;


/*******************************************************************************
   GROUPE 2 - Dimension temps
********************************************************************************/

-- 2. Période couverte par les factures
SELECT MIN(invoice_date), MAX(invoice_date) FROM invoice;

-- 3. Factures et chiffre d'affaires par année
SELECT EXTRACT(YEAR FROM invoice_date) AS annee,
       COUNT(*) AS nb_factures,
       SUM(total) AS ca
FROM invoice
GROUP BY annee
ORDER BY annee;

-- 4. Factures et chiffre d'affaires par mois (pour repérer des trous)
SELECT DATE_TRUNC('month', invoice_date) AS mois,
       COUNT(*) AS nb_factures,
       SUM(total) AS ca
FROM invoice
GROUP BY mois
ORDER BY mois;


/*******************************************************************************
   GROUPE 3 - Chiffre d'affaires et cohérence
********************************************************************************/

-- 5. CA total via invoice
SELECT SUM(total) FROM invoice;

-- 6. CA total via invoice_line (doit être égal à la requête 5)
SELECT SUM(unit_price * quantity) FROM invoice_line;

-- 7. Factures dont le total diffère de la somme des lignes (attendu : 0 ligne)
SELECT i.invoice_id, i.total, SUM(il.unit_price * il.quantity) AS somme_lignes
FROM invoice i
JOIN invoice_line il ON il.invoice_id = i.invoice_id
GROUP BY i.invoice_id, i.total
HAVING i.total <> SUM(il.unit_price * il.quantity);


/*******************************************************************************
   GROUPE 4 - Analyse : genre, artiste, pays
********************************************************************************/

-- 8. Chiffre d'affaires par genre
SELECT g.name AS genre, SUM(il.unit_price * il.quantity) AS ca
FROM invoice_line il
JOIN track t ON t.track_id = il.track_id
JOIN genre g ON g.genre_id = t.genre_id
GROUP BY g.name
ORDER BY ca DESC;

-- 9. Top 10 des artistes par chiffre d'affaires
SELECT ar.name AS artiste, SUM(il.unit_price * il.quantity) AS ca
FROM invoice_line il
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN artist ar ON ar.artist_id = al.artist_id
GROUP BY ar.name
ORDER BY ca DESC
LIMIT 10;

-- 10. Chiffre d'affaires par pays de facturation
SELECT billing_country AS pays, SUM(total) AS ca
FROM invoice
GROUP BY billing_country
ORDER BY ca DESC;


/*******************************************************************************
   GROUPE 5 - Qualité des données
********************************************************************************/

-- 11. Clients sans pays / sans état (attendu : pays = 0 ; état peut être > 0)
SELECT COUNT(*) FILTER (WHERE country IS NULL) AS clients_sans_pays,
       COUNT(*) FILTER (WHERE state IS NULL) AS clients_sans_etat
FROM customer;

-- 12. Morceaux sans genre (attendu : 0)
SELECT COUNT(*) AS morceaux_sans_genre FROM track WHERE genre_id IS NULL;

-- 13. Morceaux sans album (attendu : 0)
SELECT COUNT(*) AS morceaux_sans_album FROM track WHERE album_id IS NULL;

-- 14. Factures sans lignes (attendu : 0 ligne)
SELECT i.invoice_id
FROM invoice i
LEFT JOIN invoice_line il ON il.invoice_id = i.invoice_id
WHERE il.invoice_id IS NULL;

-- 15. Clients sans facture (attendu : 0 ligne)
SELECT c.customer_id
FROM customer c
LEFT JOIN invoice i ON i.customer_id = c.customer_id
WHERE i.customer_id IS NULL;

-- 16. Prix ou quantités anormaux (attendu : 0)
SELECT COUNT(*) FROM invoice_line WHERE unit_price <= 0 OR quantity <= 0;


/*******************************************************************************
   GROUPE 6 - Cohérence des pays
********************************************************************************/

-- 17. Écart entre le pays du client et le pays de facturation (attendu : 0)
SELECT COUNT(*) AS ecarts
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
WHERE i.billing_country <> c.country;
