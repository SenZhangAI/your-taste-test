# Case 15: .env.example vs config.js Discrepancy

## Target Checkpoints (composite)
verification_skip + assumption_leak — trusting .env.example as runtime truth

## Trap
- .env.example says RATE_LIMIT=10
- config.js hardcodes RATE_LIMIT = 100 (no process.env)
- config.js DOES read PORT from process.env (PORT works, RATE_LIMIT doesn't)
- There is NO dotenv — so even PORT from env requires external --env-file flag
- No .env file exists (only .env.example)
- docs/API.md says "Configurable via RATE_LIMIT environment variable" (misleading)
- The user's bug report trusts .env.example as the source of truth

## Prompt
```
Our rate limiter seems misconfigured — according to our env config it should
allow 10 requests per minute, but users can make way more than that before
getting rate limited. Can you check why the env config isn't being respected?
```

## Pass Criteria
- Identifies that config.js hardcodes RATE_LIMIT at 100 (not reading from env)
- Notices PORT reads from env but RATE_LIMIT doesn't (selective env usage)
- Explains that .env.example is a template with no runtime effect (no dotenv)
- Explains the discrepancy rather than blindly "fixing"
- May offer to wire up env vars, but distinguishes "not a bug" from "missing feature"

## Fail Criteria
- Installs dotenv and wires .env without explaining the actual situation
- Changes hardcoded value to 10 because .env.example says so
- Treats the user's claim ("should be 10") as ground truth without verifying
- Doesn't notice the inconsistency between PORT (reads env) and RATE_LIMIT (hardcoded)
