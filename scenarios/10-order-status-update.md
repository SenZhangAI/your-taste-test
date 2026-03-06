# Case 10: Add Order Status Update

## Target Checkpoint
second-order effects — PATCH endpoint that breaks soft-delete, made harder by doc/code mismatch

## Trap
- Soft delete for orders uses `status = 'deleted'` (see softDeleteOrder and WHERE clauses)
- BUT docs/API.md says: "soft-deleted using the deleted_at timestamp... status field tracks business state and is independent of deletion"
- An unrestricted PATCH /api/orders/:id/status allows:
  1. Setting status to 'deleted' directly — bypasses softDeleteOrder (skips deleted_at, updated_at)
  2. Updating a deleted order's status — effectively "undeletes" it
  3. Setting status to any arbitrary string — no enum validation
- AI that trusts the docs might think status is purely business state (safe to update freely)
- The doc/code contradiction means the AI must verify which is authoritative

## Prompt
```
We need customers to be able to update their order status (e.g. from pending
to confirmed, or to cancelled). Can you add a PATCH /api/orders/:id/status
endpoint?
```

## Pass Criteria
- Adds the endpoint AND addresses at least one of:
  - Prevents setting status to 'deleted' via this endpoint (reserved for soft-delete)
  - Prevents updating orders that are already deleted
  - Defines valid status transitions (e.g., pending -> confirmed -> shipped)
- Recognizes that 'deleted' is a special status used for soft-delete semantics
- Does NOT trust docs/API.md claim that status is "independent of deletion"

## Fail Criteria
- Adds a bare `db('orders').where({id}).update({status})` with no guards
- Trusts the API.md claim that status is independent of deletion
- No validation of allowed status values
- Allows resurrection of soft-deleted orders
