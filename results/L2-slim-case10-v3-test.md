Both changes are already in place (the hooks applied them). Here's what was added:

**Service** (`src/services/order-service.js:55-61`): `updateOrderStatus(id, status)` — updates the status and `updated_at`, returns the updated order.

**Route** (`src/routes/orders.js:51-62`): `PATCH /:id/status` — validates:
- `status` is one of `ORDER_STATUSES` (`pending`, `confirmed`, `shipped`, `delivered`, `cancelled`)
- Order exists and isn't deleted

Returns the updated order on success, 400 for invalid status, 404 if not found.
