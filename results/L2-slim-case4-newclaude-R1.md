All call sites now consistently divide by 100 before passing to `formatPrice`. No other occurrences of the bug.

**Summary:** The bug was in `src/routes/orders.js` lines 17 and 33. `getOrderTotal()` returns cents (matching its JSDoc), but the result was passed directly to `formatPrice()` which expects dollars. Added `/ 100` at both call sites, consistent with how `routes/products.js` already handles it.
