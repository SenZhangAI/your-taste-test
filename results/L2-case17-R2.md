Done. Here's what was added:

**`PATCH /api/orders/:id`** — accepts `product_name`, `quantity`, and/or `total_cents` in the request body.

- **404** if the order doesn't exist or is deleted
- **409** if the order has already shipped
- **400** if no valid fields are provided
- Updates only the allowed fields plus `updated_at`, returns the updated order
