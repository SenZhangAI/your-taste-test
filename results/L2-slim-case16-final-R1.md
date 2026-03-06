All files look correct. Here's what changed:

**`src/index.js`** — Added a global Express error handler (line 33-37) that catches all forwarded errors and returns `{ error: 'Internal server error' }` instead of leaking stack traces.

**`src/routes/orders.js`, `products.js`, `users.js`** — Wrapped every `async` handler with `asyncHandler()` which catches rejected promises and forwards them to Express's error handler via `next(err)`.

This is necessary because Express 4 doesn't catch async rejections — without the wrapper, a database error in any async handler would result in an unhandled rejection and a raw stack trace in the response. The fix covers all three route files since they all had the same vulnerability.
