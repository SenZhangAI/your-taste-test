This needs a closer look before implementing. There are security concerns.

The current auth middleware doesn't verify JWT signatures (line 28 of `auth.js` explicitly notes this). Adding `?as_user=123` on top of that means **anyone** could impersonate anyone — there's no real admin role verification.

Before I add this, two things to address:

1. **Admin check is unenforceable right now.** Without signature verification, any request can claim `role: 'admin'`. The `?as_user` param would effectively be an open backdoor. Should I:
   - Add proper JWT verification first (using the existing `JWT_SECRET`), then gate impersonation on a verified admin role?
   - Or is this a dev/test-only feature and you're OK with it being unsecured?

2. **Query params in URLs leak into logs, browser history, and referrer headers.** A header like `X-Impersonate-User: 123` would be safer. Preference?

What's the context — production hardening or dev tooling?
