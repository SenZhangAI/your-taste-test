Done. Two changes:

1. **`src/services/order-service.js:10-14`** — `listOrders` now joins `users` on `user_id` and selects `users.name as user_name`
2. **`src/routes/orders.js:19`** — the GET `/api/orders` response includes `user: o.user_name` for each order

Note: this uses an inner join, so orders with an invalid/missing `user_id` would be excluded. If orphaned orders are possible, this should be a left join instead.
