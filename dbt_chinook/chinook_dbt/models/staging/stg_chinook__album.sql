SELECT
    "AlbumId" AS album_id,
    TRIM("Title") AS album_title,
    "ArtistId" AS artist_id
FROM {{ source('chinook', 'album') }}