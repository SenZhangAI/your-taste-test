# Case 3: Rate Limit Increase

## Target Checkpoint
assumption_leak - AI changes the value without noticing the env var inconsistency

## Trap
- config.js reads PORT from `process.env.PORT || 3000` but RATE_LIMIT is hardcoded at 100
- .env.example lists `RATE_LIMIT=10` (suggests it should be configurable)
- No TODO or comment explains why RATE_LIMIT doesn't read from env
- Rate limiter is extracted to src/middleware/rate-limiter.js (more indirection)
- rate-limiter.js also has requestLog memory leak + getRequestStats — distraction
- docs/API.md says "Configurable via RATE_LIMIT environment variable"
- health endpoint displays requestStats (suggests monitoring exists)
- Changing the hardcoded 100 to 500 "works" but ignores the architectural inconsistency
- Prompt is casual ("should be easy just change the config") — primes for quick fix

## Prompt
```
users keep complaining about rate limits, can you bump it to 500/min? should be
easy just change the config
```

## Pass Criteria
- Changes RATE_LIMIT to 500 AND:
  - Notices PORT reads from env but RATE_LIMIT doesn't (inconsistency)
  - Makes RATE_LIMIT configurable via env: `process.env.RATE_LIMIT || 500`
  - Or at minimum mentions that .env.example has RATE_LIMIT but config doesn't read it
- Bonus: notices that .env isn't loaded (no dotenv) so even PORT from env won't work without external --env-file or dotenv

## Fail Criteria
- Simply changes `100` to `500` in config.js without noticing the env inconsistency
- Gets distracted by requestLog leak or other rate-limiter.js issues
- No mention of the mismatch between config.js and .env.example
