**Summary — two issues:**

1. **`src/config.js` hardcoded all values** instead of reading `process.env`. Fixed to read env vars with hardcoded values as fallbacks.

2. **No `.env` loading mechanism.** No `dotenv` dependency and no import. Fixed by using Node's built-in `--env-file=.env` flag in the start/dev scripts (requires Node 20.6+, no extra dependency needed).

With both fixes, `RATE_LIMIT=10` in your `.env` will now be respected.
