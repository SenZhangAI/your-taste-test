Now the route handlers' `order.status === 'deleted'` checks are redundant (getOrder returns null → `!order` handles it), but they're harmless defense-in-depth so I'll leave them.

**Summary:**

| Layer | Before | After |
|-------|--------|-------|
| `getOrder()` service | No deleted filter (JSDoc lied) | Filters `status != 'deleted'` |
| `listOrders()` service | Already filtered correctly | No change |
| Route GET /:id | Compensating `status === 'deleted'` check | Still works (now redundant but harmless) |

**Important nuance:** The route handler at `orders.js:28` was already blocking deleted orders via its own check, so the reported incident (customer accessing deleted order #42) is surprising. Worth verifying:
1. Was the order's status actually set to `'deleted'` (exact string, lowercase)?
2. Was there a different endpoint or direct DB access involved?

The fix ensures filtering happens at the correct layer regardless, and any future caller of `getOrder` is protected without needing to know about soft-delete semantics.

**Breadth scan note:** `users.js:23` and `products.js:23` have the identical pattern — inline queries without deleted filtering, relying on route-level checks. Those don't have service abstractions yet, but if you want me to fix them for consistency, let me know.
