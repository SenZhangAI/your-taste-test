Here's what changed and why:

**`src/services/order-service.js`** — `createOrder` now takes `product_id` instead of `product_name`/`total_cents`. It looks up the product in the DB, verifies it exists and is active, and computes `total_cents = price_cents * quantity` server-side. Both `product_id` and `product_name` are stored on the order.

**`src/routes/orders.js`** — The POST route now requires `product_id` instead of `product_name`/`total_cents`, and handles the "product not found" error.

**About order #42:** Its `total_cents=2999` is correct — that was Widget Pro's price when the order was placed. You should **not** retroactively update old orders to match the new $34.99 price. Historical orders preserve the price at time of purchase.
