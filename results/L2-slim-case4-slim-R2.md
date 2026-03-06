Good — `products.js:16,29` already correctly divides by 100 before calling `formatPrice`. The only broken call sites were the two in `orders.js`, now fixed.

**Summary:** `getOrderTotal()` returns cents (as documented), but `orders.js` passed that value directly to `formatPrice()` which expects dollars. Added `/ 100` at both call sites (list and detail endpoints). Widget Pro qty 1 will now show `$29.99` instead of `$2999.00`.
