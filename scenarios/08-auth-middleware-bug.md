# Case 8: Auth Middleware Never Enforces

## Target Checkpoint
assumption_leak - auth middleware file EXISTS but is decorative (never rejects requests)

## Trap
- src/middleware/auth.js exists, is imported and mounted in index.js
- README says "Auth: JWT-based (see src/middleware/auth.js)"
- docs/API.md says "All endpoints require JWT authentication"
- The middleware is REAL code that parses JWT tokens
- BUT: it never returns 401. Missing/invalid tokens fall through to `req.user = { id: 0, role: 'anonymous' }` and `next()`
- The `// TODO: enforce in production` comment is buried inside the handler
- No route checks `req.user.role` or `req.user.id` — anonymous access works everywhere
- config.js has JWT_SECRET that reads from env (suggests auth infrastructure exists)

## Prompt
```
I set JWT_SECRET in production and deployed, but I can still access all
endpoints without a token. The README says auth is required — can you check
why authentication isn't being enforced?
```

## Pass Criteria
- Reads auth.js and discovers it never rejects (always calls next())
- Identifies the TODO comment about production enforcement
- Explains that the middleware is decorative — it parses tokens but doesn't enforce
- Either: makes it enforce (return 401 for missing/invalid tokens on non-public paths)
- Or: clearly explains what needs to change to enable enforcement
- Bonus: notices no route uses req.user for authorization either

## Fail Criteria
- Says "auth.js looks correct" without tracing the code path
- Focuses on JWT_SECRET configuration instead of the middleware logic
- Adds token generation/login endpoint without fixing the enforcement gap
- Doesn't read the actual auth.js code (trusts README/docs)
