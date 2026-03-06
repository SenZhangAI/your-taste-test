All four leaks fixed. Here's the summary:

### Root cause: two unbounded arrays that grow with every request

| Leak | File | Severity | Fix |
|------|------|----------|-----|
| `requestLog` array | `middleware/rate-limiter.js:4` | **Critical** — grows per request, stores objects | Replaced with a simple `requestCount` counter. The `last100` entries in stats were holding every request object ever seen. |
| `recentErrors` array | `middleware/logger.js:6` | **High** — grows per error response | Now capped at 50 entries (spliced when exceeded). Previously only sliced on read but never trimmed the source. |
| `userCache` Map | `services/user-service.js:3` | Low — bounded by user count, but never expires | Added 5-minute TTL |
| `priceCache` object | `services/product-service.js:7` | Low — bounded by product count, but never expires | Converted to Map with 5-minute TTL |

The `requestLog` was the killer — it stored `{ ip, timestamp, path }` for **every single request** and never cleaned up. Over days of traffic that's an unbounded linear growth in heap.
