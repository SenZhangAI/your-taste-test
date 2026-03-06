# your-taste A/B Test Results

> Does [your-taste](https://github.com/SenZhangAI/your-taste)'s reasoning checkpoint injection make Claude avoid reasoning traps?

## Test Matrix

|  | Checkpoint | L0 (bare) | L2 (your-taste) | Delta |
|--|-----------|-----------|-----------------|-------|
| **Case 1** — Category Filter | verification_skip | ❌ 0/2 | ❌ 0/2 | — |
| **Case 2** — Soft Delete | breadth_miss | ✅ 2/2 | ✅ 2/2 | — |
| **Case 3** — Rate Limit | assumption_leak | ✅ 3/3 | ⚠️ 2/3 | L0 +1 |
| **Case 4** — Price Bug | depth_skip | ❌ 0/3 | ✅ 2/3 | **L2 +2** |
| **Case 5** — CSV Export | domain reasoning | ⚠️ 0/3 partial | ⚠️ 1/3 | L2 +1 |
| **Case 6** — Misleading JSDoc | indirect source | ✅ 1/1 | ✅ 1/1 | — |
| **Case 7** — Validation Breadth | breadth_miss | ❌ 0/1 | ✅ 1/1 | **L2 +1** |
| | | **L0: 40%** | **L2: 60%** | |

**L2 wins 3 cases. L0 wins 1 case. 3 ties.**

## Setup

- **Model**: Claude Opus 4.6 via `claude -p`
- **L0**: bare Claude — `--setting-sources ""`, no plugins
- **L2**: your-taste plugin + user CLAUDE.md — `--plugin-dir your-taste`
- **Runs**: 3 rounds (cases 1-5), 1 round (cases 6-7)
- **Date**: 2026-03-06
- Cases 1-2 Run 1 used older prompts and are excluded from scoring

## Per-Run Breakdown

### Case 1: Category Filter — verification_skip

Migration file adds `category` column, but was **never applied** — `db.js` creates tables inline.

| | R2 | R3 |
|--|----|----|
| L0 | ❌ Added `.where('category', ...)` blindly | ❌ Same |
| L2 | ❌ Added filter without schema check | ❌ Same |

**Gap**: Current checkpoints target "verify user claims" but not "verify infrastructure state matches migration files."

### Case 2: Soft Delete — breadth_miss

Three routes share `status !== 'deleted'`. Prompt says "update the codebase" without naming specific files.

| | R2 | R3 |
|--|----|----|
| L0 | ✅ Updated orders + users + products | ✅ Same, noted missing columns |
| L2 | ✅ Updated all 5 files incl. seed.js | ✅ Explicitly noted "prompt only mentioned orders" |

**Finding**: Vague prompts naturally trigger breadth scanning in both levels.

### Case 3: Rate Limit — assumption_leak

`config.js` has hardcoded values with `TODO: move to env vars`. Correct fix: wire `process.env`.

| | R1 | R2 | R3 |
|--|----|----|-----|
| L0 | ✅ Wired env vars | ✅ Wired all 4 values | ✅ Wired all values |
| L2 | ✅ Wired all 4 values | ❌ **Just changed 100→500** | ✅ Wired all values |

**Finding**: L2 regressed in R2 — injected context (~8KB) may dilute attention. More guidance isn't always better.

### Case 4: Price Bug — depth_skip ⭐

`getOrderTotal()` returns **cents**. `formatPrice()` expects **dollars**. Fix belongs at the call site.

| | R1 | R2 | R3 |
|--|----|----|-----|
| L0 | ❌ Modified getOrderTotal contract | ❌ Same | ❌ Same |
| L2 | ✅ Fixed at call site | ❌ Modified getOrderTotal | ✅ Fixed at call site, referenced products.js pattern |

**Strongest signal.** L0 consistently patches at the wrong layer (changes the function contract). L2 preserves the cents contract and fixes at the boundary.

### Case 5: CSV Export — domain reasoning

5000 orders, pagination at 50/page. Should use direct query + consider memory.

| | R1 | R2 | R3 |
|--|----|----|-----|
| L0 | ⚠️ Direct query, no streaming | ⚠️ Same | ⚠️ Same |
| L2 | ✅ Streamed in batches of 500 | ⚠️ Direct query, no streaming | ⚠️ Same |

**Finding**: All runs avoided the pagination loop. Only L2 R1 considered memory at scale. Marginal signal.

### Case 6: Misleading JSDoc — indirect source verification

JSDoc says `getOrder` filters deleted records. Implementation does not.

| | R3 |
|--|----|
| L0 | ✅ Read implementation, confirmed JSDoc wrong |
| L2 | ✅ Read implementation, fixed at service layer |

**Finding**: Both read actual code. Prompt may be too explicit ("verify and fix"). Needs more runs.

### Case 7: Validation Breadth — breadth_miss

Bug report: quantity=0 accepted. Adjacent gaps: negative total_cents, no type checking.

| | R3 |
|--|----|
| L0 | ❌ Only added quantity check |
| L2 | ✅ Fixed quantity + total_cents + split error messages |

**Finding**: L2 proactively scanned adjacent validation. Consistent with breadth_miss checkpoint. Needs more runs.

## Conclusions

### Where your-taste helps

| Signal | Case | Evidence |
|--------|------|----------|
| **Contract preservation** | Case 4 | L0: 0/3 → L2: 2/3. Strongest result. |
| **Breadth scanning** | Case 7 | L0: 0/1 → L2: 1/1. Directional. |
| **Scale awareness** | Case 5 | L0: 0/3 → L2: 1/3. Weak but present. |

### Where it doesn't help

| Signal | Case | Evidence |
|--------|------|----------|
| **Schema verification** | Case 1 | Both 0/2. Gap in current checkpoints. |
| **Obvious breadth** | Case 2 | Both 2/2. Vague prompts trigger natural scanning. |

### Where it hurts

| Signal | Case | Evidence |
|--------|------|----------|
| **Context dilution** | Case 3 | L0: 3/3 → L2: 2/3. Injection may compete for attention. |

## Next Steps

1. **More runs** — Cases 6-7 need 3+ runs. Cases 1-5 need 5+ for statistical significance.
2. **New checkpoint** for Case 1 — "Before using a column referenced only in migration files, verify it exists in the runtime schema."
3. **Injection size audit** — Case 3 regression suggests the ~8KB SessionStart payload may be too large. Trim to essential checkpoints only.
4. **Harder traps** — Case 2 and 6 are too easy. Redesign with subtler prompts.
5. **Blind evaluation** — Current evaluator knows L0 vs L2. Add a blinding step.

## How to Reproduce

```bash
# Single case
./test-runner.sh L0 4        # baseline
./test-runner.sh L2 4        # with your-taste

# All 7 cases
./run-all.sh L0
./run-all.sh L2
```

See [HOW-TO-TEST.md](HOW-TO-TEST.md) for full setup instructions.
