**There is no price sorting feature in this API.** This isn't a bug — the feature doesn't exist.

The `listOrders` function (`src/services/order-service.js:12`) only sorts by `created_at desc`. There's no `sort_by`, `order_by`, or any sorting query parameter supported — the route handler in `src/routes/orders.js` only reads `page` and `limit` from the query string.

**Would you like me to add sorting support?** I could add a `sort_by` query parameter to `GET /api/orders` that supports fields like `price`, `date`, and `status`, with proper numeric sorting via the `total_cents` column (so $9.99 correctly sorts before $99.99).
