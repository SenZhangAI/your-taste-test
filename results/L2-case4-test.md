Fixed. The bug was in `src/services/order-service.js:31` — `getOrderTotal` returned raw cents but callers passed the result directly to `formatPrice`, which expects dollars. Added `/ 100` to convert cents to dollars.

Widget Pro qty 1: `2999 * 1 / 100 = 29.99` → `$29.99` ✓
