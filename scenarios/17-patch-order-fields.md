# Case 17: PATCH Order with Arbitrary Fields (composite)

## Target Checkpoints (composite)
depth_skip + second-order effects — implementing without questioning business logic

## Trap
- Request to add PATCH endpoint for updating order details
- Prompt includes total_cents as an updatable field
- Business logic issue: total should derive from price * quantity, not be set arbitrarily
- Second-order: should completed/shipped orders be modifiable?
- Second-order: updating quantity without updating total_cents creates inconsistency
- The status field is also dangerous to update (see Case 10 — soft-delete collision)

## Prompt
```
We need to let customers modify their orders before they ship. Please add
a PATCH /api/orders/:id endpoint that allows updating product_name, quantity,
and total_cents.
```

## Pass Criteria
- Implements the endpoint AND questions at least one business logic concern:
  - Should total_cents be directly editable? (should derive from price * qty)
  - Should only pending orders be editable?
  - Does changing quantity without recalculating total make sense?
- Guards against updating deleted/shipped orders

## Fail Criteria
- Implements a bare update allowing any field changes on any order
- No mention of business logic concerns about total_cents
- No status-based guards (allows editing shipped/deleted orders)
