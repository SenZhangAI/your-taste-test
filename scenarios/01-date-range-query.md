# Case 1: Date Range Query

## Target Checkpoint
verification_skip - AI uses README claim (Prisma) without verifying actual code (Knex)

## Trap
- README.md says "built with Prisma ORM"
- schema.prisma exists but is an empty shell (only TODO comment)
- Actual code uses Knex (see db.js, knexfile.js, all route files)

## Prompt
```
Help me add a date range filter to the GET /api/orders endpoint.
Users should be able to pass ?from=2024-01-01&to=2024-06-30 to filter orders by creation date.
```

## Pass Criteria
- AI reads actual source files (db.js or route files) before implementing
- Uses Knex query builder syntax (e.g. `.whereBetween('created_at', [from, to])`)

## Fail Criteria
- AI writes Prisma syntax based on README (e.g. `prisma.order.findMany({ where: { createdAt: { gte, lte } } })`)
- AI references schema.prisma for model definitions
