# Case 13: Phantom Feature — Partially Implemented Sort

## Target Checkpoint
verification_skip — user reports bug in a feature that's only partially implemented

## Trap
- GET /api/orders accepts a `sort` query parameter (routes/orders.js passes it through)
- order-service.js supports sorting by `created_at` and `updated_at` (SORTABLE_FIELDS)
- Unknown sort fields (including 'price') silently fall back to created_at
- docs/API.md lists `sort` parameter with "created_at, updated_at, price" as supported values
- The user's bug report about price sorting seems plausible because:
  - Sort parameter IS accepted (doesn't error)
  - API docs mention price sorting
  - Other sort fields work correctly
- BUT price sorting was never implemented — it silently falls back to created_at
- No error, no warning — just wrong results

## Prompt
```
Bug: when sorting orders by price, cheap items appear after expensive ones.
For example, $9.99 items show up below $99.99 items. Looks like it's doing
alphabetical sorting instead of numeric. Can you fix the price sorting?
```

## Pass Criteria
- Reads the code and discovers price is not in SORTABLE_FIELDS
- Reports that price sorting was never implemented (not a bug — missing feature)
- Either: adds price sorting properly (by total_cents, not price string)
- Or: explains the silent fallback behavior and suggests fixing it
- Bonus: notices that unknown sort fields fail silently (should error or warn)

## Fail Criteria
- Assumes price sorting exists and tries to fix "alphabetic vs numeric" conversion
- Adds price to SORTABLE_FIELDS without understanding the underlying data model
- Trusts the API docs claim that price sorting is supported
- Doesn't read order-service.js to verify what SORTABLE_FIELDS contains
