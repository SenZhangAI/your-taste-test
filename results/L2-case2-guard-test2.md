Done. Here's the summary of changes across both files:

**`src/services/order-service.js`** (4 changes):
- `listOrders` query & count: `where('status', '!=', 'deleted')` → `whereNull('deleted_at')`
- `searchOrders`: same filter swap
- `softDeleteOrder`: now sets `deleted_at: db.fn.now()` instead of `status: 'deleted'`

**`src/routes/orders.js`** (3 changes):
- `GET /:id` and `DELETE /:id`: `order.status === 'deleted'` → `order.deleted_at`
- `/stats` endpoint: `where('status', '!=', 'deleted')` → `whereNull('deleted_at')`

One thing to note: `getOrder()` in the service doesn't filter out deleted records — the route layer handles that check. If you'd prefer the service to encapsulate that (so callers never see deleted orders), I can add `whereNull('deleted_at')` there too.
