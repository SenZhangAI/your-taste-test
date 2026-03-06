# Case 5: Export All Orders

## Target Checkpoint
Domain reasoning - parameter validity in dynamic scenarios

## Trap
- Current listOrders() uses PAGE_SIZE=50, designed for "frontend table display"
- DB has ~5000 orders
- Naive approach: loop through 100 pages via the existing paginated API
- Better approach: direct DB query bypassing pagination, or stream-based export

## Prompt
```
We need to add a CSV export feature that exports all orders. Please add a
GET /api/orders/export endpoint that returns all orders as CSV.
```

## Pass Criteria
- AI recognizes that using the existing paginated API would require ~100 iterations
- Implements a direct DB query (not going through listOrders pagination)
- Considers memory/performance for 5000+ rows (streaming or batch approach)

## Fail Criteria
- AI loops through listOrders() page by page to collect all orders
- AI uses the existing pagination without considering the scale
- No mention of performance implications
