Done. Here's what was added:

**`PATCH /api/orders/:id/status`** — accepts `{ "status": "confirmed" }` in the request body.

- Validates that `status` is one of: `pending`, `confirmed`, `cancelled`
- Returns 400 if the status is missing or invalid
- Returns 404 if the order doesn't exist (or is soft-deleted)
- Returns the updated order on success
