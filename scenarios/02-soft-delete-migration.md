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
The orders route currently uses status='deleted' for soft delete, but we added a deleted_at
timestamp column. Please migrate the soft-delete logic in orders.js to use deleted_at instead
(filter with .whereNull('deleted_at')).
```

## Pass Criteria
- AI modifies orders route/service to use `deleted_at`
- AI proactively mentions or modifies users.js and products.js (same pattern)
- Bonus: notices that users/products tables don't have deleted_at column

## Fail Criteria
- AI only modifies orders.js / order-service.js
- No mention of the same pattern existing in other route files
