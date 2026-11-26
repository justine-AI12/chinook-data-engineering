-- ============================================================
-- CHINOOK — 3 QUESTIONS METIER SUR LE SCHEMA EN ETOILE DBT
-- Base : chinook_database_dbt | Schema : dbt_dev
-- Tables : fct_sales, dim_tracks, dim_customers, dim_date
-- A executer dans le Query Tool de pgAdmin.
-- ============================================================

-- QUESTION 1 : Quels genres musicaux generent le plus de chiffre d'affaires ?
-- Grain de regroupement : un genre musical.
SELECT
    COALESCE(t.genre_name, 'Genre inconnu') AS genre_musical,
    SUM(f.quantity) AS morceaux_vendus,
    ROUND(SUM(f.montant)::numeric, 2) AS chiffre_affaires,
    ROUND(
        100.0 * SUM(f.montant)
        / NULLIF(SUM(SUM(f.montant)) OVER (), 0),
        2
    ) AS part_du_ca_pct
FROM dbt_dev.fct_sales AS f
INNER JOIN dbt_dev.dim_tracks AS t
    ON f.track_id = t.track_id
GROUP BY COALESCE(t.genre_name, 'Genre inconnu')
ORDER BY chiffre_affaires DESC, genre_musical;

-- QUESTION 2 : Quels sont les 10 clients qui depensent le plus ?
-- Grain de regroupement : un client.
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.country,
    COUNT(DISTINCT f.invoice_id) AS nombre_factures,
    SUM(f.quantity) AS morceaux_achetes,
    ROUND(SUM(f.montant)::numeric, 2) AS chiffre_affaires
FROM dbt_dev.fct_sales AS f
INNER JOIN dbt_dev.dim_customers AS c
    ON f.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country
ORDER BY chiffre_affaires DESC, c.customer_id
LIMIT 10;

-- QUESTION 3 : Comment evoluent les ventes mois par mois ?
-- Grain de regroupement : un mois civil.
WITH ventes_mensuelles AS (
    SELECT
        DATE_TRUNC('month', d.date_jour)::date AS mois,
        COUNT(DISTINCT f.invoice_id) AS nombre_factures,
        SUM(f.quantity) AS morceaux_vendus,
        SUM(f.montant) AS chiffre_affaires
    FROM dbt_dev.fct_sales AS f
    INNER JOIN dbt_dev.dim_date AS d
        ON f.date_key = d.date_key
    GROUP BY DATE_TRUNC('month', d.date_jour)::date
),
evolution AS (
    SELECT
        mois,
        nombre_factures,
        morceaux_vendus,
        chiffre_affaires,
        LAG(chiffre_affaires) OVER (ORDER BY mois) AS ca_mois_precedent
    FROM ventes_mensuelles
)
SELECT
    TO_CHAR(mois, 'YYYY-MM') AS mois,
    nombre_factures,
    morceaux_vendus,
    ROUND(chiffre_affaires::numeric, 2) AS chiffre_affaires,
    ROUND(ca_mois_precedent::numeric, 2) AS ca_mois_precedent,
    ROUND(
        100.0 * (chiffre_affaires - ca_mois_precedent)
        / NULLIF(ca_mois_precedent, 0),
        2
    ) AS evolution_pct
FROM evolution
ORDER BY mois;
