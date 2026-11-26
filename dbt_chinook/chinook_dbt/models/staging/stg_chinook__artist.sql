SELECT
    "ArtistId" AS artist_id,
    TRIM("Name") AS artist_name
FROM {{ source('chinook', 'artist') }}