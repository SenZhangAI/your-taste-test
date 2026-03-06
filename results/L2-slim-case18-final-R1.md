Done. Changes:

- **`listOrders`** — joins `users` table, selects `users.name as user_name`
- **`getOrder`** — same join so the single-order endpoint also gets the user name
- **GET `/api/orders`** response — added `user` field from `o.user_name`

The `GET /:id` endpoint already spreads the full order object, so `user_name` will appear there automatically.
