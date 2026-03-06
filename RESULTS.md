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
| **Case 6** — Misleading JSDoc | indirect source | ✅ 3/3 | ✅ 3/3 | — |
| **Case 7** — Validation Breadth | breadth_miss | ❌ 0/3 | ✅ 3/4 | **L2 +3** |
| | | **L0: 8/19 (42%)** | **L2: 13/20 (65%)** | |

**L2 wins 3 cases. L0 wins 1 case. 3 ties.**

> Case 7 L2 has 4 data points (one additional run observed during re-runs). All other cells are 2-3 runs.

## Setup

- **Model**: Claude Opus 4.6 via `claude -p`
- **L0**: bare Claude — `--setting-sources ""`, no plugins
- **L2**: your-taste plugin + user CLAUDE.md — `--plugin-dir your-taste`
- **Runs**: 3 rounds each (cases 3-7), 2 rounds (cases 1-2, prompt redesigned after R1)
- **Dates**: 2026-03-06 (R1-R3), 2026-03-07 (R4-R5)

## Per-Run Breakdown

### Case 1: Category Filter — verification_skip

Migration file adds `category` column, but was **never applied** — `db.js` creates tables inline.

| | R2 | R3 |
|--|----|----|
| L0 | ❌ Added `.where('category', ...)` blindly | ❌ Same |
| L2 | ❌ Added filter without schema check | ❌ Same |

**Gap**: Current checkpoints don't cover "verify migration files were actually applied."

---

### Case 2: Soft Delete — breadth_miss

Three routes share `status !== 'deleted'`. Prompt says "update the codebase" (vague).

| | R2 | R3 |
|--|----|----|
| L0 | ✅ Updated orders + users + products | ✅ Same, noted missing columns |
| L2 | ✅ Updated all 5 files incl. seed.js | ✅ Noted "prompt only mentioned orders" |

**Finding**: Vague prompts naturally trigger breadth scanning. Trap too easy.

---

### Case 3: Rate Limit — assumption_leak

`config.js` has hardcoded defaults with `TODO: move to env vars`.

| | R1 | R2 | R3 |
|--|----|----|-----|
| L0 | ✅ Wired env vars | ✅ Wired all 4 values | ✅ Wired all values |
| L2 | ✅ Wired all 4 values | ❌ **Just changed 100→500** | ✅ Wired all values |

**Finding**: L2 regressed in R2 — ~8KB injection may dilute focus.

---

### Case 4: Price Bug — depth_skip ⭐

`getOrderTotal()` returns **cents**. `formatPrice()` expects **dollars**. Fix belongs at the call site.

| | R1 | R2 | R3 |
|--|----|----|-----|
| L0 | ❌ Modified getOrderTotal contract | ❌ Same | ❌ Same |
| L2 | ✅ Fixed at call site | ❌ Modified getOrderTotal | ✅ Referenced products.js pattern |

**Strongest signal.** L0 always patches wrong layer (0/3). L2 preserves contract (2/3).

---

### Case 5: CSV Export — domain reasoning

5000 orders, pagination at 50/page. Should use direct query + consider memory.

| | R1 | R2 | R3 |
|--|----|----|-----|
| L0 | ⚠️ Direct query, no streaming | ⚠️ Same | ⚠️ Same |
| L2 | ✅ Batches of 500, explicit memory note | ⚠️ Direct query, no streaming | ⚠️ Same |

**Finding**: All avoided pagination loop. Only L2 R1 considered memory. Marginal.

---

### Case 6: Misleading JSDoc — indirect source verification

JSDoc says `getOrder` filters deleted records. Implementation does **not**.

| | R3 | R4 | R5 |
|--|----|----|-----|
| L0 | ✅ Read impl, confirmed JSDoc wrong | ✅ Removed redundant checks | ✅ Noted caller impact |
| L2 | ✅ Fixed at service layer | ✅ Cleanup + responsibility note | ✅ Cleanup + createOrder impact |

**Finding**: Both always pass (3/3 each). L2 consistently cleans up redundant route checks; L0 sometimes does, sometimes leaves as "harmless." Core trap (trust JSDoc vs read code) doesn't differentiate — prompt says "verify" which naturally leads to reading code.

---

### Case 7: Validation Breadth — breadth_miss ⭐

Bug: quantity=0 accepted. Adjacent gaps: negative total_cents, no type checking.

| | R3 | R4 | R5 |
|--|----|----|-----|
| L0 | ❌ Only quantity check | ❌ Same | ❌ Same |
| L2 | ✅ quantity + total_cents + errors | ✅ quantity + total_cents + errors | ✅ quantity + total_cents |

**Second strongest signal.** L0 never scans adjacent validation (0/3). L2 proactively fixes total_cents (3/3 in scored runs, 3/4 including one overwritten run that only fixed quantity).

---

## Conclusions

### Where your-taste helps

| Signal | Case | L0 → L2 | Runs | Confidence |
|--------|------|----------|------|------------|
| **Contract preservation** | 4 — depth_skip | 0/3 → 2/3 | 6 | High |
| **Adjacent gap scanning** | 7 — breadth_miss | 0/3 → 3/4 | 7 | High |
| **Scale awareness** | 5 — domain reasoning | 0/3 → 1/3 | 6 | Low |

### No difference

| Case | Result | Why |
|------|--------|-----|
| 1 — verification_skip | Both 0/2 | Checkpoint gap: no rule covers migration ≠ applied |
| 2 — breadth_miss | Both 2/2 | Vague prompt = natural scanning |
| 6 — indirect source | Both 3/3 | "Verify and fix" prompt is too explicit |

### Where it hurts

| Case | L0 → L2 | Why |
|------|----------|-----|
| 3 — assumption_leak | 3/3 → 2/3 | Context dilution: ~8KB injection competes for attention |

## Optimization Backlog

### New checkpoints
- [ ] Case 1 gap: "Before using a DB column referenced only in migration files, verify it exists in the runtime schema — migrations may be pending or never applied"

### Injection optimization
- [ ] Case 3 regression: audit SessionStart payload size (~8KB). Trim to highest-signal checkpoints only. Quality > quantity.

### Test improvements
- [ ] Cases 1-2: need 1+ more rounds (currently 2)
- [ ] Cases 3-5: need 2+ more rounds for 5-run target
- [ ] Case 2: hide pattern in middleware, not just route files
- [ ] Case 6: remove "verify" from prompt to test natural trust-vs-read behavior
- [ ] Add blind evaluation step (evaluator doesn't know L0 vs L2)

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
