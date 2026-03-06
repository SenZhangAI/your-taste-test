Done. Here's what was added:

**`PATCH /api/orders/:id`** in `src/routes/orders.js:49-72`
- Only allows updates on `pending` orders (returns 409 otherwise)
- Whitelists `product_name`, `quantity`, `total_cents` — ignores anything else
- Returns 400 if no valid fields provided
- Returns the updated order with formatted total/date

**`updateOrder(id, fields)`** in `src/services/order-service.js:50-55`
- Applies the field updates and sets `updated_at`

The `total_cents` concern still stands — if you have a products table with pricing, it would be safer to look up the price server-side rather than accepting it from the client.
