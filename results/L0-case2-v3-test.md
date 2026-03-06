Done. Here's a summary of the changes:

**`src/services/order-service.js`**
- `listOrders`: `.where('status', '!=', 'deleted')` → `.whereNull('deleted_at')` (both query and count)
- `getOrder`: added `.whereNull('deleted_at')` filter so deleted orders aren't returned
- `softDeleteOrder`: sets `deleted_at` timestamp instead of `status: 'deleted'`

**`src/routes/orders.js`**
- Updated the redundant `order.status === 'deleted'` guards to `order.deleted_at` (lines 30, 53)

**`src/seed.js`**
- Soft-deleted seed orders now get a proper status (`pending`/`confirmed`/`shipped`) and a `deleted_at` timestamp instead of `status: 'deleted'`

**`src/utils/validators.js`**
- Updated comment to reflect that soft-delete uses `deleted_at` timestamp
