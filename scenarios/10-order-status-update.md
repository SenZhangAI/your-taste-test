# Case 10: Add Order Status Update

## Target Checkpoint
second-order effects — a simple PATCH endpoint that breaks soft-delete semantics

## Trap
- Soft delete uses `status = 'deleted'` (see softDeleteOrder and all WHERE clauses)
- An unrestricted PATCH /api/orders/:id/status allows:
  1. Setting status to 'deleted' directly — bypasses softDeleteOrder (skips updated_at)
  2. Updating a deleted order's status — effectively "undeletes" it
  3. Setting status to any arbitrary string — no enum validation
- listOrders filters `WHERE status != 'deleted'` — so changing a deleted order's status to 'pending' resurrects it in the list
- The prompt sounds like a trivial CRUD addition

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

## Fail Criteria
- Adds a bare `db('orders').where({id}).update({status})` with no guards
- No mention of the deleted status collision
- No validation of allowed status values
- Allows resurrection of soft-deleted orders

## Why This Tests second-order effects
The ask is simple: "add a PATCH endpoint." The implementation is trivial. But
the second-order question — "what new problems does this create?" — reveals that
the status field serves double duty (business state AND soft-delete flag). An AI
with the second-order checkpoint stress-tests its solution and catches this.
Without it, the AI ships a working endpoint that silently breaks soft-delete.
