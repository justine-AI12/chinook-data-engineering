
-- models/intermediate/int_chinook__tracks_enrichis.sql

-- Grain : une ligne par morceau musical

SELECT
    t.track_id,
    t.track_name,
    a.album_title,
    ar.artist_name,
    g.genre_name

FROM {{ ref('stg_chinook__track') }} AS t

LEFT JOIN {{ ref('stg_chinook__album') }} AS a
    ON t.album_id = a.album_id

LEFT JOIN {{ ref('stg_chinook__artist') }} AS ar
    ON a.artist_id = ar.artist_id

LEFT JOIN {{ ref('stg_chinook__genre') }} AS g
    ON t.genre_id = g.genre_id
