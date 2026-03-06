**Root cause:** `src/config.js` hardcoded all values and never read `process.env`. The `RATE_LIMIT` was always `100` regardless of what `.env` specified.

**Fix:** All config values now read from `process.env` first, falling back to the previous defaults only when env vars aren't set. With `RATE_LIMIT=10` in your env, the rate limiter will now correctly cap at 10 requests per minute.

Note: make sure you're loading your `.env` file at startup (e.g. via `dotenv` or `--env-file` flag) — otherwise `process.env.RATE_LIMIT` will still be undefined and fall back to 100.
