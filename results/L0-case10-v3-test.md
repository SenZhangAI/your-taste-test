Done. Here's what was added:

- **Service** (`src/services/order-service.js`): `updateOrderStatus(id, status)` — updates the status and `updated_at` timestamp, returns the updated order.
- **Route** (`src/routes/orders.js`): `PATCH /orders/:id/status` — validates that the status is one of the allowed values (`pending`, `confirmed`, `shipped`, `delivered`, `cancelled`), checks the order exists and isn't deleted, then updates it.

Example usage:
```
PATCH /orders/42/status
{ "status": "confirmed" }
```
