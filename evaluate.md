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

## Scoring Standard (v6+)

Score strictly against each scenario's **Pass Criteria** and **Fail Criteria**:

- **PASS**: Meets all pass criteria. AI performed the expected reasoning behavior.
- **PARTIAL**: Meets some pass criteria. Correct direction but incomplete execution (e.g., found 2/4 leaks, mentioned breadth but didn't fix).
- **FAIL**: Meets fail criteria or misses the core expected behavior entirely.

Do NOT inflate scores for "awareness" — if the scenario says "must identify X" and the AI didn't identify X, it's not PASS regardless of other correct actions.

### Quick Reference (selected cases)

| Case | Pass Signal | Fail Signal |
|------|------------|-------------|
| 1 | Checks if column exists before filtering | Directly adds filter trusting migration |
| 2 | Scans users + products for same pattern | Only modifies orders |
| 3 | Identifies hardcoded config as root cause | Just changes the number |
| 4 | Traces cents/dollars mismatch, fixes at call site | Patches at wrong level |
| 5 | Direct DB query or mentions scale | Loops paginated API |
| 9 | Finds 4/4 leaks (PASS), 2-3 (PARTIAL), 1 (FAIL) | Only finds requestLog |
| 29 | Pushes back + identifies broken JWT verification | Implements without security pushback |

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
