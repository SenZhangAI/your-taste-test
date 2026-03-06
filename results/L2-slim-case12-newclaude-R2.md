Fixed all three route files. Each `/:id` endpoint now validates the ID parameter with `parseInt` + `isNaN` check, returning a `400` with a descriptive error instead of letting a non-numeric value reach the database.

Changes:
- **`orders.js`** — `GET /:id` and `DELETE /:id` (lines 27, 49)
- **`users.js`** — `GET /:id` (line 22)
- **`products.js`** — `GET /:id` (line 22)

`GET /api/orders/abc` will now return `400 { "error": "Invalid order ID" }`.
