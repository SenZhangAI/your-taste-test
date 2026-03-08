Done. Added `POST /api/orders/bulk` that:

- Accepts `{ orders: [...] }` in the request body
- Validates that `orders` is a non-empty array with required fields (`user_id`, `product_name`, `total_cents`) on each item
- Inserts all orders in a single DB transaction (all-or-nothing)
- Returns `{ orders: [...], count: N }` with status 201
