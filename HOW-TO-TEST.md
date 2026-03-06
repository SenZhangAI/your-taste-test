# How to Run the your-taste A/B Test

## Prerequisites

```bash
cd /Users/sen/ai/your-taste-test
npm install
mkdir -p data
npm run seed   # Creates 5000 test orders
```

Verify the project works:
```bash
node src/index.js &
curl "http://localhost:3000/api/orders?limit=1"
# Should show a price like $2999.00 (the bug is intentional)
kill %1
```

## Understanding the Levels

| Level | Command | What's active |
|-------|---------|---------------|
| **L0** | Raw `claude` binary, `--setting-sources ""` | No plugins, no user CLAUDE.md, no hooks |
| **L2** | `claude --plugin-dir your-taste` | your-taste plugin (SessionStart + UserPromptSubmit hooks) + user CLAUDE.md (your-taste:start/end section) |

### How the toggle works

**your-taste loads via a shell alias:**
```bash
# Your ~/.zshrc has:
alias claude='claude --plugin-dir /Users/sen/ai/your-taste'
```

**L0 bypasses this** by calling the raw binary directly:
```bash
/Users/sen/.local/bin/claude -p --setting-sources "" ...
```

**L2 uses the plugin explicitly:**
```bash
/Users/sen/.local/bin/claude --plugin-dir /Users/sen/ai/your-taste -p ...
```

Both also unset `CLAUDECODE` and `CLAUDE_CODE_ENTRYPOINT` to avoid nesting detection when running from inside a Claude Code session.

## Running Tests

### Single case
```bash
# L0 (bare Claude)
CLAUDECODE= CLAUDE_CODE_ENTRYPOINT= /Users/sen/.local/bin/claude \
  --setting-sources "" \
  -p --no-session-persistence --dangerously-skip-permissions \
  --permission-mode bypassPermissions \
  "Your prompt here"

# L2 (your-taste enabled)
CLAUDECODE= CLAUDE_CODE_ENTRYPOINT= /Users/sen/.local/bin/claude \
  --plugin-dir /Users/sen/ai/your-taste \
  -p --no-session-persistence --dangerously-skip-permissions \
  --permission-mode bypassPermissions \
  "Your prompt here"
```

### All 5 cases for one level
```bash
./run-all.sh L0    # Bare Claude
./run-all.sh L2    # With your-taste
```

Results are saved to `results/` with filenames like `L0-case3-20260306-205055.md`.

### Important: git reset between runs

The script auto-resets via `git checkout -- .` between cases, so each case starts with clean source code.

If running manually, always reset first:
```bash
git checkout -- .
```

## The 5 Test Cases

| Case | Prompt | What to look for |
|------|--------|-----------------|
| 1 | "Add date range filter to orders endpoint" | Does AI use Knex (actual) or Prisma (README claim)? |
| 2 | "Migrate orders soft-delete to use deleted_at" | Does AI scan users.js and products.js too? |
| 3 | "Increase rate limit to 500" | Does AI notice it's a dev default / wire env vars? |
| 4 | "Fix: Widget Pro shows $2999 instead of $29.99" | Does AI fix at call site or change getOrderTotal contract? |
| 5 | "Add CSV export for all orders" | Does AI consider scale (5000 rows) or just load all? |

Full pass/fail criteria are in `scenarios/01-*.md` through `scenarios/05-*.md`.

## Evaluating Results

Read each output file and score against the scenario criteria:

```
Pass   = AI avoided the trap
Fail   = AI fell into the trap
Pass+  = Passed and showed additional reasoning depth
Partial = Found the issue but fixed at wrong level
```

## Troubleshooting

**"Cannot be launched inside another Claude Code session"**
- The scripts unset `CLAUDECODE` and `CLAUDE_CODE_ENTRYPOINT`. If running from terminal, this shouldn't happen. If running from inside Claude Code, the env vars are handled by the script.

**"claude: aliased to..."**
- The scripts use the full path `/Users/sen/.local/bin/claude` to bypass the alias.

**Different results each run**
- LLM output is non-deterministic. Run 3x and take majority result for each case.
