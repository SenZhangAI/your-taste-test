Done. Here's what was added:

**Service** (`src/services/order-service.js`):
- `updateOrderStatus(id, status)` — validates the status is one of `pending`, `confirmed`, or `cancelled`, then updates the order and returns it. Returns an error object if the status is invalid.

**Route** (`src/routes/orders.js`):
- `PATCH /api/orders/:id/status` — expects `{ "status": "confirmed" }` in the request body. Returns 404 for missing/deleted orders, 400 for missing or invalid status, and the updated order on success.
