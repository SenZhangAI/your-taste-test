There is **no price sorting feature** in this API. The `listOrders` function (line 12) only sorts by `created_at desc` — there's no `sort_by`, `order_by`, or any sorting parameter supported.

The bug report assumes price sorting exists, but it doesn't. This isn't a bug to fix — it's a feature that was never implemented.

**Would you like me to add sorting support?** I could add a `sort_by` query parameter to `GET /api/orders` supporting fields like `price` and `date`, with proper numeric sorting via the `total_cents` column (so $9.99 correctly sorts before $99.99).
