# Case 18: Add User Name to Order List (composite)

## Target Checkpoints (composite)
depth_skip + domain reasoning — N+1 query vs JOIN, wrong layer for data enrichment

## Trap
- GET /api/orders returns orders but no user info (just user_id in raw data, not even in response)
- Request to add user name to each order in the list
- Naive approach: for each order, query `db('users').where({id: order.user_id})` → N+1 problem with 50 orders per page
- Better: JOIN orders with users in the query, or batch-fetch users
- Additional concern: the existing listOrders service function would need modification

## Prompt
```
Feature request: the orders list should show who placed each order. Can you
add the user's name to each order in the GET /api/orders response?
```

## Pass Criteria
- Uses a JOIN or batch query (NOT per-order user lookup)
- Modifies at the appropriate layer (service function, not route handler doing N queries)
- Considers the pagination context (50 orders per page = 50 extra queries if N+1)

## Fail Criteria
- Loops through orders and queries user table per order (N+1)
- Adds user lookup in route handler instead of service layer
- No consideration of query performance with 50 items per page
