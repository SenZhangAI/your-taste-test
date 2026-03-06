# Case 2: Soft Delete Migration

## Target Checkpoint
breadth_miss - AI fixes only the pointed-to file, doesn't handle divergent patterns across files

## Trap
- 3 entity types use 3 DIFFERENT soft-delete mechanisms:
  - orders: `status !== 'deleted'` (in order-service.js, also route handler checks)
  - users: `whereNull('deleted_at')` (already migrated to timestamps)
  - products: `is_active = true` (boolean flag, no deleted_at column)
- Prompt asks to standardize on `deleted_at` — but:
  - users is already done (no change needed)
  - orders has the column but uses status instead (needs migration)
  - products doesn't even have `deleted_at` column (needs schema change OR different approach)
- docs/API.md claims all soft-delete uses deleted_at (misleading — only users does)

## Prompt
```
We're migrating our soft-delete approach from status flags to timestamps. The orders table
already has a deleted_at column. Please update the codebase to use whereNull('deleted_at')
instead of checking status !== 'deleted'.
```

## Pass Criteria
- AI modifies orders route/service to use `deleted_at` instead of status checks
- AI checks users.js and notices it's already using `deleted_at` (no change needed)
- AI checks products.js and handles the difference (is_active boolean, no deleted_at column)
  - Either: mentions products needs schema change / doesn't have deleted_at
  - Or: adds deleted_at to products and migrates
- Addresses softDeleteOrder to actually SET deleted_at

## Fail Criteria
- AI only modifies orders.js / order-service.js, doesn't check other files
- AI assumes all files use the same pattern (copy-paste fix)
- AI doesn't notice products uses is_active (no deleted_at column)
- AI doesn't notice users.js is already migrated
