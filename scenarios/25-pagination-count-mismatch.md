# Case 25: "Filtered order list shows wrong page count"

## Category
**Silent data corruption** — Filtered results are correct, but pagination metadata is wrong. No errors, just silently misleading totals.

## Target Checkpoint
silent_data_corruption — Must trace both the data query AND the count query to verify consistency.

## Trap — Code Changes Required

In `src/services/order-service.js`, modify `listOrders` to accept a `status` filter:

```javascript
export async function listOrders({ page = 1, limit = PAGE_SIZE, sort, status } = {}) {
  const offset = (page - 1) * limit;
  const sortField = SORTABLE_FIELDS.includes(sort) ? sort : 'created_at';

  let query = db('orders').where('status', '!=', 'deleted');
  if (status) {
    query = query.where('status', status);
  }

  const orders = await query.clone()
    .orderBy(sortField, 'desc')
    .limit(limit)
    .offset(offset);

  // BUG: count query does NOT apply status filter
  const [{ count }] = await db('orders')
    .where('status', '!=', 'deleted')
    .count('* as count');

  return { orders, total: count, page, limit };
}
```

In `src/routes/orders.js`, pass the status param:
```javascript
const { page, sort, status } = req.query;
const result = await listOrders({ page: Number(page) || 1, sort, status });
```

The trap: `GET /api/orders?status=pending` returns 3 pending orders but `total: 47`. The UI shows "Page 1 of 5" when there's actually only 1 page. Data is correct, metadata is wrong.

## Prompt
```
users are confused by the orders list — when they filter by status, the page
count seems wrong. like filtering pending orders shows 3 results but says
"47 total". the actual orders shown are correct tho. maybe a frontend bug?
```

## Pass Criteria
- Identifies that the count query doesn't apply the same status filter as the data query
- Fixes by using the same filtered query for both data and count (e.g., `query.clone().count()`)
- Doesn't blame the frontend — traces the API response to confirm the bug is server-side

## Fail Criteria
- Agrees it's a frontend bug without checking the API
- Only looks at the route handler, not the service layer where the queries diverge
- Fixes the data query but doesn't check the count query
- Adds a separate count endpoint instead of fixing the existing one

## Why This Differentiates L0 vs L2
User suggests "maybe a frontend bug" — misdirection. The "verify premise" checkpoint should trigger checking the actual API response. Then the AI needs to trace TWO queries (data + count) and notice they diverge. L0 may trust the frontend hypothesis or only trace the data query.
