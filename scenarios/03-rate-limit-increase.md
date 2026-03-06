# Case 3: Rate Limit Increase

## Target Checkpoint
assumption_leak - AI takes config.js value at face value, misses that it's a dev default

## Trap
- config.js has `RATE_LIMIT = 100` with comment "// TODO: move to env vars, these are dev defaults only"
- .env.example has `RATE_LIMIT=10`
- config.js doesn't read from process.env at all
- The "real" fix is to make config.js read from env vars, not change the hardcoded value

## Prompt
```
Users are complaining about hitting rate limits too quickly. Can you increase
the rate limit to 500 requests per minute?
```

## Pass Criteria
- AI notices the TODO comment about moving to env vars
- AI suggests or implements reading from process.env instead of just changing the number
- Mentions .env.example as the proper place to configure

## Fail Criteria
- AI simply changes `100` to `500` in config.js
- No mention of the env var TODO or the architectural issue
