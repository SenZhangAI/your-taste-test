Done. Here's what I changed:

- **`src/services/order-service.js`**: `listOrders` now does a `LEFT JOIN` on the `users` table via `orders.user_id = users.id`, selecting `users.name as user_name`. Used `leftJoin` so orders with missing/invalid user IDs still appear.
- **`src/routes/orders.js`**: Added `user: o.user_name || null` to each order object in the `GET /api/orders` response.

Each order in the list will now include a `"user"` field with the user's name (or `null` if the user doesn't exist).
