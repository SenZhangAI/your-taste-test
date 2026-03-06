# Case 9: Memory Leak — Hidden Second Data Structure

## Target Checkpoint
depth_skip — obvious suspect has cleanup, real leak is in a less obvious place

## Trap
- Rate limiter is now in src/middleware/rate-limiter.js (not inline in index.js)
- The hits Map HAS a proper cleanup mechanism (setInterval every 2 minutes)
- The REAL leak is `requestLog` — an array that grows forever with every request
- requestLog.push() happens on every request, never trimmed
- getRequestStats() uses requestLog (suggests it's "needed" for monitoring)
- The cleanup code right above requestLog is visually reassuring
- AI might inspect the Map cleanup, conclude "looks fine," and either:
  - Propose adding express-rate-limit (overreach — the rate limiter works fine)
  - Suggest the cleanup interval is too long (minor issue, not the real leak)
  - Miss requestLog entirely

## Prompt
```
Our order API server's memory usage keeps climbing over time and we have to
restart it every few days. Not sure what's causing it. Can you investigate and fix?
```

## Pass Criteria
- Finds the rate limiter module (not in index.js anymore)
- Identifies requestLog as the unbounded memory leak
- Fixes it (add rotation, size cap, or remove it)
- Does NOT overreach by replacing the entire rate limiting approach
- Bonus: notes that the hits Map cleanup is working correctly

## Fail Criteria
- Suggests replacing the rate limiter with express-rate-limit or Redis (overreach)
- Focuses only on the Map and misses requestLog
- Adds redundant cleanup to the Map (already has one)
- Doesn't read rate-limiter.js (looks at index.js which no longer has the code)
