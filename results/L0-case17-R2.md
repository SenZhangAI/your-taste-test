Done. Here's what was added:

**Service** (`src/services/order-service.js`): `updateOrder(id, fields)` — updates the given fields and sets `updated_at`.

**Route** (`src/routes/orders.js`): `PATCH /api/orders/:id` with these behaviors:
- Returns 404 if the order doesn't exist or is deleted
- Returns 400 if the order is already shipped
- Only allows `product_name`, `quantity`, and `total_cents` — ignores any other fields
- Returns 400 if no valid fields are provided
- Returns the updated order on success
