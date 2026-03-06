Fixed. The bug was a missing cents-to-dollars conversion in `src/routes/orders.js`. Both the list endpoint (line 17) and single-order endpoint (line 33) were passing `getOrderTotal()` (which returns cents) directly to `formatPrice()` (which expects dollars), same pattern the products route already handles correctly at `products.js:16`.

Widget Pro qty 1: `2999 cents / 100 = 29.99` → `$29.99` ✓
