# Evaluation Guide

## How to Run Tests

### Prerequisites
```bash
cd /Users/sen/ai/your-taste-test
npm install
mkdir -p data
npm run seed
```

### Quick Test (single case)
```bash
# 1. Configure level (see test-runner.sh output for checklist)
# 2. Run:
./test-runner.sh L0 1    # Bare Claude, Case 1
./test-runner.sh L1 1    # Basic CLAUDE.md, Case 1
./test-runner.sh L2 1    # your-taste enabled, Case 1
```

### Full Matrix
```bash
for level in L0 L1 L2; do
  for case_num in 1 2 3 4 5; do
    # Configure level first, then:
    ./test-runner.sh $level $case_num
  done
done
```

Run each combination 3 times for statistical reliability.

## Level Configuration Checklist

### L0 (Bare Claude)
- [ ] Rename `CLAUDE.md` -> `CLAUDE.md.bak` (in project dir)
- [ ] `~/.claude/settings.json`: set `"your-taste@SenZhangAI": false` in enabledPlugins
  - Or temporarily uninstall: `claude plugin uninstall your-taste@SenZhangAI`
- [ ] `~/.claude/CLAUDE.md`: remove or comment out `<!-- your-taste:start -->` to `<!-- your-taste:end -->` block

### L1 (Basic instructions only)
- [ ] `CLAUDE.md` has L1 baseline content (the 2-line version)
- [ ] Same plugin/taste disabling as L0

### L2 (your-taste enabled)
- [ ] `CLAUDE.md` has L1 baseline content
- [ ] your-taste plugin enabled
- [ ] `~/.claude/CLAUDE.md` has your-taste:start/end block
- [ ] `~/.your-taste/observations.md` exists with evolved content

## Scoring

For each result file, score Pass/Fail per the scenario criteria:

| Case | Pass Signal | Fail Signal |
|------|------------|-------------|
| 1 | Uses Knex syntax | Uses Prisma syntax |
| 2 | Mentions other route files | Only modifies orders |
| 3 | Mentions env vars / TODO comment | Just changes the number |
| 4 | Traces cents/dollars mismatch | Patches at wrong level |
| 5 | Direct DB query or mentions scale | Loops paginated API |

## Results Template

```
| Case | L0-r1 | L0-r2 | L0-r3 | L1-r1 | L1-r2 | L1-r3 | L2-r1 | L2-r2 | L2-r3 |
|------|-------|-------|-------|-------|-------|-------|-------|-------|-------|
| 1    |       |       |       |       |       |       |       |       |       |
| 2    |       |       |       |       |       |       |       |       |       |
| 3    |       |       |       |       |       |       |       |       |       |
| 4    |       |       |       |       |       |       |       |       |       |
| 5    |       |       |       |       |       |       |       |       |       |
```
