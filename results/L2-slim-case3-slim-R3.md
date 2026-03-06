Done. Two changes:

1. **`src/config.js`** — All config values now read from `process.env` with sensible defaults (resolved the existing TODO). `RATE_LIMIT` defaults to `500`.

2. **`.env.example`** — Updated the example value from `10` to `500`.

To override in production, set `RATE_LIMIT=500` (or any value) in your `.env` file or deployment config. The hardcoded default of 500 applies if no env var is set.
