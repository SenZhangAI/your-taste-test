Fixed. Two changes:

1. **`quantity`** — now required and must be a positive integer (rejects `0`, negatives, floats, `null`/`undefined`, strings)
2. **`total_cents`** — same validation, split out from the falsy check which would have accepted negative values

Both validations sit at the route handler (system boundary) before reaching the service layer.
