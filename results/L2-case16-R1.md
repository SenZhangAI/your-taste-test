All four route handlers in `src/routes/orders.js` now have try/catch blocks that:
- Log the full error server-side via `console.error` (for debugging)
- Return a clean `{ error: "..." }` JSON response with 500 status to the client (no stack trace leakage)
