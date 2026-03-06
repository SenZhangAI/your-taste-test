# your-taste A/B Test Results

> Does [your-taste](https://github.com/SenZhangAI/your-taste)'s reasoning checkpoint injection make Claude avoid reasoning traps?

## Configuration

| Component | L0 (bare Claude) | L2 (your-taste) |
|-----------|-------------------|------------------|
| CLAUDE.md | None | 6.8K (optimized) |
| SessionStart hook | None | ~0.5K |
| UserPromptSubmit hook | None | ~2.5K (abstract checkpoints) |
| **Total injection** | **0** | **~10K** |

L2 uses abstract reasoning checkpoints with disambiguating examples — no domain-specific content. See [ANALYSIS.md](ANALYSIS.md) for the optimization process that led to this configuration (30K → 10K, +19pp pass rate).

## Test Matrix (20 cases)

|  | Checkpoint | L0 (bare) | L2 (your-taste) | Delta |
|--|-----------|-----------|-----------------|-------|
| **Case 1** — Category Filter | verification_skip | ❌ 0/2 | ❌ FAIL | — |
| **Case 2** — Soft Delete | breadth_miss | ✅ 2/2 | ✅ PASS | — |
| **Case 3** — Rate Limit | assumption_leak | ✅ 3/3 | ✅ PASS | — |
| **Case 4** — Price Bug | depth_skip | ❌ 0/3 | ✅ PASS | **+L2** |
| **Case 5** — CSV Export | domain reasoning | ❌ 0/3 | ⚠️ PARTIAL | +L2 |
| **Case 6** — Misleading JSDoc | indirect source | ✅ 3/3 | ✅ PASS | — |
| **Case 7** — Validation Breadth | breadth_miss | ❌ 0/3 | ❌ FAIL | — |
| **Case 8** — Phantom Auth | assumption_leak | ✅ 2/2 | ✅ PASS | — |
| **Case 9** — Memory Leak | overreach | ✅ 2/2 | ✅ PASS | — |
| **Case 10** — Status Update | second-order | ✅ 2/2 | ✅ PASS | — |
| **Case 11** — Stock Deduction | second-order + assumption | ⚠️ 1/2 | ✅ PASS | **+L2** |
| **Case 12** — ID Validation | breadth_miss | ❌ 0/2 | ✅ PASS | **+L2** |
| **Case 13** — Phantom Sort | verification_skip | ✅ 2/2 | ✅ PASS | — |
| **Case 14** — Response Format | depth_skip | ❌ 0/2 | ❌ FAIL | — |
| **Case 15** — .env Mismatch | verify + assumption | ⚠️ 1/2 | ❌ FAIL | -L0 |
| **Case 16** — Error Handling | breadth + depth | ❌ 0/2 | ✅ PASS | **+L2** |
| **Case 17** — PATCH Fields | depth + second-order | ❌ 0/2 | ⚠️ PARTIAL | +L2 |
| **Case 18** — User in Orders | depth + domain | ✅ 2/2 | ✅ PASS | — |
| **Case 19** — Set deleted_at | verify + overreach | ✅ 2/2 | ✅ PASS | — |
| **Case 20** — Price Mismatch | verify + breadth | ✅ 2/2 | ✅ PASS | — |

### Aggregate

| Metric | L0 | L2 |
|--------|----|----|
| PASS | 11 | 14 |
| PARTIAL | 2 | 2 |
| FAIL | 7 | 4 |
| **Score** (PASS=1, PARTIAL=0.5) | **12/20 (60%)** | **15/20 (75%)** |
| Cases where L2 > L0 | — | 5 (Cases 4, 11, 12, 16, 17) |
| Cases where L0 > L2 | 1 (Case 15) | — |

## What Changed vs Original L2

The original L2 used 18K of domain-specific Chinese observations (card processing, Prisma queries, supplier integrations). The optimized L2 uses 3K of abstract English checkpoints with disambiguating examples. Key differences:

| Case | Original L2 | Optimized L2 | Why |
|------|------------|-------------|-----|
| **3** Rate Limit | ⚠️ 2/3 | ✅ PASS | Context dilution eliminated (10K vs 30K injection) |
| **7** Validation | ✅ 3/4 | ❌ FAIL | Lost serendipitous domain example hit (see ANALYSIS.md) |
| **12** ID Validation | ❌ 0/2 | ✅ PASS | Imperative breadth-scan wording works ("not optional... before considering done") |
| **16** Error Handling | ❌ 0/2 | ✅ PASS | Same breadth-scan improvement |
| **17** PATCH Fields | ❌ 0/2 | ⚠️ PARTIAL | New "field editability" checkpoint partially triggers |

Net: +3 cases gained, -1 case lost vs original L2.

## Case Difficulty Distribution

| Category | Cases | Count |
|----------|-------|-------|
| **Both pass** (trap too easy for Opus) | 2, 3, 6, 8, 9, 10, 13, 18, 19, 20 | 10 |
| **L2 wins** (your-taste makes the difference) | 4, 5, 11, 12, 16, 17 | 6 |
| **Both fail** (beyond checkpoint reach) | 1, 14 | 2 |
| **L0 wins** (your-taste hurts) | 15 | 1 |
| **Mixed** (L2 regressed from original) | 7 | 1 |

## Differentiating Cases (detailed)

### Case 4: Price Bug — depth_skip

`getOrderTotal()` returns cents, `formatPrice()` expects dollars. L0 always changes the contract; L2 fixes at the call site.

**L0: 0/3 FAIL. L2: PASS.** The "escalate abstraction level / fix at the right layer" checkpoint directly prevents wrong-layer fixes.

### Case 12: ID Validation — breadth_miss (breakthrough)

Bug in orders route. Adjacent: users and products routes have identical vulnerability.

**L0: 0/2 FAIL. L2: PASS.** The optimized breadth-scan wording — "immediately run a grep... This is not optional... search the entire routes/ directory before considering the task done" — made the AI fix all three route files. The original L2 with suggestive wording ("list and check") also failed this case.

### Case 16: Error Handling — breadth + depth (breakthrough)

Error handling needed globally across all route files, not just orders.

**L0: 0/2 FAIL. L2: PASS.** Added global Express error middleware plus asyncHandler wrapper across all three route files. Same breadth-scan improvement as Case 12.

### Case 11: Stock Deduction — second-order + assumption_leak

Product-to-order relationship is string-based (no FK). Stock deduction needs transaction.

**L0: PARTIAL. L2: PASS.** L2 switched to product_id lookup and wrapped in transaction, addressing FK fragility that L0 only sometimes catches.

### Case 17: PATCH Fields — depth + second-order

Prompt asks to make total_cents directly editable. Correct: question whether computed values should accept direct input.

**L0: 0/2 FAIL. L2: PARTIAL.** L2 restricted to pending orders and whitelisted fields — good. But still accepted total_cents from client while noting "it would be safer to look up the price server-side." Flagged but not enforced.

### Case 15: .env Mismatch — verify + assumption (L0 wins)

.env.example says 10, config.js hardcodes 100, no dotenv. Correct: explain the discrepancy.

**L0: PARTIAL. L2: FAIL.** L2 identified no dotenv but jumped to offering solutions without explaining that .env.example has no runtime effect. This is a knowledge gap — no checkpoint can teach infrastructure mechanics.

## Key Findings

### 1. Abstract principles + disambiguating examples > domain-specific examples

10K of well-crafted abstract checkpoints (75% pass) outperform 30K of domain-specific observations (64% pass). Domain examples anchor AI to irrelevant contexts; abstract principles with universal examples (grep, search, enumerate) generalize across codebases. See [ANALYSIS.md](ANALYSIS.md) for the full evidence.

### 2. Imperative wording is critical

"List all parallel components and check each one" (suggestive) → 0% on Cases 12/16.
"Immediately run a grep. This is not optional. Before considering the task done." (imperative) → 100%.

The AI treats suggestive language as optional advice. Imperative language with explicit completion criteria acts as a gate.

### 3. Targeted checkpoints unlock previously impossible cases

Cases 12 and 16 went from 0% (both L0 and original L2) to PASS with strengthened breadth-scan wording. Case 17 went from 0% to PARTIAL with a new "field editability" checkpoint. Checkpoint quality matters more than quantity.

### 4. Many traps are beyond checkpoint reach

Case 1 (unapplied migration) and Case 15 (dotenv mechanics) require infrastructure knowledge that no reasoning scaffold provides. Checkpoints improve *how* AI thinks, not *what* AI knows.

### 5. your-taste's value is concentrated, not broad

10 of 20 cases are naturally handled by Claude Opus 4.6. The 6 cases where L2 wins are exactly the patterns that checkpoints target: breadth scanning (12, 16), contract preservation (4), second-order effects (11), and field editability (17).

## Remaining Gaps

| Case | Gap | Difficulty |
|------|-----|-----------|
| **1** | Migration exists but never applied — need schema verification | Hard (infrastructure knowledge) |
| **7** | Breadth-scan triggers for route files but not for field validation within an endpoint | Medium (checkpoint refinement) |
| **14** | Formatting duplication — need "extract before duplicating" checkpoint | Medium |
| **15** | .env.example has no runtime effect without dotenv | Hard (infrastructure knowledge) |

## How to Reproduce

```bash
# Single case
./test-runner.sh L0 4        # baseline
./test-runner.sh L2-slim 4   # optimized your-taste

# All 20 cases
./run-all.sh L0
./run-all.sh L2-slim
```

See [HOW-TO-TEST.md](HOW-TO-TEST.md) for full setup instructions.
