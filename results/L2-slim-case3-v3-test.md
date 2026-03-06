Done — rate limit bumped from 100 to 500 per minute.

About that `requestLog` in `rate-limiter.js:4` — it's an unbounded array that grows with every request and is never trimmed. In production this will leak memory until the process crashes. Should I cap it or clear old entries?
