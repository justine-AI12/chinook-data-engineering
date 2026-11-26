SELECT
    "PlaylistId" AS playlist_id,
    "TrackId" AS track_id
FROM {{ source('chinook', 'playlist_track') }}