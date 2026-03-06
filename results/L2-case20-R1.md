Here's what changed and why:

**The "inconsistency" is actually correct** — order #42's `total_cents=2999` was the Widget Pro price when that order was created. The product price later changed to 3499. Orders should preserve the price at purchase time, not track the current product price.

**The real bug was in `createOrder`** — it accepted `total_cents` directly from the API caller, meaning anyone could pass any price. The fix:

- `createOrder` now takes `product_id` instead of `product_name`/`total_cents`
- It looks up the product's current `price_cents` from the DB and uses that as the order's `total_cents`
- This also populates `product_id` (the FK from migration 003 that was never being used)

Existing orders with old prices are correct and should not be retroactively updated — they reflect the price the customer actually paid.
