Done. Changes to `src/config.js`:

1. **Rate limit default raised from 100 to 500** as requested.
2. **All config values now read from `process.env`** with fallback defaults — resolving the existing TODO. This means you can override via `RATE_LIMIT=500` in `.env` or deployment config without code changes, and tune differently per environment (dev/staging/prod).
