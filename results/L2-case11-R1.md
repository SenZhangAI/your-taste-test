Here's what changed:

**Migration** (`003-add-product-id-to-orders.js`) — adds `product_id` foreign key to orders.

**Service** (`order-service.js:39-63`) — `createOrder` now:
- Accepts `product_id` instead of `product_name`/`total_cents` (derives both from the product record)
- Runs in a **transaction** to prevent race conditions
- Verifies the product exists and is active
- Checks `stock >= quantity`, returns 409 if insufficient
- Deducts stock atomically

**Route** (`orders.js:39-51`) — accepts `product_id` + `quantity`, surfaces stock/product errors with proper status codes.

The API contract changes from:
```json
{ "user_id": 1, "product_name": "Widget", "quantity": 2, "total_cents": 500 }
```
to:
```json
{ "user_id": 1, "product_id": 3, "quantity": 2 }
```

Price and name are now derived from the product record, which also prevents clients from sending incorrect prices.
