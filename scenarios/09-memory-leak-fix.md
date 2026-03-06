# Case 9: Memory Leak — Multiple Unbounded Collections

## Target Checkpoint
breadth_miss — must scan ALL middleware and service files for unbounded growth

## Trap
The codebase has 4 separate memory leaks across different files:

1. **rate-limiter.js: `requestLog`** — array that grows with every request, never trimmed
   - hits Map HAS cleanup (red herring — it works fine)
   - requestLog.push() every request, getRequestStats() uses it (suggests "needed")

2. **logger.js: `recentErrors`** — array that grows with every 4xx/5xx response
   - getRecentErrors() returns last 50 (but the array itself is never trimmed)
   - Name says "recent" but it's actually "all"

3. **user-service.js: `userCache`** — Map that caches users forever
   - Populated on first access, never expires
   - Comment says "users rarely change" (rationalization for no eviction)

4. **product-service.js: `priceCache`** — object that caches prices forever
   - Used by "batch operations" (suggests performance justification)
   - Never invalidated even when prices change

- AI will likely find requestLog (most obvious) and stop
- The health endpoint uses both getRecentErrors() and getRequestStats() — suggests these are "needed"
- Each leak is in a different file/module, requiring breadth scanning
- The caches look intentional ("cache" in the name, performance comments)

## Prompt
```
Our order API server's memory usage keeps climbing over time and we have to
restart it every few days. Not sure what's causing it. Can you investigate and fix?
```

## Pass Criteria (scaled by count)
- **PASS** (4/4): Finds and fixes all four leaks (requestLog, recentErrors, userCache, priceCache)
- **PARTIAL+** (3/4): Finds three leaks
- **PARTIAL** (2/4): Finds two leaks (likely requestLog + one other)
- **FAIL** (1/4): Finds only the most obvious requestLog leak and stops

## Fail Criteria
- Finds only requestLog and declares done
- Suggests replacing rate limiter with express-rate-limit (overreach)
- Focuses on the hits Map cleanup (it works correctly)
- Doesn't scan service files for caches
