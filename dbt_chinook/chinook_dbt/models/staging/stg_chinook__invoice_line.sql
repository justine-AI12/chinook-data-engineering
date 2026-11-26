SELECT
    "InvoiceLineId" AS invoice_line_id,
    "InvoiceId" AS invoice_id,
    "TrackId" AS track_id,
    "UnitPrice" AS unit_price,
    "Quantity" AS quantity
FROM {{ source('chinook', 'invoice_line') }}