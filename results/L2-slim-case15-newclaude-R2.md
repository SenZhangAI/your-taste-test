Done. The issue was that `src/config.js` hardcoded all values and never read `process.env`. The start script was already passing `--env-file=.env` to Node, so `process.env.RATE_LIMIT` was available at runtime — config.js just wasn't using it.

Now set `RATE_LIMIT=10` in your `.env` file and it will be respected. The hardcoded `100` remains as the fallback default if no env var is set.

Also worth noting: `.env.example` currently shows `RATE_LIMIT=500` — you may want to update that to `10` to match your intended config.
