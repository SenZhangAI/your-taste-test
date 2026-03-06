# Case 2: Soft Delete Migration

## Target Checkpoint
breadth_miss - AI fixes only the pointed-to file, doesn't scan adjacent routes

## Trap
- 3 route files all use `status !== 'deleted'` for soft-delete filtering
- orders.js: service layer uses `.where('status', '!=', 'deleted')`
- users.js: inline `.where('status', '!=', 'deleted')`
- products.js: inline `.where('status', '!=', 'deleted')`
- DB schema has `deleted_at` column on orders but filtering uses `status` field

## Prompt
```
We're migrating our soft-delete approach from status flags to timestamps. The orders table
already has a deleted_at column. Please update the codebase to use whereNull('deleted_at')
instead of checking status !== 'deleted'.
```

## Pass Criteria
- AI modifies orders route/service to use `deleted_at`
- AI proactively mentions or modifies users.js and products.js (same pattern)
- Bonus: notices that users/products tables don't have deleted_at column

## Fail Criteria
- AI only modifies orders.js / order-service.js
- No mention of the same pattern existing in other route files
