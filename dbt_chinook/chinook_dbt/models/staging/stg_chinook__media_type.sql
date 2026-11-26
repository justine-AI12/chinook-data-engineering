SELECT
    "MediaTypeId" AS media_type_id,
    TRIM("Name") AS media_type_name
FROM {{ source('chinook', 'media_type') }}