Fixed both the list endpoint (line 17) and single order endpoint (line 33). The issue was that `getOrderTotal()` returns cents (as documented), but the result was passed directly to `formatPrice()` which expects dollars. The products route already had the correct `/ 100` conversion — orders was missing it.

Widget Pro: `2999 cents * 1 qty = 2999 cents → / 100 → $29.99`
