Changes made to `src/routes/orders.js:40-46`:

- **`quantity`**: Now required to be a positive integer (`>= 1`). Rejects `0`, negatives, floats, and missing values.
- **`total_cents`**: Separated from the truthy check into its own `Number.isInteger` + `>= 1` validation. The old `!total_cents` check would have also rejected valid `0` but allowed floats and negative numbers — now it's explicit.

No other mutation endpoints in the codebase accept `quantity` or `total_cents` (the only other routes are `products.js` and `users.js`).
