Done. Changes across all 4 order response endpoints:

- **List & Search**: `id: o.id` → `order_id: o.id`
- **Single order & Create**: destructured `id` out of the DB row, then spread the rest with `order_id: id` first — so `id` no longer leaks through

Note: the route params (`/:id`, `req.params.id`) are internal routing — left those as-is since they're not part of the API response shape.

**Breaking change warning**: any existing API consumers that read `.id` from order responses will break. If there are frontend clients or other services calling these endpoints, they'll need to update to `.order_id`.
