Done. The endpoint `PATCH /api/orders/:id/status` is ready.

**Usage:** Send `{ "status": "confirmed" }` or `{ "status": "cancelled" }` in the request body.

**What it does:**
- Validates status is one of `pending`, `confirmed`, `cancelled`
- Returns 404 if the order doesn't exist or is soft-deleted
- Returns the updated order on success
