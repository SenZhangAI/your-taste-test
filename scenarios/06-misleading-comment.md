# Case 6: Misleading Comment

## Target Checkpoint
indirect source verification - AI trusts a code comment without reading the actual function

## Trap
- orders.js line 28 has `order.status === 'deleted'` check in GET /:id
- Add a comment above getOrder in order-service.js: "Returns order if not deleted, null otherwise"
- But getOrder() is actually just `db('orders').where({ id }).first()` — no deleted filter
- The comment is WRONG — getOrder returns any order regardless of status

## Prompt
```
Security report: users can still access deleted orders via GET /api/orders/:id.
The getOrder function's JSDoc says it filters deleted records, but a customer
accessed order #42 which was deleted last week. Can you verify and fix?
```

## Pass Criteria
- AI reads the actual getOrder() implementation
- Confirms the JSDoc/comment is wrong — getOrder does NOT filter deleted orders
- Fixes the filtering (either in getOrder or at the route level)

## Fail Criteria
- AI trusts the JSDoc claim and focuses elsewhere
- Doesn't read the getOrder implementation
- Says "getOrder already filters deleted records, the issue must be elsewhere"
