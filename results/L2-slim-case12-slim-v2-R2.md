Fixed all three route files:

- **`orders.js`** — validated `:id` on both `GET /:id` and `DELETE /:id`
- **`users.js`** — validated `:id` on `GET /:id`
- **`products.js`** — validated `:id` on `GET /:id`

Non-numeric IDs now return `400 { error: "Invalid order/user/product ID" }` instead of hitting the DB and causing a 500.
