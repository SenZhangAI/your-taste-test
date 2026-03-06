Fixed all three route files. Each `/:id` endpoint now validates the parameter is a positive integer before hitting the database:

- **`orders.js`** — `GET /:id` and `DELETE /:id` (lines 27-30, 52-55)
- **`users.js`** — `GET /:id` (lines 23-26)
- **`products.js`** — `GET /:id` (lines 23-26)

Non-numeric IDs like `abc` now return `400 { error: "Invalid order ID" }` instead of a 500.
