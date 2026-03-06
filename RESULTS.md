# your-taste A/B Test Results

> Does [your-taste](https://github.com/SenZhangAI/your-taste)'s reasoning checkpoint injection make Claude avoid reasoning traps?

## Test Matrix (20 cases)

|  | Checkpoint | L0 (bare) | L2 (your-taste) | Delta |
|--|-----------|-----------|-----------------|-------|
| **Case 1** — Category Filter | verification_skip | ❌ 0/2 | ❌ 0/2 | — |
| **Case 2** — Soft Delete | breadth_miss | ✅ 2/2 | ✅ 2/2 | — |
| **Case 3** — Rate Limit | assumption_leak | ✅ 3/3 | ⚠️ 2/3 | L0 +1 |
| **Case 4** — Price Bug | depth_skip | ❌ 0/3 | ✅ 2/3 | **L2 +2** |
| **Case 5** — CSV Export | domain reasoning | ⚠️ 0/3 | ⚠️ 1/3 | L2 +1 |
| **Case 6** — Misleading JSDoc | indirect source | ✅ 3/3 | ✅ 3/3 | — |
| **Case 7** — Validation Breadth | breadth_miss | ❌ 0/3 | ✅ 3/4 | **L2 +3** |
| **Case 8** — Phantom Auth | assumption_leak | ✅ 2/2 | ✅ 2/2 | — |
| **Case 9** — Memory Leak | overreach | ✅ 2/2 | ✅ 2/2 | — |
| **Case 10** — Status Update | second-order | ✅ 2/2 | ✅ 2/2 | — |
| **Case 11** — Stock Deduction | second-order + assumption | ⚠️ 1/2 | ✅ 2/2 | **L2 +1** |
| **Case 12** — ID Validation | breadth_miss | ❌ 0/2 | ❌ 0/2 | — |
| **Case 13** — Phantom Sort | verification_skip | ✅ 2/2 | ✅ 2/2 | — |
| **Case 14** — Response Format | depth_skip | ❌ 0/2 | ❌ 0/2 | — |
| **Case 15** — .env Mismatch | verify + assumption | ⚠️ 1/2 | ❌ 0/2 | L0 +1 |
| **Case 16** — Error Handling | breadth + depth | ❌ 0/2 | ❌ 0/2 | — |
| **Case 17** — PATCH Fields | depth + second-order | ❌ 0/2 | ❌ 0/2 | — |
| **Case 18** — User in Orders | depth + domain | ✅ 2/2 | ✅ 2/2 | — |
| **Case 19** — Set deleted_at | verify + overreach | ✅ 2/2 | ✅ 2/2 | — |
| **Case 20** — Price Mismatch | verify + breadth | ✅ 2/2 | ✅ 2/2 | — |

### Aggregate

| Metric | L0 | L2 |
|--------|----|----|
| Cases with differentiation | 2 wins | 4 wins |
| Pass rate (all runs) | 56% | 64% |

## Case Difficulty Distribution

| Category | Cases | Count |
|----------|-------|-------|
| **Both always pass** (trap too easy) | 2, 6, 8, 9, 10, 13, 18, 19, 20 | 9 |
| **Differentiation** (L2 > L0 or L0 > L2) | 3, 4, 5, 7, 11, 15 | 6 |
| **Both always fail** (trap too hard) | 1, 12, 14, 16, 17 | 5 |

The 6 differentiating cases are the most valuable for measuring your-taste's impact.

## Differentiating Cases (detailed)

### Case 4: Price Bug — depth_skip ⭐⭐

`getOrderTotal()` returns cents, `formatPrice()` expects dollars. Fix at call site, not by changing contracts.

| | R1 | R2 | R3 |
|--|----|----|-----|
| L0 | ❌ Changed getOrderTotal contract | ❌ Same | ❌ Same |
| L2 | ✅ Fixed at call site | ❌ Changed contract | ✅ Referenced products.js pattern |

**L0: 0/3, L2: 2/3.** Strongest signal. The depth_skip checkpoint directly prevents wrong-layer fixes.

### Case 7: Validation Breadth — breadth_miss ⭐⭐

Bug: quantity=0. Adjacent: total_cents also has weak validation.

| | R3 | R4 | R5 |
|--|----|----|-----|
| L0 | ❌ Only quantity | ❌ Same | ❌ Same |
| L2 | ✅ quantity + total_cents | ✅ Same | ✅ Same |

**L0: 0/3, L2: 3/4.** Second strongest. The breadth_miss checkpoint triggers "what else has the same problem?"

### Case 11: Stock Deduction — second-order + assumption_leak ⭐

Product-to-order relationship is string-based (no FK). Stock deduction needs transaction.

| | R1 | R2 |
|--|----|----|
| L0 | ⚠️ Transaction but no FK concern | ✅ Added product_id + transaction |
| L2 | ✅ FK migration + derived pricing | ✅ product_id + transaction |

**L0: 1.5/2, L2: 2/2.** L2 consistently addresses structural issues (FK fragility, price derivation). L0 catches up in R2 but is less consistent.

### Case 3: Rate Limit — assumption_leak (L0 wins)

Config has `TODO: move to env vars`. Correct fix: wire `process.env`.

| | R1 | R2 | R3 |
|--|----|----|-----|
| L0 | ✅ Wired env vars | ✅ All 4 values | ✅ All values |
| L2 | ✅ All 4 values | ❌ Just changed number | ✅ All values |

**L0: 3/3, L2: 2/3.** Context dilution: ~8KB injection competed for attention.

### Case 15: .env Mismatch — verify + assumption (L0 wins)

.env.example says 10, config.js hardcodes 100. No dotenv integration.

| | R1 | R2 |
|--|----|----|
| L0 | ✅ Explained discrepancy | ❌ Just wired .env |
| L2 | ❌ Just wired .env | ⚠️ Wired but noted caveat |

**L0: 1/2, L2: 0.5/2.** Both struggle, but L0 R1 was the only run that properly explained the discrepancy without blindly fixing.

### Case 5: CSV Export — domain reasoning (marginal)

5000 orders. Should stream/batch, not load all to memory.

| | R1 | R2 | R3 |
|--|----|----|-----|
| L0 | ⚠️ Direct query, no streaming | ⚠️ Same | ⚠️ Same |
| L2 | ✅ Batches of 500 | ⚠️ Same | ⚠️ Same |

**L0: 0/3, L2: 1/3.** Marginal. Both bypass pagination but memory consideration is rare.

## Both-Fail Cases (potential optimization targets)

These 5 cases are traps that neither L0 nor L2 catches. They represent gaps in current checkpoints.

| Case | Trap | Why both fail | Potential checkpoint |
|------|------|--------------|---------------------|
| **1** | Migration exists but never applied | No checkpoint covers "verify schema state" | "Before using a column from migration files, verify it exists in runtime schema" |
| **12** | ID validation needed in all 3 route files | Both only fix the mentioned route | Strengthen breadth_miss: "After fixing a route pattern, grep for identical patterns in sibling routes" |
| **14** | Response formatting should be extracted, not duplicated | Both copy-paste formatting | "Before duplicating logic, check if extraction is warranted" |
| **16** | Error handling needed globally, not per-route | Both only wrap orders routes | Same as 12 — breadth scanning for route patterns |
| **17** | PATCH allows total_cents directly | Neither questions business logic | "Before implementing a data mutation endpoint, verify field editability makes business sense" |

## Key Findings

### 1. your-taste's value is concentrated, not broad

Only 6 of 20 cases show differentiation. The strongest wins are on **depth_skip** (Case 4: contract preservation) and **breadth_miss** (Case 7: adjacent validation). These are exactly the patterns your-taste's observations.md targets most heavily.

### 2. Many traps are too easy for Claude Opus

9 of 20 cases are consistently passed by both levels. Claude Opus 4.6 naturally verifies filesystem state (Case 8, 13), investigates root causes (Case 9), and uses JOINs (Case 18). These behaviors don't need checkpoint reinforcement.

### 3. Context dilution is real

Cases 3 and 15 show L0 outperforming L2. The ~8KB injection payload sometimes competes for attention on tasks where the answer is straightforward. This argues for **fewer, sharper checkpoints** rather than comprehensive coverage.

### 4. Both-fail cases reveal checkpoint gaps

5 cases that neither level passes represent real opportunities to improve your-taste's checkpoints. The most impactful additions would target **schema verification** (Case 1) and **sibling-route scanning** (Cases 12, 16).

## Optimization Recommendations

### High-impact checkpoint additions
1. **Schema verification**: "Before using a DB column referenced only in migration files, verify it exists in the runtime schema"
2. **Sibling route scanning**: "After fixing a pattern in one route file, grep for the same pattern in other route files under the same directory"
3. **Business logic scrutiny**: "Before implementing a data mutation endpoint, question whether each writable field should be user-controllable"

### Injection optimization
- Trim SessionStart payload from ~8KB to essential checkpoints only
- Prioritize depth_skip and breadth_miss (proven signal) over verbose examples
- Remove checkpoint instances that overlap with Claude's natural capabilities

## How to Reproduce

```bash
# Single case
./test-runner.sh L0 4        # baseline
./test-runner.sh L2 4        # with your-taste

# All 20 cases
./run-all.sh L0
./run-all.sh L2
```

See [HOW-TO-TEST.md](HOW-TO-TEST.md) for full setup instructions.
