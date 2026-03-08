# your-taste A/B Test Results

> Does [your-taste](https://github.com/SenZhangAI/your-taste)'s reasoning checkpoint injection make Claude avoid reasoning traps?

## Test Levels

| Level | What it is | Injection | Description |
|-------|-----------|-----------|-------------|
| **L0** | Bare Claude | 0 | No CLAUDE.md, no plugin. Pure model capability baseline. |
| **L0-deep** | Bare Claude + extended thinking | 0 | Same as L0 but with `--effort high`. Tests if more thinking time substitutes for directional guidance. |
| **L1** | Standalone CLAUDE.md | ~6.8K | Exported thinking-context merged with user CLAUDE.md. No hooks, no per-message injection. |
| **L2** | Full plugin | ~6K | Dynamic hooks (SessionStart + UserPromptSubmit) + user CLAUDE.md. Per-message reasoning checkpoint injection. |

## Test Codebase

15+ file Express/Knex order management API with:
- Service layer (order-service, user-service, product-service)
- 3 varied soft-delete mechanisms (status flag, deleted_at timestamp, is_active boolean)
- 4 embedded memory leaks (requestLog, recentErrors, userCache, priceCache)
- Deliberate doc/code mismatches (JSDoc claims vs actual behavior)
- Auth middleware that never enforces

## Test Cases (30)

### By Reasoning Skill Tested

**Breadth-scan** — Does AI check adjacent files/entities after acting?

| Case | Name | Trap |
|------|------|------|
| 2 | Soft Delete Migration | 3 entity types use 3 different soft-delete mechanisms |
| 7 | Validation Breadth | quantity=0 bug exists on one endpoint, others may have similar gaps |
| 9 | Memory Leak (4 leaks) | 4 leaks across different files, AI typically finds 2 |
| 12 | ID Type Validation | bad ID handling in orders — same issue in users/products routes |
| 16 | Error Handling Breadth | error handling needed across multiple route files |
| 25 | Pagination Count Mismatch | count query diverges from data query — must trace both |

**Verification** — Does AI verify claims and docs before acting?

| Case | Name | Trap |
|------|------|------|
| 6 | Misleading JSDoc | JSDoc says "filters deleted records" — code doesn't |
| 13 | Phantom Sort Feature | user reports sorting bug, but sorting was never implemented |
| 20 | Price Mismatch | order prices "out of sync" — actually correct (price snapshot design) |
| 21 | Stale User Cache | deleted user still visible — stale cache, not a query bug |

**Root Cause Depth** — Does AI trace to the actual root cause?

| Case | Name | Trap |
|------|------|------|
| 3 | Rate Limit Config | .env.example misleads — real issue is hardcoded config |
| 4 | Price Display Bug | cents/dollars mismatch across formatPrice + getOrderTotal |
| 8 | Auth Middleware Bug | auth middleware is mounted but never enforces (always calls next()) |
| 14 | Response Format | "just copy formatting" would propagate cents/dollars bug |
| 15 | Env Config Mismatch | env var not read — config.js hardcodes the value |
| 22 | Search Route Ordering | /search 404s because /:id route matches first |
| 26 | Stale Price Cache | price update works but subsequent orders use cached old price |

**Scope Control** — Does AI stay within scope and flag breaking changes?

| Case | Name | Trap |
|------|------|------|
| 10 | Order Status Update | add PATCH — shouldn't over-engineer with state machines |
| 17 | PATCH Order Fields | user wants to edit "total, whatever" — should question letting users set prices |
| 19 | Set deleted_at | fix 1-line bug — prompt asks about products alignment too |
| 24 | Cancel/Refund | design decisions needed — should analyze code first, not just ask |
| 27 | Rename ID Field | "quick find-and-replace" is a breaking API change |

**Feature Design Quality** — Does AI consider edge cases, performance, patterns?

| Case | Name | Trap |
|------|------|------|
| 1 | Category Filter | migration referenced but may not be applied |
| 5 | CSV Export | "loop through pages" — should query DB directly instead |
| 11 | Stock Deduction | needs transaction + race condition guard |
| 18 | Add User to Orders | N+1 query trap — should use JOIN or batch |
| 23 | Bulk CSV Import | error handling, partial failure semantics |
| 28 | Stats Performance | loads 500k rows into memory — needs SQL aggregation |

**Generalization** — No direct rule in thinking-context; must combine principles

| Case | Name | What it tests |
|------|------|--------------|
| 29 | Admin Impersonation | Security risk awareness (combine: surface risks + Scan + challenge) |
| 30 | Bulk Order Create | Multi-dimensional design (combine: Scan + Explicit > Implicit + patterns) |

---

## Results — All Levels (30 cases)

All results manually verified against actual output files. Scoring standard: correct direction + some awareness of the expected dimension = PARTIAL; no awareness at all = FAIL.

| Case | Category | L0 | L0-deep | L1 | L2 |
|------|----------|:--:|:-------:|:--:|:--:|
| 1 | Feature | PARTIAL | PARTIAL | PARTIAL | PARTIAL |
| 2 | Breadth | PARTIAL | PARTIAL | PARTIAL | **PASS** |
| 3 | Root Cause | FAIL | **PASS** | **PASS** | **PASS** |
| 4 | Root Cause | **PASS** | **PASS** | **PASS** | **PASS** |
| 5 | Feature | PARTIAL | PARTIAL | **PASS** | PARTIAL |
| 6 | Verification | PARTIAL | PARTIAL | **PASS** | **PASS** |
| 7 | Breadth | FAIL | PARTIAL | **PASS** | **PASS** |
| 8 | Root Cause | **PASS** | **PASS** | **PASS** | **PASS** |
| 9 | Breadth | FAIL | PARTIAL | **PASS** | PARTIAL |
| 10 | Scope | PARTIAL | PARTIAL | **PASS** | **PASS** |
| 11 | Feature | PARTIAL | PARTIAL | **PASS** | **PASS** |
| 12 | Breadth | FAIL | FAIL | **PASS** | **PASS** |
| 13 | Verification | **PASS** | **PASS** | **PASS** | **PASS** |
| 14 | Root Cause | FAIL | FAIL | **PASS** | **PASS** |
| 15 | Root Cause | PARTIAL | PARTIAL | **PASS** | **PASS** |
| 16 | Breadth | PARTIAL | PARTIAL | **PASS** | PARTIAL |
| 17 | Scope | PARTIAL | PARTIAL | PARTIAL | PARTIAL |
| 18 | Feature | FAIL | FAIL | **PASS** | PARTIAL |
| 19 | Scope | **PASS** | **PASS** | PARTIAL | **PASS** |
| 20 | Verification | PARTIAL | **PASS** | **PASS** | **PASS** |
| 21 | Verification | **PASS** | **PASS** | **PASS** | **PASS** |
| 22 | Root Cause | **PASS** | **PASS** | **PASS** | **PASS** |
| 23 | Feature | **PASS** | **PASS** | **PASS** | **PASS** |
| 24 | Scope | **PASS** | **PASS** | **PASS** | PARTIAL |
| 25 | Breadth | **PASS** | **PASS** | **PASS** | **PASS** |
| 26 | Root Cause | **PASS** | **PASS** | **PASS** | **PASS** |
| 27 | Scope | PARTIAL | PARTIAL | **PASS** | **PASS** |
| 28 | Feature | **PASS** | **PASS** | **PASS** | **PASS** |
| 29 | Generalization | FAIL | FAIL | **PASS** | **PASS** |
| 30 | Generalization | PARTIAL | PARTIAL | PARTIAL | PARTIAL |

### Aggregate Score

| Metric | L0 | L0-deep | L1 | L2 |
|--------|:--:|:-------:|:--:|:--:|
| **PASS** | 11 (37%) | 14 (47%) | **25 (83%)** | 22 (73%) |
| **PARTIAL** | 11 (37%) | 12 (40%) | 5 (17%) | 8 (27%) |
| **FAIL** | 8 (27%) | 4 (13%) | 0 (0%) | 0 (0%) |

### By Category

| Category | Cases | L0 | L0-deep | L1 | L2 |
|----------|:-----:|:--:|:-------:|:--:|:--:|
| Breadth-scan | 6 | 17% | 17% | **83%** | 67% |
| Verification | 4 | 50% | 75% | **100%** | **100%** |
| Root Cause | 7 | 57% | 71% | **100%** | **100%** |
| Scope Control | 5 | 40% | 40% | 60% | 60% |
| Feature Design | 6 | 33% | 33% | **83%** | 50% |
| Generalization | 2 | 0% | 0% | 50% | 50% |

### Head-to-Head (30 cases)

| Comparison | Wins | Ties | Losses |
|------------|:----:|:----:|:------:|
| L1 vs L0 | **15** | 14 | 1 |
| L1 vs L0-deep | **13** | 16 | 1 |
| L1 vs L2 | **5** | 23 | 2 |
| L2 vs L0 | **14** | 15 | 1 |
| L2 vs L0-deep | **11** | 18 | 1 |
| L0-deep vs L0 | **4** | 26 | 0 |

---

## Key Findings

### 1. Standalone CLAUDE.md (L1) is the best approach

L1 achieves 83% PASS — higher than L2's 73%. The standalone export, loaded once at session start, outperforms per-message injection. This is the most important finding: **simpler delivery mechanism, better results**.

### 2. Per-message injection may over-prompt

L1 beats L2 on Feature Design (83% vs 50%) and Breadth-scan (83% vs 67%). The starkest example: Case 9 (memory leaks) — L1 found all 4 leaks while L2 found only 2. Hypothesis: per-message breadth-scan reminders cause the AI to "check the box" and stop searching after finding the first few issues, rather than doing an exhaustive scan.

### 3. Directional guidance >> thinking budget

L0-deep (extended thinking, no guidance) scores 47% vs L1's 83%. **More thinking time cannot substitute for directional checkpoints.** L1 won 13 cases that L0-deep couldn't solve with extra thinking alone.

### 4. Breadth-scan is the core differentiator

L0 and L0-deep both score 17% on Breadth-scan cases. L1 scores 83%. This is the single largest gap and confirms breadth-scan as the capability that AI doesn't exhibit natively.

### 5. Case 29 (security) is the strongest discriminator

Only L1 and L2 push back on the dangerous impersonation feature. L0 and L0-deep (including with extended thinking) blindly implement it. The "challenge when warranted" + "surface risks" principles generalize to security without any explicit security rules.

### 6. Prompt refinement has measurable impact

| Change | Case | Before → After |
|--------|------|:--------------:|
| Added "Is this a breaking change?" to Scan | 27 | FAIL → **PASS** |
| Qualified "don't unify" with user-request exception | 19 | PARTIAL → **PASS** |
| Changed "internal/external" to "breaking/non-breaking" | 27 | FAIL → **PASS** |

Small, precise prompt changes produce targeted improvements without regression.

## How to Reproduce

```bash
# Single case
./test-runner.sh L0 9              # bare Claude
./test-runner.sh L0-deep 9         # bare + extended thinking
./test-runner.sh L1 9              # standalone CLAUDE.md (no plugin)
./test-runner.sh L2 9              # full plugin
./test-runner.sh L2-deep 9         # full plugin + extended thinking

# All 30 cases
./run-all.sh L2 4                  # 4x parallel, all cases
./run-all.sh L2 1 2 19 27         # specific cases only (retry)

# Environment variables
CASE_TIMEOUT=180                   # per-case timeout (seconds)
CLAUDE_BIN=claude                  # path to claude binary
TASTE_PLUGIN_DIR=../your-taste     # path to plugin

# Results saved to results/
```

## Run History

| Run | Date | Level | Cases | Run ID | Notes |
|-----|------|-------|:-----:|--------|-------|
| v5-L2 | 2026-03-08 | L2 | 30 | 20260308-103612 | Final prompt |
| v5-L1 | 2026-03-08 | L1 | 30 | 20260308-113600 | Standalone CLAUDE.md |
| v5-L0 | 2026-03-08 | L0 | 30 | 20260308-073842 + 20260308-115939 | Cases 1-20 + 21-30 |
| v5-L0-deep | 2026-03-08 | L0-deep | 30 | 20260308-073845 + 20260308-115940 | Cases 1-20 + 21-30 |
