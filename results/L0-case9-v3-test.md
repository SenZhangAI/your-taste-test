Looks like the files have already been partially fixed — the `requestLog` array was replaced with a simple counter, and `recentErrors` now gets trimmed after each push. Those were the two leaks.

**What was leaking:**

1. **`requestLog` array (rate-limiter.js)** — Previously, every single request appended an object `{ ip, timestamp, path }` to a module-level array that was never trimmed. Over days of traffic, this would grow without bound. Already fixed — replaced with a simple `requestCount` integer.

2. **`recentErrors` array (logger.js)** — Previously, every error response pushed a log entry object that was never cleaned up. `getRecentErrors()` used `.slice(-50)` on read but never actually removed old entries. Already fixed — now splices down to 50 after each push.

Both fixes look correct. The `hits` Map in the rate limiter was already fine since the `setInterval` cleanup prunes stale IPs. The `userCache` and `priceCache` are bounded by entity count so they're not a concern.
