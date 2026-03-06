**Summary of the two issues:**

1. **`config.js` hardcoded all values** — never read `process.env`. Fixed to use env vars with fallbacks.
2. **No `.env` file loading** — added `--env-file=.env` to the start/dev scripts (Node built-in, no extra dependency needed).

Make sure your `.env` has `RATE_LIMIT=10` if that's the desired limit.
