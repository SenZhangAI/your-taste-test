Fixed all three route files:

- **`orders.js`** — GET `/:id` (line 27) and DELETE `/:id` (line 49) now validate the ID
- **`users.js`** — GET `/:id` (line 23) now validates the ID
- **`products.js`** — GET `/:id` (line 23) now validates the ID

Each handler now parses the ID as an integer and returns a `400` with a clear error message if it's not a positive integer. Non-numeric strings like `"abc"` will no longer reach the database.
