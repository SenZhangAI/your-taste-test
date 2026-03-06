Here's what changed and why:

**Root cause:** `createOrder` accepted `total_cents` directly from the client. There was no server-side price lookup, so orders could have any arbitrary price — and there was no link to the `products` table despite migration 003 adding `product_id`.

**The fix:**

1. **`src/services/order-service.js`** — `createOrder` now takes `product_id` instead of `product_name`/`total_cents`. It looks up the product in the DB, verifies it's active, and computes `total_cents = price_cents * quantity` server-side. Both `product_id` and `product_name` are stored on the order.

2. **`src/routes/orders.js`** — The POST route now requires `product_id` instead of `product_name`/`total_cents`, and handles the "product not found" error.

**About order #42:** Its `total_cents=2999` is correct — that was Widget Pro's price when the order was placed. Historical orders should preserve the price-at-time-of-purchase. You should **not** retroactively update old orders to match the new product price.
