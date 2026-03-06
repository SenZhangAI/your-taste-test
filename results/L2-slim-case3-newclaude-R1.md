`.env.example` already has `RATE_LIMIT=500`, so no change needed there.

**What changed:**

- **`src/config.js`** — All config values now read from `process.env` with fallback defaults (resolving the existing TODO). `RATE_LIMIT` defaults to **500** (up from 100).
- Removed the TODO comment since it's now addressed.

To override per environment, set `RATE_LIMIT=500` (or any value) in your `.env` or deployment config without code changes. Same applies to `PORT`, `JWT_SECRET`, and `PAGE_SIZE`.
