Done. Changes:

- **`order-service.js`**: `listOrders` now JOINs the `users` table to fetch `users.name as user_name`. The count query is also qualified with `orders.status` to avoid ambiguity.
- **`routes/orders.js`**: The list response now includes `user: o.user_name` for each order.
