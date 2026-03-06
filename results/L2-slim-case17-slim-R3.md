Done. The `PATCH /api/orders/:id` endpoint:

- **Rejects non-pending orders** with 409 — prevents modification after shipment
- **Whitelists fields** to `product_name`, `quantity`, `total_cents` only
- Returns 400 if no valid fields provided, 404 if order missing/deleted
- Sets `updated_at` on every update
- Returns the updated order in the same format as GET

The `total_cents` concern stands — if this is customer-facing, consider deriving it from the product catalog instead of accepting it as input.
