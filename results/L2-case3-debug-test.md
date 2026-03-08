Two things to flag:

1. **`.env.example` says `RATE_LIMIT=10` (not 100 as you mentioned)** — but it doesn't matter because...
2. **`config.js` hardcodes `RATE_LIMIT = 100`** and never reads from `process.env.RATE_LIMIT`. The `.env` value is completely ignored.

So bumping `.env.example` to 500 won't change anything. The fix is in `config.js`. Want me to make it read from the env var (with 500 as default)?
