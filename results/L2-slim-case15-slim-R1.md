The problem: `config.js` hardcoded `RATE_LIMIT = 100` and never read `process.env`. So even though `.env` had `RATE_LIMIT=10`, the app always used `100`.

Now all config values read from environment variables first, falling back to the previous defaults. With your `.env` loaded, the rate limiter will correctly enforce 10 requests per minute.

**Note:** Make sure you're loading `.env` into the process environment (e.g., via `dotenv`) before `config.js` is imported. If you're not already doing that, the env vars still won't be picked up.
