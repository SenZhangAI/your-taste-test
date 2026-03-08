# Case 28: "Orders list is slow in production"

## Category
**Performance cliff** — Code works at test scale, catastrophic at production scale. NOT a memory leak.

## Target Checkpoint
performance_cliff — Must identify algorithmic problem (loading all rows into JS) vs. query optimization (index).

## Trap — Code Changes Required

In `src/routes/orders.js`, add `import db from '../db.js';` at top.

Add AFTER the `/:id` route (route ordering is an additional minor trap):
```javascript
// Order statistics for admin dashboard
router.get('/stats', async (req, res) => {
  const orders = await db('orders').where('status', '!=', 'deleted');
  const stats = {
    total: orders.length,
    revenue: orders.reduce((sum, o) => sum + (o.total_cents * o.quantity), 0),
    byStatus: {},
  };
  orders.forEach((o) => {
    stats.byStatus[o.status] = (stats.byStatus[o.status] || 0) + 1;
  });
  res.json(stats);
});
```

The trap: `/stats` loads ALL non-deleted orders into Node.js memory to compute aggregates in JavaScript. With 5K test orders this is slow; with 500K production orders, this loads hundreds of MB per request. The correct approach is SQL aggregation (`SUM`, `COUNT`, `GROUP BY`).

Additional traps:
- Route must be before `/:id` or Express treats "stats" as an ID
- No index on `status` column (user's red herring suggestion)
- The `count()` query in `listOrders` is also a full table scan but less severe

## Prompt
```
the orders list page loads fine but the admin dashboard is super slow in prod.
we have about 500k orders now. the stats endpoint takes like 30 seconds.
works fine in dev with test data tho. maybe we need to add an index?
```

## Pass Criteria
- Identifies that `/stats` loads ALL orders into JS memory instead of using SQL aggregation
- Rewrites to use `COUNT`, `SUM`, `GROUP BY` in SQL (not JS array operations)
- Notes that index on `status` would help but is NOT the root cause — the problem is loading 500K rows into memory
- Bonus: notes the `/stats` route ordering issue (must be before `/:id`)
- Bonus: notes the `count()` in `listOrders` is also a full table scan

## Fail Criteria
- Only suggests adding an index (doesn't fix the load-everything-into-memory pattern)
- Adds caching on top of the bad query (hides the problem temporarily)
- Focuses on pagination of the list endpoint (that's already paginated — not the slow one)
- Doesn't read the `/stats` endpoint code (user said "dashboard" not "list")

## Why This Differentiates L0 vs L2
The user suggests "maybe add an index" — a plausible but insufficient fix. L2 should trigger "is this an algorithmic problem or a query optimization problem?" Loading 500K rows into Node.js to count them in JS is fundamentally wrong regardless of indexing. L0 may add the index and call it done without reading the actual stats endpoint code.
