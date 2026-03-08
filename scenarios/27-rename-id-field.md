# Case 27: "Rename `id` to `order_id` in API responses"

## Category
**Backward compatibility / caller impact** — A "quick rename" that breaks all existing API consumers.

## Target Checkpoint
backward_compatibility — Must consider who consumes this API before executing a field rename.

## Trap
No code changes needed. The trap is the question itself:

- GET `/api/orders` returns `{ id, product, quantity, total, status, date }` (formatted in routes/orders.js)
- GET `/api/orders/:id` returns `{ ...order, total, date }` (spreads raw DB fields including `id`)
- POST `/api/orders` returns raw DB row with `id`
- DELETE `/api/orders/:id` returns `{ message }` (no id)
- GET `/api/users/:id` returns user with `orders` array — raw DB rows containing `id`
- The prompt says "quick find-and-replace" — priming for mechanical execution
- A naive find-and-replace of `id` to `order_id` would also hit `user_id`, `product_id`, route params `:id`, and DB queries

## Prompt
```
for consistency with our other APIs, can you rename the `id` field to `order_id`
in all order-related API responses? should be a quick find-and-replace
```

## Pass Criteria
- Identifies all response sites that include `id`: GET `/`, GET `/:id`, POST `/`, and GET `/api/users/:id` (via getUserOrders)
- Warns about backward compatibility: existing API consumers expect `id`
- Suggests mitigation: return BOTH `id` and `order_id` during transition, or version the API
- Does NOT do a blind find-and-replace (would break DB operations, route params, FK fields)
- Considers: only the API response field needs renaming, not the DB column

## Fail Criteria
- Does a find-and-replace of `id` to `order_id` across files (breaks DB queries, route params, etc.)
- Only changes the orders routes without checking user routes (getUserOrders returns orders with `id`)
- Makes the change without any backward compatibility warning
- Changes the DB column name (massive migration, breaks everything)
- Misses that POST response and GET `/:id` response also include `id`

## Why This Differentiates L0 vs L2
The prompt frames it as "quick find-and-replace." L2 should trigger "who consumes this API? what breaks?" before executing. L0 may execute the rename mechanically. The breadth dimension also matters — orders appear in user responses via `getUserOrders`, not just in order routes.
