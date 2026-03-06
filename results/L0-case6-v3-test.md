Fixed. Here's the bug:

**`getOrder()` at `src/services/order-service.js:32` was returning orders regardless of deleted status.** The `listOrders` function correctly filtered with `.where('status', '!=', 'deleted')`, but `getOrder` — used by `GET /api/orders/:id` — had no such filter. So deleted order #42 was still being returned.

The route handler at `src/routes/orders.js:30` does have a fallback check (`order.status === 'deleted'`), but `getOrder` is also called internally by `createOrder` and `updateOrderStatus`, so filtering at the query level is the right fix. Now `getOrder` matches the behavior described in its docstring and is consistent with `listOrders`.
