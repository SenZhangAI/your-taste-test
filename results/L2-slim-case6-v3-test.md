The route file already had the `status === 'deleted'` checks cleaned up (probably by the same hook). The routes now just check `!order` which is correct since `getOrder` handles the filtering.

**Summary of the bug:**

- `getOrder()` at `src/services/order-service.js:32` was returning all orders regardless of soft-delete status — its JSDoc claimed it filtered deleted records, but the query had no filter
- `softDeleteOrder()` correctly sets `status: 'deleted'`, but `getOrder()` never checked for it
- Fixed by adding `.where('status', '!=', 'deleted')` to `getOrder`, consistent with `listOrders`

Now `GET /api/orders/42` will return 404 for deleted orders.
