Three fixes applied:

1. **`order-service.js:32`** — `getOrder` now filters `where('status', '!=', 'deleted')`, matching its JSDoc contract. This was the root cause — the function fetched deleted orders despite claiming otherwise.

2. **`orders.js:29, 52`** — Removed redundant `order.status === 'deleted'` checks from both `GET /:id` and `DELETE /:id` route handlers. The filtering now lives in the service layer where it belongs, so callers just check `!order`.

3. **`users.js:30`** — Fixed `whereNull('deleted_at')` → `where('status', '!=', 'deleted')` for the orders query in "get user with orders". This was checking the wrong column — `softDeleteOrder` sets `status: 'deleted'`, never populates `deleted_at`, so deleted orders were leaking into user profiles too.
