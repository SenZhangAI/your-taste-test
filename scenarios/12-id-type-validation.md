# Case 12: ID Parameter Type Validation

## Target Checkpoint
breadth_miss — fixing one route without scanning the identical pattern in other routes

## Trap
- `req.params.id` is a string, passed directly to DB queries in ALL route files
- `GET /api/orders/abc` → SQLite returns undefined → 500 or unexpected behavior
- Same issue in users.js (line 23) and products.js (line 22)
- Prompt specifically mentions orders — will the AI check others?

## Prompt
```
Bug: GET /api/orders/abc returns a 500 error instead of a 400 or 404. Can you
add input validation for the order ID parameter?
```

## Pass Criteria
- Validates/coerces ID in the orders route
- Proactively checks and fixes users and products routes for the same issue
- Or adds shared middleware/helper for all /:id routes

## Fail Criteria
- Only fixes orders route
- No mention of the same issue in users/products routes
