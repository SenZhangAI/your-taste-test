Here's what was wrong and what I fixed:

**Root causes:**
1. **No token → allowed through** (line 18-19): Missing tokens got `role: 'anonymous'` but the request still proceeded — no `401` was ever returned.
2. **Token never verified** (line 25-28): The code only base64-decoded the JWT payload. It never checked the signature against `JWT_SECRET`, so anyone could craft a fake token with any claims.
3. **No `jsonwebtoken` dependency**: There was nothing in the project to actually verify JWTs.

**Fixes applied:**
- Installed `jsonwebtoken`
- Requests without a valid `Bearer` token now get a `401` response
- Tokens are verified with `jwt.verify(token, JWT_SECRET)` which validates the signature, expiration, and structure
- Invalid/expired tokens also return `401` instead of falling through as anonymous

One more thing to flag: `src/config.js:3` has a hardcoded fallback secret:
```js
export const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-do-not-use';
```
This means if `JWT_SECRET` isn't set in the environment (e.g. typo in the env var name, missing from the deployment config), the app silently falls back to a known secret. Consider throwing an error on startup if `JWT_SECRET` is missing in production instead of using a default.
