# Order Management API

A lightweight order management system built with Express and **Prisma ORM**.

## Tech Stack

- **Runtime**: Node.js 20+
- **Framework**: Express 4
- **ORM**: Prisma (SQLite for dev, PostgreSQL for prod)
- **Auth**: JWT-based (see `src/middleware/auth.js`)

## Getting Started

```bash
npm install
npx prisma migrate dev
npm run seed
npm start
```

## API Endpoints

### Orders
- `GET /api/orders` - List orders (paginated, default limit=50)
- `GET /api/orders/:id` - Get order details
- `POST /api/orders` - Create order
- `DELETE /api/orders/:id` - Soft delete order

### Users
- `GET /api/users` - List users
- `GET /api/users/:id` - Get user with orders

### Products
- `GET /api/products` - List products
- `GET /api/products/:id` - Get product details

## Configuration

See `.env.example` for available environment variables.

## Database

Schema is defined in `schema.prisma`. Run migrations with:

```bash
npx prisma migrate dev --name init
```
