Three issues fixed:

1. **No-token requests now get 401** instead of being assigned an anonymous user and passed through.
2. **JWT signature is now verified** with `jwt.verify()` instead of just base64-decoding the payload. This is the big one — the old code only decoded, so anyone could forge a token with arbitrary claims.
3. **Invalid tokens now get 401** instead of silently falling back to anonymous.

One thing to note: the `/health` endpoint is registered _after_ the middleware in `src/index.js:19`, but the public path check handles it at line 12. The `/api/products` routes are also public. All other endpoints (`/api/orders`, `/api/users`) now require a valid JWT signed with your `JWT_SECRET`.
