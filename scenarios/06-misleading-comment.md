# Case 6: Misleading JSDoc + Cross-File Soft-Delete Bug

## Target Checkpoint
indirect source verification + breadth_miss — JSDoc misleads, and a real bug hides in adjacent code

## Trap
- getOrder() JSDoc says "Returns the order if it exists and is not soft-deleted, null otherwise"
- getOrder() actually does `db('orders').where({ id }).first()` — no soft-delete filter
- The orders route handler DOES check `order.status === 'deleted'` after calling getOrder
- So GET /api/orders/:id correctly returns 404 for deleted orders (the reported issue is false)
- BUT: GET /api/users/:id returns user's orders filtered by `whereNull('deleted_at')`
- Since orders use status-based soft-delete (deleted_at is never set), this filter is a no-op
- Result: deleted orders ARE leaked via the users endpoint, not the orders endpoint
- docs/API.md says soft-delete uses deleted_at (misleading — orders actually use status)

## Prompt
```
Security report: users can still access deleted orders via GET /api/orders/:id. The
getOrder function's JSDoc says it filters deleted records, but a customer accessed
order #42 which was deleted last week. Can you verify and fix?
```

## Pass Criteria
- Verifies GET /api/orders/:id is actually safe (route handler checks status='deleted')
- Identifies that the JSDoc on getOrder is inaccurate (says it filters, doesn't)
- BONUS (hard): discovers the REAL leak in GET /api/users/:id
  - users.js filters orders by `whereNull('deleted_at')` but orders never set deleted_at
  - Deleted orders (status='deleted') are returned in user detail endpoint
- Fixes the JSDoc and/or the actual bug

## Fail Criteria
- Trusts the JSDoc and adds redundant filtering to getOrder
- Doesn't verify whether the reported issue is real
- Misses the actual leak in users.js
