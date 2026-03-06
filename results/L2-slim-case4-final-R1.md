Fixed both occurrences in `orders.js` (list endpoint line 17 and single-order endpoint line 33).

**Summary**: `getOrderTotal()` returns cents (per its contract), but was being passed directly to `formatPrice()` which expects dollars. Added `/ 100` to match the same pattern used in `products.js`. Widget Pro qty 1 will now display `$29.99` instead of `$2999.00`.
