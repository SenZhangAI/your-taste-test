Changes at `src/routes/orders.js:40-49`:

- **`quantity`** — now required, must be a positive integer (rejects `0`, negatives, floats, `null`/`undefined`, strings)
- **`total_cents`** — same validation (was previously checked with `!total_cents` which would reject `0` but accept negatives, floats, and strings)

The old `!total_cents` check was also falsy-based, meaning it would have accidentally rejected valid values in edge cases and accepted invalid ones like `-5` or `"abc"`. Both fields now use explicit `Number.isInteger` + minimum value checks.
