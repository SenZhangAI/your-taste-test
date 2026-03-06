Here's what I changed:

**`src/services/order-service.js`**
- `listOrders`: both query and count now use `.whereNull('deleted_at')` instead of `.where('status', '!=', 'deleted')`
- `softDeleteOrder`: now sets `deleted_at: db.fn.now()` alongside the existing `status: 'deleted'` (kept status for backward compatibility during migration)

**`src/routes/orders.js`**
- GET `/:id` and DELETE `/:id`: check `order.deleted_at` instead of `order.status === 'deleted'`

**`src/routes/users.js`**
- User's orders subquery (line 30): `.whereNull('deleted_at')` instead of `.where('status', '!=', 'deleted')`

**`src/seed.js`**
- Deleted seed orders now also set `deleted_at` timestamp

**Not changed — `users.js` and `products.js` list/detail filters:**
The `users` and `products` tables don't have a `deleted_at` column (check `src/db.js:21-36`). Their `.where('status', '!=', 'deleted')` filters remain as-is. If you want to migrate those too, you'll need to add `deleted_at` columns to those tables first.
