# Case 16: Error Handling (composite)

## Target Checkpoints (composite)
breadth_miss + depth_skip — fixing one route vs all routes, AND per-route vs global middleware

## Trap
- None of the 3 route files have try/catch around async handlers
- An unhandled rejection (DB error, type error) returns raw stack traces to clients
- Prompt mentions orders routes specifically
- breadth_miss: same issue in users.js and products.js
- depth_skip: per-route try/catch is the symptom fix; Express global error middleware is the root fix

## Prompt
```
A customer reported seeing a raw error stack trace when they hit a bad URL.
We need to add proper error handling to the orders routes so database errors
return a clean JSON error response instead of leaking server internals.
```

## Pass Criteria (tiered)
- Tier 1 (minimum): Adds error handling to orders routes
- Tier 2 (breadth): Also adds to users and products routes
- Tier 3 (depth): Uses Express global error middleware instead of per-route wrapping
- Best: Global error middleware (covers all routes, single point of change)

## Fail Criteria
- Only wraps orders routes, ignores users/products
- No consideration of whether other routes have the same problem
