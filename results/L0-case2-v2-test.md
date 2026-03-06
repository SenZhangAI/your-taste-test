All changes applied. Here's a summary:

**`src/services/order-service.js`**
- `listOrders`: both query and count now use `.whereNull('deleted_at')` instead of `.where('status', '!=', 'deleted')`
- `softDeleteOrder`: sets `deleted_at: db.fn.now()` instead of `status: 'deleted'`

**`src/routes/orders.js`**
- GET `/:id` and DELETE `/:id`: check `order.deleted_at` instead of `order.status === 'deleted'`

**`src/seed.js`**
- Deleted seed orders now also set `deleted_at` timestamp so they're properly filtered by the new queries

**No changes needed in `src/routes/users.js`** — it already uses `whereNull('deleted_at')` for filtering orders (line 30).
