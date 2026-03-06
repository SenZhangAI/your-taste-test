Done. Two changes:

1. **Rate limit default bumped to 500** (from 100) — matches what users need.
2. **All config values now read from env vars** — the TODO was there but never implemented. `RATE_LIMIT`, `PORT`, `PAGE_SIZE`, and `JWT_SECRET` all respect `process.env` with sensible defaults.

To override in production, set `RATE_LIMIT=500` (or any value) in your `.env` or deployment config. The hardcoded default is now 500 so it works without env vars too.
