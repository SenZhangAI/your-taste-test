Done. Here's the summary:

**`src/services/order-service.js`**
- `listOrders`: `.where('status', '!=', 'deleted')` → `.whereNull('deleted_at')` (query + count)
- `getOrder`: added `.whereNull('deleted_at')` — the JSDoc claimed it filtered deleted records but it didn't, now it does
- `softDeleteOrder`: sets `deleted_at: db.fn.now()` instead of `status: 'deleted'`

**`src/routes/orders.js`**
- Removed `order.status === 'deleted'` checks from GET `/:id` and DELETE `/:id` — now redundant since `getOrder` filters at the query level

**`src/seed.js`** (already applied by hook)
- Deleted seed orders use `deleted_at` timestamp instead of `status: 'deleted'`, keeping a valid business status for all rows

**No changes needed:**
- `src/services/user-service.js` — already uses `whereNull('deleted_at')` for both users and orders queries
- `src/routes/products.js` / `product-service.js` — uses `is_active` boolean, no `deleted_at` column on products table
