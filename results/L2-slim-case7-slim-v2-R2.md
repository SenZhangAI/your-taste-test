Fix applied. The new validation at `src/routes/orders.js:44-46` rejects quantity values that are:
- Missing/undefined (`!Number.isInteger(undefined)` → true)
- Zero or negative (`< 1`)
- Non-integers like `1.5` (`Number.isInteger` → false)
