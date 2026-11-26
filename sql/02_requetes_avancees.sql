-- CHINOOK — JOUR 2 : SQL AVANCE (PostgreSQL)
-- Base cible : chinook ; tables du schéma public.
-- Les résultats dépendent du contenu de la base. Exécuter chaque requête dans pgAdmin.
-- Les montants utilisent les lignes de facture (prix unitaire * quantité).

-- Q1 : LAG — évolution mensuelle du chiffre d'affaires
-- Besoin métier : comparer chaque mois au mois précédent (dans les mois où il y a des ventes).
WITH ca_mensuel AS (
    SELECT DATE_TRUNC('month', i.invoice_date)::date AS mois,
           SUM(il.unit_price * il.quantity) AS ca
    FROM public.invoice AS i
    JOIN public.invoice_line AS il ON il.invoice_id = i.invoice_id
    GROUP BY 1
), comparaison AS (
    SELECT mois, ca,
           LAG(ca) OVER (ORDER BY mois) AS ca_mois_precedent
    FROM ca_mensuel
)
SELECT mois, ROUND(ca, 2) AS ca_mensuel,
       ROUND(ca_mois_precedent, 2) AS ca_mois_precedent,
       ROUND(100 * (ca - ca_mois_precedent)
             / NULLIF(ca_mois_precedent, 0), 2) AS evolution_pct
FROM comparaison
ORDER BY mois;

-- Q2 : RANK et DENSE_RANK — classement des clients selon leurs dépenses
-- RANK saute des rangs en cas d'ex aequo ; DENSE_RANK ne les saute pas.
WITH depenses AS (
    SELECT c.customer_id, c.first_name, c.last_name,
           COALESCE(SUM(i.total), 0) AS ca_client
    FROM public.customer AS c
    LEFT JOIN public.invoice AS i ON i.customer_id = c.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT customer_id, first_name, last_name,
       ROUND(ca_client, 2) AS ca_client,
       RANK() OVER (ORDER BY ca_client DESC) AS rang,
       DENSE_RANK() OVER (ORDER BY ca_client DESC) AS rang_dense
FROM depenses
ORDER BY ca_client DESC, customer_id;

-- Q3 : NTILE(4) — quatre groupes de clients selon leur dépense totale
WITH depenses AS (
    SELECT c.customer_id, c.first_name, c.last_name,
           COALESCE(SUM(i.total), 0) AS ca_client
    FROM public.customer AS c
    LEFT JOIN public.invoice AS i ON i.customer_id = c.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT customer_id, first_name, last_name,
       ROUND(ca_client, 2) AS ca_client,
       NTILE(4) OVER (ORDER BY ca_client DESC, customer_id) AS quartile_depense
FROM depenses
ORDER BY quartile_depense, ca_client DESC, customer_id;

-- Q4 : fenêtre glissante ROWS BETWEEN — CA cumulé sur les 3 mois observés
-- Attention : trois lignes mensuelles, pas nécessairement trois mois calendaires
-- si des mois sans vente existent dans les données.
WITH ca_mensuel AS (
    SELECT DATE_TRUNC('month', i.invoice_date)::date AS mois,
           SUM(il.unit_price * il.quantity) AS ca
    FROM public.invoice AS i
    JOIN public.invoice_line AS il ON il.invoice_id = i.invoice_id
    GROUP BY 1
)
SELECT mois, ROUND(ca, 2) AS ca_mensuel,
       ROUND(SUM(ca) OVER (
           ORDER BY mois
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS ca_mobile_3_mois_observes
FROM ca_mensuel
ORDER BY mois;

-- Q5 : WITH RECURSIVE — hiérarchie des employés via reports_to
-- Le tableau part des salariés sans manager et descend dans l'organigramme.
WITH RECURSIVE organigramme AS (
    SELECT e.employee_id, e.first_name, e.last_name,
           e.title, e.reports_to, 0 AS niveau,
           ARRAY[e.employee_id] AS chemin_ids
    FROM public.employee AS e
    WHERE e.reports_to IS NULL
    UNION ALL
    SELECT e.employee_id, e.first_name, e.last_name,
           e.title, e.reports_to, o.niveau + 1,
           o.chemin_ids || e.employee_id
    FROM public.employee AS e
    JOIN organigramme AS o ON e.reports_to = o.employee_id
    WHERE NOT (e.employee_id = ANY(o.chemin_ids))
)
SELECT niveau, employee_id, reports_to,
       REPEAT('  ', niveau) || first_name || ' ' || last_name AS employe,
       title, chemin_ids
FROM organigramme
ORDER BY chemin_ids;

-- Q6 : CTE enchaînées + ROW_NUMBER — top 3 des morceaux par genre
-- Variante autonome du travail déjà présent dans sql/exo1_filrouge.sql.
WITH ventes_par_morceau AS (
    SELECT g.genre_id, g.name AS genre,
           t.track_id, t.name AS morceau,
           SUM(il.unit_price * il.quantity) AS ca
    FROM public.invoice_line AS il
    JOIN public.track AS t ON t.track_id = il.track_id
    JOIN public.genre AS g ON g.genre_id = t.genre_id
    GROUP BY g.genre_id, g.name, t.track_id, t.name
), classement AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY genre_id ORDER BY ca DESC, track_id
    ) AS position
    FROM ventes_par_morceau
)
SELECT genre, position, morceau, ROUND(ca, 2) AS chiffre_affaires
FROM classement
WHERE position <= 3
ORDER BY genre, position;
