Done. Two changes:

1. **`src/services/order-service.js`** — `listOrders` now joins the `users` table to fetch `users.name as user_name`. Also qualified `orders.status` in the count query to avoid ambiguity from the join.

2. **`src/routes/orders.js`** — Added `user: o.user_name` to the response mapping.

Each order in the `GET /api/orders` response now includes a `user` field with the name of who placed it.
