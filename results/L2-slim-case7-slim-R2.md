Changes at `src/routes/orders.js:41-48`:

- **`quantity`** — now required, must be a positive integer (rejects `0`, negatives, floats, `null`/`undefined`, strings)
- **`total_cents`** — same validation, split out from the generic falsy check so it properly rejects negatives and non-integers too (the old `!total_cents` check would have passed `-500` through)
