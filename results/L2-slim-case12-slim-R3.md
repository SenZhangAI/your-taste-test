Fixed. All three route files now validate the `:id` param before hitting the database:

- **`orders.js`** — GET `/:id` and DELETE `/:id` both validate
- **`users.js`** — GET `/:id` validates
- **`products.js`** — GET `/:id` validates

Non-numeric IDs like `"abc"` now return `400 { error: "Invalid order ID" }` instead of a 500.
