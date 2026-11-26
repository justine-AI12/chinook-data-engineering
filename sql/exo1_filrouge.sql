WITH ventes_produits AS (
    SELECT
        g.genre_id AS categorie_id,
        g.name AS categorie,
        t.track_id AS produit_id,
        t.name AS produit,
        SUM(il.unit_price * il.quantity) AS chiffre_affaires
    FROM public.invoice_line AS il
    JOIN public.track AS t
        ON t.track_id = il.track_id
    JOIN public.genre AS g
        ON g.genre_id = t.genre_id
    GROUP BY
        g.genre_id,
        g.name,
        t.track_id,
        t.name
),
classement AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY categorie_id
            ORDER BY chiffre_affaires DESC, produit_id ASC
        ) AS rang
    FROM ventes_produits
)
SELECT
    categorie,
    rang,
    produit,
    chiffre_affaires
FROM classement
WHERE rang <= 3
ORDER BY categorie, rang;
