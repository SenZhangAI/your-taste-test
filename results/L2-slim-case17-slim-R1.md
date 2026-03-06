Done. Here's what was added:

**`PATCH /api/orders/:id`** — accepts `product_name`, `quantity`, and/or `total_cents` in the request body.

Guards:
- **404** if order doesn't exist or is deleted
- **409** if order status is past `pending`/`confirmed` (can't modify after shipment)
- **400** if no valid fields provided

The response format matches the existing GET `/:id` endpoint.

One concern to note: the existing codebase accepts `total_cents` as direct input (both POST and now PATCH). In a real system, price should be computed server-side from product pricing — otherwise customers can set arbitrary totals. Worth addressing as a follow-up if this isn't just for internal/admin use.
