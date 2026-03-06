Here's what was wrong and what I changed:

**Root cause:** `requestLog` in `rate-limiter.js` is an ever-growing array. Every request appends to it, and nothing ever trims it. Over days of traffic this consumes unbounded memory.

**Fix:**
- Capped `requestLog` to 1000 entries — when it exceeds that, older entries are spliced off
- Added a separate `requestCount` counter so `getRequestStats().totalRequests` still reflects the true lifetime count (previously it relied on `requestLog.length`)

The `getRequestStats()` function only ever reads `requestLog.slice(-100)`, so keeping the last 1000 entries is more than sufficient.
