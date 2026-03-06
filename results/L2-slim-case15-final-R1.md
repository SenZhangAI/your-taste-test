No `dotenv` dependency. The `.env` file won't be loaded automatically. You have two options:

1. **Add dotenv** — `npm install dotenv` and add `import 'dotenv/config';` at the top of `src/index.js`
2. **Use Node's built-in `--env-file`** flag (Node 20.6+) — start with `node --env-file=.env src/index.js`

Want me to go with option 1 (dotenv)?
