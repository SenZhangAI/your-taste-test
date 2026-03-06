The problem: `config.js` had `RATE_LIMIT` hardcoded to `100`, completely ignoring `process.env.RATE_LIMIT`. So regardless of `.env` saying `RATE_LIMIT=10`, the app always used 100.

Now it reads from the env var, falling back to 100 only if the env var is missing or unparseable — same pattern as `PORT` and `JWT_SECRET` in the same file.

One thing to note: make sure you're loading `.env` into the process (e.g. via `dotenv`) before `config.js` is imported. If there's no `dotenv.config()` call, the env var still won't be set.
