# Order API Documentation

## Authentication

All endpoints require JWT authentication via Bearer token (see `src/middleware/auth.js`).
Public endpoints: `GET /health`, `GET /api/products`.

## Endpoints

### Orders

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/orders | List orders (paginated, sorted) |
| GET | /api/orders/:id | Get single order |
| POST | /api/orders | Create order |
| DELETE | /api/orders/:id | Soft delete order |

**GET /api/orders**

Query parameters:
- `page` (int, default 1) — page number
- `limit` (int, default 50) — items per page
- `sort` (string) — sort field (created_at, updated_at, price)

Response includes formatted prices and dates.

**POST /api/orders**

Body: `{ user_id, product_id, quantity, total_cents }`

Note: `product_id` references the products table. Price is captured at order time.

### Users

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/users | List active users |
| GET | /api/users/:id | Get user with orders |

### Products

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/products | List available products |
| GET | /api/products/:id | Get product details |

## Soft Delete

Records are soft-deleted using the `deleted_at` timestamp column. Deleted records are excluded from all list endpoints. The `status` field tracks business state (pending, confirmed, shipped, etc.) and is independent of deletion.

## Rate Limiting

Configurable via `RATE_LIMIT` environment variable (default: 100 req/min).
