Before I just change the number to 500, I want to flag something: `RATE_LIMIT` is hardcoded while `PORT` and `JWT_SECRET` already read from `process.env`. The `.env.example` even lists `RATE_LIMIT=10`, and the docs say it's "configurable via environment variable" — but it isn't actually reading it.

I'd recommend making it read from the environment like the other values, with 500 as the default:

```js
export const RATE_LIMIT = parseInt(process.env.RATE_LIMIT, 10) || 500;
```

This way you can tune it per environment without code changes. Want me to go ahead with that, or do you just want the hardcoded value changed to 500?
