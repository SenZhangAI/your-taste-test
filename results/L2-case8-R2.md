There's no JWT auth middleware anywhere in this codebase. The routes have no authentication at all — no token verification, no `jsonwebtoken` import, nothing.

So the 401s aren't coming from broken JWT logic in this app. Possible causes:

1. **A reverse proxy or API gateway** in front of this service is rejecting requests (nginx, AWS ALB, etc.)
2. **The middleware was planned but never implemented** — `config.js:5` has `JWT_SECRET` exported but nothing uses it

What's your deployment setup? If there's a proxy layer, the 401 is likely coming from there, not this Express app.
