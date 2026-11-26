
-- models/marts/dim_tracks.sql
-- Grain : une ligne par morceau musical

{{ config(materialized='table') }}

SELECT
    track_id,
    track_name,
    album_title,
    artist_name,
    genre_name
FROM {{ ref('int_chinook__tracks_enrichis') }}
