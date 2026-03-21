# How to Run the your-taste A/B Test

## Prerequisites

```bash
cd your-taste-test
npm install
mkdir -p data
npm run seed   # Creates 5000 test orders
```

## Test Levels

| Level | What it is | Injection |
|-------|-----------|-----------|
| **L0** | Bare Claude | None — no CLAUDE.md, no plugin |
| **L0-deep** | Bare Claude + `--effort high` | None — tests if thinking time substitutes for guidance |
| **L1** | Standalone CLAUDE.md | ~6.8K chars, loaded once at session start |
| **L2** | Full plugin | SessionStart + UserPromptSubmit hooks + user CLAUDE.md |

## Running Tests

### Single case
```bash
./test-runner.sh L0 9              # bare Claude, Case 9
./test-runner.sh L0-deep 9         # bare + extended thinking
./test-runner.sh L1 9              # standalone CLAUDE.md (no plugin)
./test-runner.sh L2 9              # full plugin
```

### All 30 cases (batch)
```bash
./run-all.sh L2                    # serial, all 30 cases
./run-all.sh L2 4                  # 4x parallel, all 30 cases
./run-all.sh L2 1 2 19 27         # serial, specific cases only (retry)
```

### Environment variables
```bash
CASE_TIMEOUT=180                   # per-case timeout (seconds, default 180)
CLAUDE_BIN=claude                  # path to claude binary
TASTE_PLUGIN_DIR=../your-taste     # path to plugin
```

Results are saved to `results/` with filenames like `L0-case9-20260321-082734.md`.

### Important notes

- The script auto-resets via `git checkout -- .` between cases
- L1 requires `~/.your-taste/standalone-CLAUDE.md` — run `taste export` first if base-thinking.md changed
- Parallel mode copies project to temp dirs for isolation

## Full Evaluation Protocol

### Step 1: Run 3 rounds per level

Single-run results have too much variance. Run each level 3 times for statistical reliability.

```bash
# Round 1
./run-all.sh L0 4 && ./run-all.sh L0-deep 4 && ./run-all.sh L1 4 && ./run-all.sh L2 4

# Round 2
./run-all.sh L0 4 && ./run-all.sh L0-deep 4 && ./run-all.sh L1 4 && ./run-all.sh L2 4

# Round 3
./run-all.sh L0 4 && ./run-all.sh L0-deep 4 && ./run-all.sh L1 4 && ./run-all.sh L2 4
```

Or run 2 levels in parallel (8 concurrent Claude instances):
```bash
./run-all.sh L0 4 & ./run-all.sh L0-deep 4 & wait
./run-all.sh L1 4 & ./run-all.sh L2 4 & wait
```

Timeouts: retry with `CASE_TIMEOUT=300 ./run-all.sh L1 1 5 9` (Case 5 CSV export often needs more time).

### Step 2: Evaluate by category (not by level)

**Critical**: assign one evaluator per **category**, not per level. This ensures consistent scoring standards across levels within each category.

| Evaluator | Category | Cases | What to look for |
|-----------|----------|-------|------------------|
| Agent 1 | Breadth-scan | 2, 7, 9, 12, 16, 25 | Did AI scan adjacent files/components? |
| Agent 2 | Verification | 6, 13, 20, 21 | Did AI verify claims/docs before acting? |
| Agent 3 | Root Cause | 3, 4, 8, 14, 15, 22, 26 | Did AI trace to actual root cause? |
| Agent 4 | Scope Control | 10, 17, 19, 24, 27 | Did AI stay in scope and flag breaking changes? |
| Agent 5 | Feature Design | 1, 5, 11, 18, 23, 28 | Did AI consider edge cases, performance, patterns? |
| Agent 6 | Generalization | 29, 30 | Did AI combine principles for novel situations? |

Each agent reads:
1. The scenario file (`scenarios/NN-*.md`) — contains pass/fail criteria
2. ALL result files for that case across ALL levels and ALL 3 runs

Each agent scores every result as PASS / PARTIAL / FAIL.

**Why category-based**: If Agent A evaluates all L0 results and Agent B evaluates all L2 results, their different grading strictness makes L0-vs-L2 comparison unreliable. Category-based evaluation ensures the same agent grades L0, L1, L2 for the same case — apples-to-apples.

### Step 3: Aggregate scores

For each case × level, take the **majority score** across 3 runs:
- 3× PASS = PASS
- 2× PASS + 1× PARTIAL = PASS
- 2× PARTIAL + 1× PASS = PARTIAL
- etc.

Report both the majority score and the individual run scores for transparency.

## Scoring Standard

Score strictly against each scenario's **Pass Criteria** and **Fail Criteria**:

| Score | Meaning |
|-------|---------|
| **PASS** | Meets all pass criteria. AI performed the expected reasoning behavior. |
| **PARTIAL** | Meets some pass criteria. Correct direction but incomplete (e.g., found 2/4 leaks). |
| **FAIL** | Meets fail criteria or misses the core expected behavior entirely. |

**Rules:**
- Do NOT inflate scores for "awareness" — if the scenario says "must identify X" and AI didn't identify X, it's not PASS
- "Mentioned it but didn't fix it" is PARTIAL at best, not PASS
- Timeout = rerun with higher CASE_TIMEOUT; if still fails, score as FAIL

## The 30 Test Cases

Full pass/fail criteria are in `scenarios/01-*.md` through `scenarios/30-*.md`.

| # | Name | Category | Core trap |
|---|------|----------|-----------|
| 1 | Category Filter | Feature | Migration exists but never applied |
| 2 | Soft Delete Migration | Breadth | 3 entity types × 3 different soft-delete patterns |
| 3 | Rate Limit Config | Root Cause | .env.example misleads, config is hardcoded |
| 4 | Price Display Bug | Root Cause | cents/dollars mismatch |
| 5 | CSV Export | Feature | "Loop through pages" vs direct DB query |
| 6 | Misleading JSDoc | Verification | JSDoc lies about filtering |
| 7 | Validation Breadth | Breadth | quantity=0 bug, check other endpoints |
| 8 | Auth Middleware Bug | Root Cause | Middleware mounted but never enforces |
| 9 | Memory Leaks (4) | Breadth | 4 leaks across different files |
| 10 | Order Status Update | Scope | Add PATCH without over-engineering |
| 11 | Stock Deduction | Feature | Needs transaction + race condition guard |
| 12 | ID Type Validation | Breadth | Same bug in users/products routes |
| 13 | Phantom Sort Feature | Verification | Sorting was never implemented |
| 14 | Response Format | Root Cause | "Copy formatting" would propagate bug |
| 15 | Env Config Mismatch | Root Cause | Env var not read, config hardcoded |
| 16 | Error Handling Breadth | Breadth | Error handling needed across all routes |
| 17 | PATCH Order Fields | Scope | Should question letting users set prices |
| 18 | Add User to Orders | Feature | N+1 query trap |
| 19 | Set deleted_at | Scope | 1-line fix, don't over-refactor |
| 20 | Price Mismatch | Verification | Prices are correct (snapshot design) |
| 21 | Stale User Cache | Verification | Stale cache, not a query bug |
| 22 | Search Route Ordering | Root Cause | /:id matches before /search |
| 23 | Bulk CSV Import | Feature | Error handling, partial failure |
| 24 | Cancel/Refund | Scope | Design decisions needed first |
| 25 | Pagination Count | Breadth | Count query diverges from data query |
| 26 | Stale Price Cache | Root Cause | Cache not invalidated on update |
| 27 | Rename ID Field | Scope | Breaking API change |
| 28 | Stats Performance | Feature | 500k rows in memory |
| 29 | Admin Impersonation | Generalization | Security risk, broken JWT |
| 30 | Bulk Order Create | Generalization | Multi-dimensional design |

## Troubleshooting

**Timeout on Case 5 (CSV export)**
- Claude generates verbose code for streaming CSV. Try `CASE_TIMEOUT=300`.
- If still fails, may be output token limit in claude-cli-proxy.

**"Cannot be launched inside another Claude Code session"**
- Scripts unset `CLAUDECODE` and `CLAUDE_CODE_ENTRYPOINT`. Should work from terminal or inside Claude Code.

**L1 standalone CLAUDE.md not found**
- Run `taste export` CLI command or invoke the `taste:export` skill.

**Different results each run**
- Expected — LLM output is non-deterministic. This is why we run 3x and take majority scores.
