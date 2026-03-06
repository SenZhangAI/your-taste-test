The POST response now formats `total` and `date` the same way as the GET `/:id` endpoint — using `formatPrice(getOrderTotal(order))` and `formatDate(order.created_at)`.
