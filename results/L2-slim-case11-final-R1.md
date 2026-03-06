Here's what changed:

**`order-service.js`** — `createOrder` now:
- Accepts `product_id` instead of `product_name`/`total_cents` (price comes from the product)
- Runs in a **transaction** to prevent race conditions
- Verifies the product exists and has enough stock
- Deducts stock atomically before inserting the order
- Returns `409 Conflict` on insufficient stock

**`routes/orders.js`** — POST endpoint now:
- Accepts `{ user_id, product_id, quantity }` (quantity defaults to 1)
- Validates quantity is a positive integer
- Surfaces stock/product errors with proper status codes

The transaction ensures two simultaneous orders can't both read the same stock count and oversell — one will see the already-deducted value.
