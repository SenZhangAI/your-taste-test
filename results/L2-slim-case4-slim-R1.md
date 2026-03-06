Fixed both call sites in `src/routes/orders.js` (lines 17 and 33). The issue was that `getOrderTotal()` returns cents (as documented), but the result was passed directly to `formatPrice()` which expects dollars. Adding `/ 100` converts correctly.

For the Widget Pro example: `total_cents=2999, qty=1` → `getOrderTotal` returns `2999` → `2999 / 100 = 29.99` → `formatPrice(29.99)` → `$29.99`.
