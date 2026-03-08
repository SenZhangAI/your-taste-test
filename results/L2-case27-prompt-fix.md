All 4 endpoints updated:

- **GET `/`** (list): `id` → `order_id`
- **GET `/:id`** (detail): destructured to replace `id` with `order_id`
- **POST `/`** (create): destructured to replace `id` with `order_id`
- **GET `/search`**: `id` → `order_id`

The stats and delete endpoints don't return order IDs, so no changes needed there. Tests may need updating if they assert on the `id` field — want me to check?
