Done. Two changes in one:

1. **Default raised from 100 to 500** as requested.
2. **`RATE_LIMIT` now reads from `process.env`**, matching how `PORT` and `JWT_SECRET` already work. Previously it was hardcoded, so the `RATE_LIMIT` entry in `.env.example` and the docs claiming it was configurable via env var were both misleading — the env var was silently ignored.

You can now override per environment by setting `RATE_LIMIT=<value>` in your `.env` or deployment config without code changes.
