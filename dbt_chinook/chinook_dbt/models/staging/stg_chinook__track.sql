SELECT
    "TrackId" AS track_id,
    TRIM("Name") AS track_name,
    "AlbumId" AS album_id,
    "MediaTypeId" AS media_type_id,
    "GenreId" AS genre_id,
    TRIM("Composer") AS composer,
    "Milliseconds" AS milliseconds,
    "Bytes" AS bytes,
    "UnitPrice" AS unit_price
FROM {{ source('chinook', 'track') }}