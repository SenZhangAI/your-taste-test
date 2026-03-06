# your-taste A/B Test Results

> Testing whether [your-taste](https://github.com/SenZhangAI/your-taste)'s reasoning checkpoint injection makes Claude avoid specific reasoning traps.

## Setup

- **Model**: Claude Opus 4.6 via `claude -p`
- **L0** (baseline): bare Claude, no user CLAUDE.md, no plugins (`--setting-sources ""`)
- **L2** (your-taste): plugin hooks + user CLAUDE.md with learned reasoning rules (`--plugin-dir your-taste`)
- **Runs**: 3 rounds per case (cases 1-5), 1 round (cases 6-7)
- **Date**: 2026-03-06

> **Note on Cases 1-2**: Run 1 used earlier prompt designs (Case 1 was a different trap, Case 2 had overly specific scoping). Only Runs 2-3 use the final prompts and are included in scoring.

## Summary

| Case | Checkpoint | L0 | L2 | Winner |
|------|-----------|----|----|--------|
| 1 - Category Filter | verification_skip | 0/2 | 0/2 | Tie (both fail) |
| 2 - Soft Delete | breadth_miss | 2/2 | 2/2 | Tie (both pass) |
| 3 - Rate Limit | assumption_leak | 3/3 | 2/3 | **L0** |
| 4 - Price Bug | depth_skip | 0/3 | 2/3 | **L2** |
| 5 - CSV Export | domain reasoning | 0/3 | 1/3 | **L2** (marginal) |
| 6 - Misleading JSDoc | indirect source | 1/1 | 1/1 | Tie |
| 7 - Validation Breadth | breadth_miss | 0/1 | 1/1 | **L2** |

**L2 wins 3 cases, L0 wins 1 case, 3 ties.**

Aggregate pass rate: **L0 6/15 (40%)** vs **L2 9/15 (60%)**

## Detailed Results

### Case 1: Category Filter (verification_skip)

**Trap**: Migration file `002-add-category.js` adds a `category` column, but it was never applied. `db.js` creates tables inline without running migrations.

| Run | L0 | L2 |
|-----|----|----|
| R2 | FAIL - Added `.where('category', category)` without checking schema | FAIL - Same |
| R3 | FAIL - Same | FAIL - Same |

**Analysis**: Neither level verified whether the migration was actually applied. Both trusted the migration file as evidence the column exists. This is a genuine verification_skip gap that the current observations.md checkpoint doesn't catch — the existing checkpoint targets "verify user claims about behavior" but not "verify infrastructure claims about schema state."

**Improvement opportunity**: Add a checkpoint like "Before using a column/table/index referenced only in migration files, verify it exists in the actual runtime schema."

---

### Case 2: Soft Delete Migration (breadth_miss)

**Trap**: Prompt says "update the codebase" to use `deleted_at` timestamps. Three route files (orders, users, products) share the same `status !== 'deleted'` pattern.

| Run | L0 | L2 |
|-----|----|----|
| R2 | PASS - Updated all routes (orders, users, products) | PASS - Updated all 5 files including seed.js |
| R3 | PASS - Updated all routes, noted missing columns | PASS - Updated all routes, explicitly called out "prompt only mentioned orders" |

**Analysis**: After redesigning the prompt to be vague ("update the codebase"), both levels consistently scanned adjacent files. The breadth_miss trap requires a more subtle trigger — perhaps when the prompt names a specific file but the pattern exists in non-obvious locations.

---

### Case 3: Rate Limit Increase (assumption_leak)

**Trap**: `config.js` has hardcoded values with a `TODO: move to env vars` comment. The correct fix wires `process.env`, not just changes the number.

| Run | L0 | L2 |
|-----|----|----|
| R1 | PASS - Wired env vars, updated .env.example | PASS - Wired all 4 config values to env vars |
| R2 | PASS - Wired all 4 config values | **FAIL - Just changed 100 to 500** |
| R3 | PASS - Wired all config values | PASS - Wired all config values |

**Analysis**: L0 passed all 3 runs. L2 had a regression in Run 2 where it simply changed the hardcoded number — the exact failure the assumption_leak checkpoint should prevent. This suggests the ~8KB injection context from your-taste may occasionally dilute attention rather than focus it. Important finding: **more context is not always better**.

---

### Case 4: Price Display Bug (depth_skip)

**Trap**: `getOrderTotal()` returns cents. `formatPrice()` expects dollars. The bug is at the call site in `orders.js`. Products.js already does the correct `price_cents / 100` conversion.

| Run | L0 | L2 |
|-----|----|----|
| R1 | FAIL - Modified getOrderTotal to divide by 100 (changes contract) | **PASS** - Fixed at call site, noted "as documented in JSDoc" |
| R2 | FAIL - Same contract change | FAIL - Replaced multiplication with division inside getOrderTotal |
| R3 | FAIL - Same contract change | **PASS** - Fixed at call site, referenced products.js correct pattern |

**Analysis**: This is the **strongest signal for your-taste's value**. L0 consistently modified `getOrderTotal` to return dollars instead of cents — changing the function's documented contract. L2 fixed at the correct boundary (the call site) in 2 of 3 runs and explicitly referenced the existing correct pattern in products.js. The depth_skip checkpoint ("trace data flow across function boundaries before patching") directly addresses this failure mode.

---

### Case 5: CSV Export (domain reasoning)

**Trap**: 5000 orders in DB, existing pagination at 50/page. Naive approach loops through 100 pages. Better approach: direct query with streaming/batching for memory safety.

| Run | L0 | L2 |
|-----|----|----|
| R1 | PARTIAL - Direct query, no memory consideration | **PASS** - Streamed in batches of 500, explicitly mentioned memory |
| R2 | PARTIAL - Direct query, no streaming | PARTIAL - Direct query, no streaming |
| R3 | PARTIAL - Direct query, no streaming | PARTIAL - Direct query, no streaming |

**Analysis**: All runs correctly bypassed the pagination trap (none looped through `listOrders`). The difference is in the second layer of reasoning: considering memory implications of loading 5000+ rows. Only L2 Run 1 explicitly addressed this with a streaming/batching approach. The domain reasoning checkpoint helped in one run but wasn't consistent.

---

### Case 6: Misleading JSDoc (indirect source verification)

**Trap**: JSDoc says `getOrder` "returns order if not deleted, null otherwise" — but the actual implementation is `db('orders').where({ id }).first()` with no deleted filter.

| Run | L0 | L2 |
|-----|----|----|
| R3 | PASS - Read implementation, confirmed JSDoc wrong, added filter | PASS - Read implementation, fixed at service layer |

**Analysis**: Both read the actual code rather than trusting the comment. One data point is insufficient for conclusions. This trap may be too easy when the prompt explicitly says "verify and fix" — a subtler prompt might reveal differences.

---

### Case 7: Input Validation Breadth (breadth_miss)

**Trap**: Bug report mentions quantity=0. The POST endpoint also lacks validation for negative total_cents, non-existent user_id, and type checking.

| Run | L0 | L2 |
|-----|----|----|
| R3 | FAIL - Only added quantity validation | **PASS** - Fixed quantity + total_cents + split error messages |

**Analysis**: L0 fixed exactly what was reported. L2 proactively scanned adjacent validation gaps and fixed total_cents validation too. One data point, but directionally consistent with the breadth_miss checkpoint's intent.

---

## Key Findings

### Where your-taste helps

1. **Contract preservation (Case 4)**: The clearest win. L2 respected function contracts and fixed at the correct boundary. L0 consistently patched at the wrong layer. The `depth_skip` checkpoint directly prevents this.

2. **Breadth scanning (Case 7)**: L2 proactively fixed adjacent validation gaps beyond the reported bug. The `breadth_miss` checkpoint encourages "what else has the same problem?"

3. **Scale awareness (Case 5)**: Marginal advantage. L2 considered memory implications in 1/3 runs vs 0/3 for L0. The domain reasoning injection helps but inconsistently.

### Where your-taste doesn't help

1. **Schema verification (Case 1)**: Both levels fail equally. The current checkpoints don't cover "verify infrastructure state matches migration files." This is a gap in observations.md.

2. **Vague breadth tasks (Case 2)**: When the prompt is sufficiently vague, both levels naturally scan the codebase. The breadth_miss checkpoint adds no value here.

### Where your-taste hurts

1. **Context dilution (Case 3)**: L2 failed once where L0 never did. The injected context (~8KB of checkpoints + rules) may occasionally compete for attention with the actual task context. This is a real tradeoff: more guidance can reduce focus.

## Statistical Limitations

- **Small sample size**: 3 runs per case for cases 1-5, 1 run for cases 6-7. LLM outputs are non-deterministic — a single run proves little.
- **Prompt sensitivity**: Cases 1-2 required prompt redesign after Run 1. The "right" prompt matters as much as the injection.
- **No blinding**: The evaluator (us) knows which output is L0 vs L2.
- **Single model**: Results may differ across model versions or providers.

For stronger conclusions, each case would need 10+ runs with blind evaluation.

## How to Reproduce

See [HOW-TO-TEST.md](HOW-TO-TEST.md) for full instructions.

```bash
# Run a single case
./test-runner.sh L0 4        # baseline
./test-runner.sh L2 4        # with your-taste

# Run all 7 cases
./run-all.sh L0
./run-all.sh L2
```

Results are saved to `results/` with filenames like `L0-case4-20260306-210629.md`.
