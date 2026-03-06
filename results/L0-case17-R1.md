Here's what was added:

**Service** (`src/services/order-service.js`): `updateOrder(id, fields)` — updates the given fields and sets `updated_at`.

**Route** (`src/routes/orders.js`): `PATCH /api/orders/:id` with these behaviors:
- Returns **404** if the order doesn't exist or is deleted
- Returns **409** if the order has already shipped
- Whitelists only `product_name`, `quantity`, and `total_cents` from the request body (ignores anything else)
- Returns **400** if none of those fields are provided
- Returns the updated order on success
