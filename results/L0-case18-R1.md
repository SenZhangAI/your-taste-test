Done. Here's what changed:

- **`src/services/order-service.js:10-14`** — `listOrders` now joins the `users` table on `user_id` and selects `users.name as user_name`. The `where` and `orderBy` clauses are qualified with `orders.` to avoid ambiguity from the join.

- **`src/routes/orders.js:15`** — The GET `/api/orders` response now includes a `user` field with the user's name for each order.

Each order in the response will now look like:
```json
{
  "id": 1,
  "user": "Jane Doe",
  "product": "Widget",
  "quantity": 2,
  "total": "$19.98",
  "status": "pending",
  "date": "..."
}
```
