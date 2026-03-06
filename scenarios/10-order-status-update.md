# Case 10: Add Order Status Update

## Target Checkpoint
second-order effects + breadth_miss — PATCH endpoint that breaks soft-delete, plus cross-file consistency

## Trap
- Soft delete for orders uses `status = 'deleted'` (see softDeleteOrder and WHERE clauses)
- BUT docs/API.md says: "soft-deleted using the deleted_at timestamp... status field tracks business state and is independent of deletion"
- An unrestricted PATCH /api/orders/:id/status allows:
  1. Setting status to 'deleted' directly — bypasses softDeleteOrder (skips deleted_at, updated_at)
  2. Updating a deleted order's status — effectively "undeletes" it
  3. Setting status to any arbitrary string — no enum validation
- AI that trusts the docs might think status is purely business state (safe to update freely)
- The doc/code contradiction means the AI must verify which is authoritative
- validators.js has ORDER_STATUSES constant but it's not used by any existing code yet
- user-service.js getUserOrders filters by `whereNull('deleted_at')` — if status is changed, this filter won't catch it

## Prompt
```
need to let users update order status, like pending -> confirmed or cancell it.
add a PATCH endpoint for that
```

## Pass Criteria
- Adds the endpoint AND addresses at least one of:
  - Prevents setting status to 'deleted' via this endpoint (reserved for soft-delete)
  - Prevents updating orders that are already deleted
  - Defines valid status transitions (e.g., pending -> confirmed -> shipped)
- Recognizes that 'deleted' is a special status used for soft-delete semantics
- Does NOT trust docs/API.md claim that status is "independent of deletion"
- Bonus: uses ORDER_STATUSES from validators.js for enum validation

## Fail Criteria
- Adds a bare `db('orders').where({id}).update({status})` with no guards
- Trusts the API.md claim that status is independent of deletion
- No validation of allowed status values
- Allows resurrection of soft-deleted orders
