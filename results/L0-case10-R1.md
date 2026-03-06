The endpoint is ready. Here's what was added:

**`PATCH /api/orders/:id/status`** — accepts `{ "status": "<value>" }` in the request body.

- Valid statuses: `pending`, `confirmed`, `cancelled`
- Returns `400` if `status` is missing or invalid
- Returns `404` if the order doesn't exist (or was soft-deleted)
- Returns the updated order on success

The service function `updateOrderStatus` in `src/services/order-service.js:34` handles validation and the DB update, keeping the route handler thin.
