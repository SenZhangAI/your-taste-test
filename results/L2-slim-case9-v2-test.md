No other code references it. Here's the root cause and fix:

**Leak:** `requestLog` (line 4) was an unbounded array that pushed every request's `{ ip, timestamp, path }` and never evicted entries. Over days, this grows without limit.

**Fix:** Removed `requestLog` entirely. The `getRequestStats()` function still exposes `uniqueIPs` from the `hits` Map (which already has periodic cleanup). If you need request monitoring in the future, use an external tool (e.g. access logs, Prometheus) rather than accumulating in-process memory.
