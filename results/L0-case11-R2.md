Here's what I changed:

**`src/services/order-service.js`** — `createOrder` now:
- Requires `product_id` 
- Runs inside a **transaction** to prevent race conditions
- Verifies the product exists and is active (404 if not)
- Checks `product.stock >= quantity` (409 Conflict if insufficient)
- Deducts stock before inserting the order

**`src/routes/orders.js`** — The POST route now:
- Requires `product_id` in the request body
- Catches stock/product errors and returns the appropriate status code (409 for insufficient stock, 404 for missing product)

The transaction ensures that the stock check and deduction happen atomically — no two concurrent orders can oversell the same product.

Note: you'll need to run migration 003 (`migrations/003-add-product-id-to-orders.js`) if you haven't already, since orders now reference `product_id`.
