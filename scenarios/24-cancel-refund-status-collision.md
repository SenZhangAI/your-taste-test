# Case 24: "Add order cancellation with refund tracking"

## Category
**Enumerate from first principles** — The obvious approach (add `cancelled` status + `refund_cents`) misses that `status` is overloaded with soft-delete semantics.

## Target Checkpoint
enumerate_from_first_principles — Must enumerate what `status` already means before adding new values to it.

## Trap
No code changes needed. The traps are already present:

- `ORDER_STATUSES` in `validators.js` includes `'cancelled'` — looks like cancellation is already considered
- But `softDeleteOrder()` sets `status = 'deleted'` — so `status` serves double duty (business state AND soft-delete)
- `listOrders()` filters `status != 'deleted'` — cancelled orders still appear in lists (correct)
- But what about an order that's cancelled AND THEN soft-deleted? `status` can only hold one value
- Adding `refund_cents` column requires a schema change, but `initDB()` only creates tables if they don't exist — no migration mechanism for existing databases
- `getOrderTotal()` doesn't account for refunds — every display of "total" would be wrong for partially refunded orders

## Prompt
```
need to add order cancellation. when an order is cancelled, we should track
the refund amount (could be partial refund). add a cancel endpoint and show
refund info in the order response
```

## Pass Criteria
- Addresses the status field conflict: `cancelled` vs `deleted` both live in `status` — what happens when a cancelled order is later soft-deleted?
- Considers where to store `refund_cents` (new column needs schema migration, `initDB` won't add it to existing tables)
- Updates `getOrderTotal()` or the display logic to account for refunds
- Prevents cancellation of already-deleted or already-shipped orders

## Fail Criteria
- Adds `status = 'cancelled'` without noticing the soft-delete collision
- Adds a `refund_cents` column to the `initDB` schema without considering existing databases
- Doesn't update the order total/display to reflect refunds
- Doesn't guard against double-cancellation or cancelling already-shipped orders

## Why This Differentiates L0 vs L2
Before adding cancellation, the AI should enumerate what `status` already means in this system. L2's "consider the design space before coding" should trigger: "status is used for soft-delete, so adding business states to the same field creates conflicts." L0 may see `cancelled` in `ORDER_STATUSES` and assume it's straightforward.
