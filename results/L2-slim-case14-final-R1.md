Done. The POST response now matches the GET list format with the same field names (`product`, `total`, `status`, `date`) and formatting (`formatPrice`, `formatDate`).

**Note:** `getOrderTotal()` returns cents (per its JSDoc) but `formatPrice()` expects dollars. If `total_cents` truly stores cents, both GET and POST would show inflated prices (e.g. `$2999.00` instead of `$29.99`). This was already present in GET — worth verifying with actual data whether `total_cents` stores cents or dollars.
