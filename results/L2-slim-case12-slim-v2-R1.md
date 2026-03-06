Fixed all three route files. `GET /api/orders/abc` will now return 400 `{"error": "Invalid order ID"}` instead of a 500.

The same validation was added to every `:id` route across the codebase:
- **orders.js** — `GET /:id` and `DELETE /:id`
- **users.js** — `GET /:id`
- **products.js** — `GET /:id`

Each validates that the ID is a positive integer before hitting the DB.
