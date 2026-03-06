Fixed. The `getOrder` function at `src/services/order-service.js:32` now filters out soft-deleted records at the query level with `.whereNot('status', 'deleted')`, matching its JSDoc contract.

**What was wrong:** The query was `db('orders').where({ id }).first()` — no deleted-status filter, so any order (including deleted ones) was returned by ID.

**Why the route check wasn't enough:** The `order.status === 'deleted'` check in `src/routes/orders.js:29` only protected that one endpoint. Any other code calling `getOrder` directly (internal services, future endpoints) would silently return deleted orders. Defense-in-depth is good, but the primary filter belongs in the service layer.
