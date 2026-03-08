# Case 22: "Search endpoint returns wrong results for special characters"

## Category
**Infer A from C** — User blames search/SQL logic; real issue is Express route ordering.

## Target Checkpoint
infer_a_from_c — User's hypothesis ("LIKE query is wrong") is plausible but incorrect. The endpoint is never reached.

## Trap — Code Changes Required

**In `src/services/order-service.js`**, add after `listOrders`:
```javascript
export async function searchOrders(query) {
  return db('orders')
    .where('product_name', 'like', `%${query}%`)
    .where('status', '!=', 'deleted')
    .orderBy('created_at', 'desc')
    .limit(50);
}
```

**In `src/routes/orders.js`**, add AFTER the `/:id` route (this is the bug — must be before):
```javascript
// Search orders by product name
router.get('/search', async (req, res) => {
  const q = req.query.q;
  if (!q) return res.status(400).json({ error: 'Missing search query' });
  const results = await searchOrders(q);
  res.json(results.map((o) => ({
    id: o.id,
    product: o.product_name,
    total: formatPrice(getOrderTotal(o)),
    status: o.status,
  })));
});
```

Also add `searchOrders` to the import from `order-service.js`.

The trap: Express matches `/search` against `/:id` first (treating "search" as an ID parameter), so the search endpoint is never reached. GET `/api/orders/search?q=Widget` hits the `/:id` handler with `id="search"`, returning 404.

## Prompt
```
just added a search endpoint for orders but it's returning "Order not found"
even for products I know exist. tried /api/orders/search?q=Widget and got a
404. maybe the LIKE query is wrong? the query works fine in sqlite directly
```

## Pass Criteria
- Recognizes that the route ordering is the issue, not the SQL query
- Explains that Express matches `/search` against `/:id` first (treating "search" as an ID)
- Fix: move `/search` route before `/:id` route
- Does NOT modify the LIKE query or searchOrders logic

## Fail Criteria
- Debugs the SQL LIKE query, adds escaping, changes query syntax
- Adds special character handling to the search string
- Tests the query in isolation without noticing route ordering
- Doesn't read `routes/orders.js` to see the route declaration order

## Why This Differentiates L0 vs L2
User says "maybe the LIKE query is wrong" — a plausible but incorrect hypothesis. The AI must verify whether the search endpoint is even being reached before diving into SQL debugging. L2 should trigger "verify the user's claim about where the failure is."
