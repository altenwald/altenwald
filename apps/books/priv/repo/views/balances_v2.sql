SELECT "id", "type", "items", "amount", "year", "month", "name", "book_id", "inserted_at", "updated_at"
FROM (
  (
    SELECT "id", 'income' AS "type", "items", "amount", "year", "month", "source" AS "name", "book_id", "inserted_at", "updated_at"
    FROM "income"
  ) UNION (
    SELECT "id", 'outcome' AS "type", 0 AS "items", -"amount", "year", "month", "target" AS "name", NULL as "book_id", "inserted_at", "updated_at"
    FROM "outcome"
  )
) AS balances
ORDER BY "year" DESC, "month" DESC, "name" ASC
