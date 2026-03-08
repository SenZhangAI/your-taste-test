# Case 30: "Add bulk order creation endpoint"

## Category
**Multi-dimensional scan** — A feature that requires considering multiple failure modes and applying existing patterns to a new context.

## Target Checkpoint
Generalization test — no direct bulk operation rule in thinking-context.md. Tests whether "Scan: what could go wrong? what second-order problems?" + "Explicit > Implicit" + breadth-scan direction 2 (break callers/create inconsistent state?) generalize to new feature design.

## Trap
- The request sounds simple ("accept an array, create multiple orders")
- But multiple dimensions need consideration:
  1. **Array size limit** — no limit = potential DoS / memory exhaustion (500k-item array)
  2. **Partial failure semantics** — all-or-nothing (transaction) vs partial success with error report? Must be explicit.
  3. **Stock checking** — existing single-order creation checks stock (Case 11 pattern). Bulk must also check stock per order, and handle race conditions across items competing for the same product.
  4. **Validation per item** — each order needs the same validation as single create (quantity > 0, required fields, etc.)
  5. **Response shape** — should match existing single-create response format for each order
- The prompt says nothing about limits, failures, or stock — priming for a minimal implementation

## Prompt
```
add a POST /api/orders/bulk endpoint that creates multiple orders in one
request. accept an array of orders in the request body
```

## Pass Criteria
- Implements the bulk endpoint with transaction (all-or-nothing) or explicit partial-failure handling
- Adds array size limit or at least warns about unbounded input
- Applies existing validation patterns (quantity > 0, required fields) to each item
- Considers stock checking if the codebase has it (follow existing patterns)
- Makes error handling explicit — what happens when item 3 of 10 fails?

## Fail Criteria
- Implements without any array size consideration
- Skips per-item validation that exists on the single-create endpoint
- Doesn't mention partial failure semantics (implicit behavior = bug)
- Ignores stock checking even though single-create has it
- Returns 201 with no error details when some items fail

## Why This Tests Generalization
thinking-context.md has no bulk operation rules. The AI must combine:
1. "Scan: what could go wrong?" → unbounded array, partial failures
2. "Explicit > Implicit" → failure semantics must be stated, not assumed
3. "Follow existing patterns" → single-create has validation + stock check → bulk should too
4. "Breadth-scan direction 2: does this create inconsistent state?" → partial inserts without transaction
5. "Correctness > Performance" → transaction safety over insert speed
