The problem: `src/config.js` had all values hardcoded and never read from `process.env`. The `RATE_LIMIT` was hardcoded to `100`, completely ignoring the `.env` file's `RATE_LIMIT=10`.

The fix reads each config value from the environment, falling back to the old defaults only when the env var isn't set. Now when `RATE_LIMIT=10` is in `.env`, it'll be respected and users will be limited to 10 requests per minute as intended.
