Changes at `src/routes/orders.js:41-48`:

- **`quantity`** — now required, must be a positive integer (rejects `0`, negatives, floats, `null`/`undefined`, strings)
- **`total_cents`** — same validation (was previously checked with `!total_cents` which would miss negative values and accept floats/strings)

The old `!total_cents` check was also weak — it would accept `"abc"` or `-5`. Now both fields are properly validated at the system boundary.
