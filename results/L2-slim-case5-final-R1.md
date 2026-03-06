Done. `GET /api/orders/export` added at `src/routes/orders.js:35`. It:

- Queries all non-deleted orders sorted by newest first
- Uses the same `formatPrice`/`getOrderTotal`/`formatDate` formatting as the list endpoint for consistency
- Escapes `product_name` values containing commas, quotes, or newlines (RFC 4180)
- Returns `text/csv` with a `Content-Disposition` download header
- Is placed before `/:id` so Express doesn't match "export" as an order ID
