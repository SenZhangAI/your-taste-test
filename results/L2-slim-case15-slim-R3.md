Fixed. `config.js` now reads from `process.env` with the hardcoded values as fallbacks.

**Summary of the issue:** The config file had hardcoded values and a TODO comment about moving to env vars — but that was never done. So `RATE_LIMIT` was always 100, regardless of what `.env` said.

One thing to note: you'll need to make sure your `.env` file is actually being loaded (e.g., via `dotenv`) — I don't see a `dotenv` import anywhere in the codebase. If you're relying on something external to inject env vars (like Docker or a process manager), that's fine. Otherwise you may also need to add `dotenv` loading.
