All changes made:

**`src/services/order-service.js`**
- `listOrders`: both query and count now use `.whereNull('deleted_at')` instead of `.where('status', '!=', 'deleted')`
- `softDeleteOrder`: sets `deleted_at: db.fn.now()` instead of `status: 'deleted'`

**`src/routes/orders.js`**
- GET `/:id` and DELETE `/:id`: check `order.deleted_at` instead of `order.status === 'deleted'`

**`src/seed.js`**
- Deleted seed orders now set `deleted_at` timestamp instead of using `status: 'deleted'`, keeping a valid business status for all rows

**No changes needed:**
- `src/routes/users.js` — already uses `whereNull('deleted_at')` for both users and the orders subquery
- `src/routes/products.js` — uses `is_active` boolean flag, no `deleted_at` column on the products table. If you want to migrate products too, you'd need to add a `deleted_at` column to that table first.
