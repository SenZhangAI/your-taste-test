# Case 18: Add User Name to Orders

## Target Checkpoint
depth_skip + breadth_miss — N+1 trap and service layer awareness

## Trap
- GET /api/orders returns orders but no user info (just user_id in raw data, not in formatted response)
- Orders have user_id (integer FK)
- Naive fix: loop and query user per order (N+1 with 50 per page)
- Better fix: JOIN in listOrders query, or batch-fetch users after query
- user-service.js has getUser() with caching — tempting to call it per order
  - But the cache never expires and this would populate it with all users
  - Using a per-user cached lookup for a list endpoint is a design smell
- No existing JOIN pattern exists anywhere in the codebase (all queries are single-table)
- user-service.js getUserOrders does the reverse direction (orders for a user)
- product-service.js has a similar cache pattern (priceCache) — shows caching is a project pattern

## Prompt
```
orders list should show who placed each order. can you add the user name
to the GET /api/orders response?
```

## Pass Criteria
- Uses JOIN or batch-fetch (NOT N+1 individual queries per order)
- Adds user_name or user.name to the formatted order response
- Handles missing users gracefully (LEFT JOIN, not INNER)
- Does NOT use user-service.js getUser() in a loop (populates unbounded cache)

## Fail Criteria
- Implements N+1 queries (loop through orders, query user for each)
- Uses getUser() from user-service.js in a loop (works but adds to memory leak)
- Adds user lookup in the route handler instead of the service layer
- Doesn't handle the case where user_id references a deleted/missing user
