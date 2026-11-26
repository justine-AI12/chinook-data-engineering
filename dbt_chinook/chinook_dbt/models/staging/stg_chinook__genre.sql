SELECT
    "GenreId" AS genre_id,
    TRIM("Name") AS genre_name
FROM {{ source('chinook', 'genre') }}