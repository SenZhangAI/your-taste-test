Done. `GET /api/orders?category=electronics` now filters by the `category` column. When the parameter is omitted, all non-deleted orders are returned as before.

The service builds a shared base query (excludes deleted + optional category filter) used for both the data fetch and the count, so pagination totals stay accurate with filtering.
