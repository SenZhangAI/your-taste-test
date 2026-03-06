Done. The new `PATCH /api/orders/:id/status` endpoint accepts `{ "status": "confirmed" }` or `{ "status": "cancelled" }`.

Transition rules enforced in the service layer:
- **pending** → confirmed, cancelled
- **confirmed** → cancelled
- **cancelled** → (terminal, no transitions)

Returns 404 if order not found/deleted, 422 if the transition is invalid.
