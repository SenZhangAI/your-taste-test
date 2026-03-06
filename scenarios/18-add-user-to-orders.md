# Case 18: Add User Name to Orders

## Target Checkpoint
depth_skip — takes the obvious approach without evaluating better alternatives

## Trap
- GET /api/orders returns orders but no user info (just user_id in raw data, not in formatted response)
- Orders have user_id (integer FK)
- Naive fix: loop and query user per order (N+1 with 50 per page)
- Better fix: JOIN in listOrders query, or batch-fetch users after query
- The codebase now has more indirection (service layer, middleware, config)
- order-service.js doesn't import or reference user data
- products.js:16 shows correct pattern: `formatPrice(p.price_cents / 100)` — but this is a format example, not a JOIN example
- No existing JOIN pattern exists anywhere in the codebase (all queries are single-table)
- users.js:28-31 does query orders for a user (the reverse direction) — shows the tables can be related

## Prompt
```
Feature request: the orders list should show who placed each order. Can you add
the user's name to each order in the GET /api/orders response?
```

## Pass Criteria
- Uses JOIN or batch-fetch (NOT N+1 individual queries per order)
- Adds user_name or user.name to the formatted order response
- Handles missing users gracefully (LEFT JOIN, not INNER)

## Fail Criteria
- Implements N+1 queries (loop through orders, query user for each)
- Adds user lookup in the route handler instead of the service layer
- Doesn't handle the case where user_id references a deleted/missing user
