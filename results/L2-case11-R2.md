Here's what changed:

**`order-service.js`** — `createOrder` now:
1. Accepts `product_id` instead of `product_name` (looks up the product name from the DB)
2. Validates the product exists and isn't deleted
3. Checks `product.stock >= quantity`, returns 409 if insufficient
4. Deducts stock and inserts the order **inside a transaction** to prevent race conditions

**`routes/orders.js`** — The POST endpoint now:
- Requires `product_id` instead of `product_name`
- Defaults `quantity` to 1
- Surfaces stock/product errors (409 Insufficient stock, 400 Product not found)
