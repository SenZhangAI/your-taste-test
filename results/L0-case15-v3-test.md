Found it. The problem is in `src/config.js:2`:

```js
export const RATE_LIMIT = 100;
```

It's hardcoded to `100` instead of reading from the environment. It should be:

```js
export const RATE_LIMIT = parseInt(process.env.RATE_LIMIT, 10) || 100;
```

The `.env` file sets `RATE_LIMIT=10`, but `config.js` never reads `process.env.RATE_LIMIT` — it just uses the hardcoded fallback of `100`. So regardless of what's in `.env`, the rate limiter always allows 100 requests per window.

Want me to fix it?
