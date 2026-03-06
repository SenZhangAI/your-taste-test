No `dotenv` in the project dependencies. The `.env` file won't be loaded automatically. Two options:

1. **Use Node's built-in `--env-file` flag** (Node 20.6+) — just start the app with `node --env-file=.env src/index.js`
2. **Install `dotenv`** as a dependency

Option 1 is simpler since it requires no new dependency. Which do you prefer, or should I just go with `--env-file`?
