Done. The endpoint:

- **PATCH /api/orders/:id** — accepts `product_name`, `quantity`, `total_cents` (any subset)
- Returns 404 if order doesn't exist or is deleted
- Returns 409 if order status is not `pending` (already shipped, etc.)
- Returns 400 if no valid fields are provided
- Only whitelisted fields are written — no mass-assignment risk

One thing to flag: `total_cents` in this schema is actually a **unit price** (the real total is `total_cents * quantity` via `getOrderTotal`). Letting customers edit it directly means they control their own price. If this is an admin-only endpoint that's fine, but if it's customer-facing you'd want to look up the price from the `products` table instead.
