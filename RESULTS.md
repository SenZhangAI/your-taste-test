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

## Evaluation Methodology

### Scoring Standard (v6+)

Score strictly against each scenario's **Pass Criteria** and **Fail Criteria**:

- **PASS**: Meets all pass criteria. AI performed the expected reasoning behavior.
- **PARTIAL**: Meets some pass criteria. Correct direction but incomplete execution (e.g., found 2/4 leaks, mentioned breadth but didn't fix).
- **FAIL**: Meets fail criteria or misses the core expected behavior entirely.

**Why strict scoring**: v5 used "correct direction + some awareness = PARTIAL" which inflated scores. e.g., Case 29 (security) was scored PASS in v5 despite not identifying the broken JWT verification — the core pass criterion. Strict scoring gives more accurate signal about whether the prompt actually changes AI behavior.

### Variance Caveat

Single-run results have natural model variance. The same prompt can produce different outputs between runs (e.g., Case 12 L1: v5 run mentioned breadth, v6 run didn't). Scores should be interpreted as directional, not precise. Multiple runs per case would improve reliability but at significant cost.

---

## Results — v6 (2026-03-21)

Prompt changes: added "Externalize this step" to Scan and Breadth-scan checkpoints in base-thinking.md.

**Methodology**: 3 runs per level, evaluated by category (one evaluator per category, not per level). Majority score across 3 runs. See HOW-TO-TEST.md for full protocol.

| Case | Category | L0 | L0-deep | L1 | L2 |
|------|----------|:--:|:-------:|:--:|:--:|
| 1 | Feature | FAIL | FAIL | FAIL | FAIL |
| 2 | Breadth | FAIL | PARTIAL | PARTIAL | PARTIAL |
| 3 | Root Cause | **PASS** | **PASS** | PARTIAL | **PASS** |
| 4 | Root Cause | **PASS** | **PASS** | **PASS** | **PASS** |
| 5 | Feature | **PASS** | **PASS** | **PASS** | **PASS** |
| 6 | Verification | PARTIAL | PARTIAL | **PASS** | PARTIAL |
| 7 | Breadth | FAIL | FAIL | FAIL | FAIL |
| 8 | Root Cause | **PASS** | **PASS** | **PASS** | **PASS** |
| 9 | Breadth | **PASS** | **PASS** | **PASS** | **PASS** |
| 10 | Scope | **PASS** | **PASS** | **PASS** | **PASS** |
| 11 | Feature | FAIL | FAIL | **PASS** | **PASS** |
| 12 | Breadth | FAIL | FAIL | FAIL | FAIL |
| 13 | Verification | **PASS** | **PASS** | **PASS** | **PASS** |
| 14 | Root Cause | FAIL | FAIL | PARTIAL | PARTIAL |
| 15 | Root Cause | FAIL | FAIL | PARTIAL | PARTIAL |
| 16 | Breadth | FAIL | PARTIAL | PARTIAL | PARTIAL |
| 17 | Scope | PARTIAL | PARTIAL | PARTIAL | PARTIAL |
| 18 | Feature | FAIL | FAIL | FAIL | **PASS** |
| 19 | Scope | FAIL | FAIL | PARTIAL | FAIL |
| 20 | Verification | FAIL | FAIL | **PASS** | **PASS** |
| 21 | Verification | **PASS** | **PASS** | **PASS** | **PASS** |
| 22 | Root Cause | **PASS** | **PASS** | **PASS** | **PASS** |
| 23 | Feature | **PASS** | **PASS** | **PASS** | **PASS** |
| 24 | Scope | PARTIAL | PARTIAL | PARTIAL | PARTIAL |
| 25 | Breadth | **PASS** | **PASS** | **PASS** | **PASS** |
| 26 | Root Cause | **PASS** | **PASS** | **PASS** | **PASS** |
| 27 | Scope | PARTIAL | PARTIAL | **PASS** | PARTIAL |
| 28 | Feature | **PASS** | **PASS** | **PASS** | **PASS** |
| 29 | Generalization | FAIL | FAIL | FAIL | FAIL |
| 30 | Generalization | PARTIAL | PARTIAL | PARTIAL | PARTIAL |

### v6 Aggregate Score

| Metric | L0 | L0-deep | L1 | L2 |
|--------|:--:|:-------:|:--:|:--:|
| **PASS** | 12 (40%) | 12 (40%) | **15 (50%)** | **15 (50%)** |
| **PARTIAL** | 5 (17%) | 7 (23%) | 10 (33%) | 10 (33%) |
| **FAIL** | 13 (43%) | 11 (37%) | **5 (17%)** | **5 (17%)** |

### v6 By Category

| Category | Cases | L0 | L0-deep | L1 | L2 |
|----------|:-----:|:--:|:-------:|:--:|:--:|
| Breadth-scan | 6 | 33% | 33% | 33% | 33% |
| Verification | 4 | 50% | 50% | **100%** | 75% |
| Root Cause | 7 | 71% | 71% | 57% | 71% |
| Scope Control | 5 | 20% | 20% | **40%** | 20% |
| Feature Design | 6 | 50% | 50% | 67% | **83%** |
| Generalization | 2 | 0% | 0% | 0% | 0% |

### v6 Key Observations

1. **L1 and L2 tied overall** — both 15 PASS (50%), 5 FAIL (17%). FAIL rate halved vs L0/L0-deep (43%/37%).
2. **L1 and L2 have different strengths**:
   - L1 wins Verification (100% vs 75%) and Scope (40% vs 20%)
   - L2 wins Feature Design (83% vs 67%) and Root Cause (71% vs 57%)
3. **Breadth-scan: all levels tied at 33%** — Cases 7 (validation breadth) and 12 (ID validation) are universally unsolved. Case 9 (memory leaks) is universally solved. The checkpoint helps with breadth on "investigate" tasks but not "fix this one thing" tasks.
4. **Case 29 (security) universally FAIL** — Only L2-R2 (1 of 12 runs) even mentioned the JWT verification gap. Security generalization from abstract principles doesn't work reliably.
5. **Case 19 (scope) almost universally FAIL** — AI consistently over-refactors. L1 gets PARTIAL by at least leaving products alone, but still over-refactors order queries.
6. **Case 3 L1 regression** — L1 gets distracted by the memory leak in rate-limiter.js and forgets to set the requested 500 default (sets 100 instead). The breadth-scan checkpoint causes over-exploration that hurts the primary task.

---

## Results — v5 (2026-03-08, deprecated scoring)

> ⚠️ v5 used lenient scoring ("correct direction + some awareness = PARTIAL"). Some scores are known to be incorrect (e.g., Case 29 L1/L2 scored PASS without meeting pass criteria). Retained for historical reference. Use v6 results for current assessment.

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
| 29 | Generalization | FAIL | FAIL | **PASS**⚠️ | **PASS**⚠️ |
| 30 | Generalization | PARTIAL | PARTIAL | PARTIAL | PARTIAL |

v5 Aggregate: L0 37% | L0-deep 47% | L1 83% | L2 73%

---

## Key Findings (cross-version)

### 1. Reasoning checkpoints significantly reduce catastrophic failures

Across both v5 (lenient) and v6 (strict), L1/L2 consistently have fewer FAILs than L0/L0-deep. The effect is robust to scoring methodology.

### 2. Directional guidance >> thinking budget

L0-deep (extended thinking, no guidance) never outperforms L1 or L2 meaningfully. **More thinking time cannot substitute for directional checkpoints.**

### 3. Breadth-scan is the core differentiator

L0 baseline scores lowest on breadth-scan cases across all runs. This is the capability AI doesn't exhibit natively, and where checkpoints add the most value.

### 4. Case 29 (security) is unsolved

No level reliably pushes back on the dangerous impersonation feature with broken JWT. The "challenge when warranted" + "surface risks" principles are too abstract to trigger security-specific reasoning. May need explicit security checkpoint.

### 5. Single-run variance is too high for precise comparison

Cases like 12 (breadth) swing between PASS and FAIL across runs at the same level. Reliable delta measurement requires 3+ runs per case.

### 6. Prompt refinement has measurable impact

| Change | Case | Before → After |
|--------|------|:--------------:|
| Added "Is this a breaking change?" to Scan | 27 | FAIL → **PASS** (v5) |
| Qualified "don't unify" with user-request exception | 19 | PARTIAL → **PASS** (v5) |

Small, precise prompt changes produce targeted improvements.

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

## Compact Decay Test (v5.1)

Tests whether checkpoints survive `/compact` in real multi-turn sessions.
Setup: 8 filler turns → /compact → Case 9 (breadth-scan: find 4 memory leaks).

| Run | L0 | L1 | L2 |
|:---:|:--:|:--:|:--:|
| 1 | 4/4 PASS | 4/4 PASS | 4/4 PASS |
| 2 | 4/4 PASS | 4/4 PASS | 4/4 PASS |
| 3 | 4/4 PASS | 4/4 PASS | 2/4 PARTIAL |

**Caveat:** Filler turns exposed the AI to leak-containing files (rate-limiter.js, product-service.js, etc.), giving it a codebase map that single-turn tests lack. L0's 4/4 reflects warm-start familiarity, not cold-start breadth-scan. L2's run 3 (2/4) shows checklist effect persists even with warm-start advantage. See ANALYSIS.md for detailed interpretation.

## Run History

| Run | Date | Level | Cases | Run ID | Notes |
|-----|------|-------|:-----:|--------|-------|
| v6 | 2026-03-21 | All | 30×3 | 082734/090641/094301 (L0) + 082806/092241/095748 (L1/L2) | 3 runs, category-based eval, strict scoring |
| v5.1-compact | 2026-03-08 | L0/L1/L2 | Case 9 ×3 | compact-* | Multi-turn + /compact |
| v5 | 2026-03-08 | All | 30 | 20260308-* | Lenient scoring (deprecated) |
