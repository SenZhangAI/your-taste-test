Done. Here's what changed:

1. **`src/services/order-service.js`** — `listOrders` now joins the `users` table to fetch `users.name as user_name` alongside each order.

2. **`src/routes/orders.js`** — The `GET /api/orders` response now includes a `user` field with the user's name for each order.

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
