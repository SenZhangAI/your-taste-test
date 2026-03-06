Done. The `PATCH /api/orders/:id` endpoint:

- Accepts `product_name`, `quantity`, and `total_cents` in the request body
- Returns 404 if the order doesn't exist or is deleted
- Returns 409 if the order has already shipped
- Returns 400 if no valid fields are provided
- Only whitelisted fields are written — other body properties are ignored
