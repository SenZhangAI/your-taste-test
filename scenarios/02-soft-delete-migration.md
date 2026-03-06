# Case 2: Soft Delete Migration

## Target Checkpoint
breadth_miss - AI fixes only the pointed-to file, doesn't handle divergent patterns across files

## Trap
- 3 entity types use 3 DIFFERENT soft-delete mechanisms:
  - orders: `status !== 'deleted'` (in order-service.js, also route handler checks)
  - users: `whereNull('deleted_at')` (in user-service.js — already migrated)
  - products: `is_active = true` (in product-service.js — boolean flag, no deleted_at column)
- Prompt asks to standardize on `deleted_at` — but:
  - users is already done (no change needed)
  - orders has the column but uses status instead (needs migration)
  - products doesn't even have `deleted_at` column (needs schema change OR different approach)
- docs/API.md claims all soft-delete uses deleted_at (misleading — only users does)
- Extra indirection: routes now call service functions, so AI must trace through service layer
- user-service.js getUserOrders also has `whereNull('deleted_at')` — this is the orders bug from Case 6

## Prompt
```
hey we're switching soft-delete to use timestamps instead of status flags. orders table
already has deleted_at column. can you update the code to use whereNull('deleted_at')
instead of status !== deleted?
```

## Pass Criteria
- AI modifies orders route/service to use `deleted_at` instead of status checks
- AI checks users.js / user-service.js and notices it's already using `deleted_at` (no change needed)
- AI checks products.js / product-service.js and handles the difference (is_active boolean, no deleted_at)
  - Either: mentions products needs schema change / doesn't have deleted_at
  - Or: adds deleted_at to products and migrates
- Addresses softDeleteOrder to actually SET deleted_at

## Fail Criteria
- AI only modifies orders.js / order-service.js, doesn't check other files
- AI assumes all files use the same pattern (copy-paste fix)
- AI doesn't notice products uses is_active (no deleted_at column)
- AI doesn't notice users.js is already migrated
- AI doesn't trace through the service layer (only looks at route files)
