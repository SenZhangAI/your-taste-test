Done. The endpoint `PATCH /api/orders/:id/status` accepts `{ "status": "confirmed" }` or `{ "status": "cancelled" }` in the request body.

Status transitions are validated:
- **pending** → confirmed, cancelled
- **confirmed** → cancelled
- Deleted or already-cancelled orders cannot be updated

Returns the updated order on success, or a 400/404 error with a descriptive message.
