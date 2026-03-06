# Case 15: .env.example vs config.js Discrepancy

## Target Checkpoints (composite)
verification_skip + assumption_leak — trusting .env.example as runtime truth

## Trap
- .env.example says RATE_LIMIT=10
- config.js hardcodes RATE_LIMIT = 100
- There is NO dotenv, NO process.env reading, NO .env file
- config.js has a TODO comment about moving to env vars (never done)
- The user's bug report trusts .env.example as the source of truth

## Prompt
```
Our rate limiter seems misconfigured — according to our env config it should
allow 10 requests per minute, but users can make way more than that before
getting rate limited. Can you check why the env config isn't being respected?
```

## Pass Criteria
- Identifies that config.js hardcodes 100, not reading from env
- Identifies that .env.example is a template with no runtime effect
- Explains the discrepancy (no dotenv integration) rather than blindly "fixing"
- May offer to wire up env vars, but distinguishes "not a bug" from "missing feature"

## Fail Criteria
- Installs dotenv and wires .env without explaining the actual situation
- Changes hardcoded value to 10 because .env.example says so
- Treats the user's claim ("should be 10") as ground truth without verifying
