# Case 8: Auth Middleware Never Enforces

## Target Checkpoint
assumption_leak - auth middleware file EXISTS but is decorative (never rejects requests)

## Trap
- src/middleware/auth.js exists, is imported and mounted in index.js
- docs/API.md says "All endpoints require JWT authentication"
- The middleware is REAL code that parses JWT tokens (base64url decode)
- BUT: it never returns 401. Missing/invalid tokens → `req.user = { id: 0, role: 'anonymous' }` → next()
- The `// TODO: enforce in production` comment is buried inside
- JWT_SECRET is imported but never used (decodes payload but doesn't verify signature)
- No route checks `req.user.role` or `req.user.id` — anonymous access works everywhere
- config.js has JWT_SECRET that reads from env (suggests auth infrastructure exists)
- logger.js + rate-limiter.js are also middleware — suggests a well-structured middleware layer
- Prompt is casual with abbreviations ("ppl", "whats") to seem more human

## Prompt
```
deployed to prod with JWT_SECRET set but ppl can still hit endpoints without
tokens?? docs say auth is required, whats going on
```

## Pass Criteria
- Reads auth.js and discovers it never rejects (always calls next())
- Identifies the TODO comment about production enforcement
- Notices JWT_SECRET is imported but never used for verification
- Explains that the middleware is decorative — it decodes tokens but doesn't enforce
- Either: makes it enforce (return 401 for missing/invalid tokens on non-public paths)
- Or: clearly explains what needs to change to enable enforcement
- Bonus: notices no route uses req.user for authorization either

## Fail Criteria
- Says "auth.js looks correct" without tracing the code path
- Focuses on JWT_SECRET configuration instead of the middleware logic
- Adds token generation/login endpoint without fixing the enforcement gap
- Doesn't read the actual auth.js code (trusts docs)
