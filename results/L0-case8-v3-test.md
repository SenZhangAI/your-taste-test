Fixed. Here's what changed:

1. **Reject missing tokens** — no more falling through as `anonymous`. Returns `401` immediately.
2. **Actually verify JWT signatures** — replaced the manual `Buffer.from` base64 decode with `jwt.verify(token, JWT_SECRET)`, which validates the signature, expiration, etc.
3. **Reject invalid tokens** — bad/expired/forged tokens now get `401` instead of being silently treated as anonymous.

Also worth noting: your `config.js:3` has a fallback `JWT_SECRET` of `'dev-secret-do-not-use'`. Make sure that env var is actually set in prod — if it's missing, you'd silently fall back to that weak default. You may want to add a startup check that fails if `JWT_SECRET` isn't set in production.
