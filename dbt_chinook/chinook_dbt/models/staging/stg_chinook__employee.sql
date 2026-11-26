SELECT
    "EmployeeId" AS employee_id,
    TRIM("FirstName") AS first_name,
    TRIM("LastName") AS last_name,
    TRIM("Title") AS job_title,
    "ReportsTo" AS reports_to,
    "BirthDate" AS birth_date,
    "HireDate" AS hire_date,
    TRIM("Address") AS address,
    TRIM("City") AS city,
    TRIM("State") AS state,
    TRIM("Country") AS country,
    TRIM("PostalCode") AS postal_code,
    TRIM("Phone") AS phone,
    TRIM("Fax") AS fax,
    LOWER(TRIM("Email")) AS email
FROM {{ source('chinook', 'employee') }}