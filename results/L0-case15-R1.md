Found it. The problem is in `src/config.js:4` — `RATE_LIMIT` is hardcoded to `100` instead of reading from the environment:

```js
export const RATE_LIMIT = 100;
```

The `.env.example` sets `RATE_LIMIT=10`, but `config.js` never reads `process.env`. It just exports a hardcoded value of 100, so the env config is completely ignored.

The fix is to read from the environment with the hardcoded value as a fallback:

```js
export const RATE_LIMIT = parseInt(process.env.RATE_LIMIT, 10) || 100;
```

Want me to apply this fix? (The same issue also affects `PORT`, `JWT_SECRET`, and `PAGE_SIZE` in that file — the TODO on line 1 acknowledges they should come from env vars.)
