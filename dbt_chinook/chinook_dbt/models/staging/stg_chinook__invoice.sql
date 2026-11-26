
SELECT 
           "InvoiceId" AS invoice_id,
           "CustomerId" AS customer_id,
           "InvoiceDate" AS invoice_date,
           TRIM("BillingCountry") AS billing_country,
           "Total" AS total
FROM {{ source('chinook', 'invoice') }}