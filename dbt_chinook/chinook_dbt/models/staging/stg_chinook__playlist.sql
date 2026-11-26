SELECT
    "PlaylistId" AS playlist_id,
    TRIM("Name") AS playlist_name
FROM {{ source('chinook', 'playlist') }}