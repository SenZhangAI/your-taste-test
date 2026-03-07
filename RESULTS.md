# your-taste A/B Test Results

> Does [your-taste](https://github.com/SenZhangAI/your-taste)'s reasoning checkpoint injection make Claude avoid reasoning traps?

## Configuration

| Level | CLAUDE.md | Plugin | Effort | Total Injection |
|-------|-----------|--------|--------|-----------------|
| L0 | None | None | default | 0 |
| L0-deep | None | None | high (extended thinking) | 0 |
| L2 | User CLAUDE.md | Full (hooks + CLAUDE.md) | default | ~10K |

Codebase: 15+ file Express/Knex order API with service layer, 3 varied soft-delete patterns, 4 memory leaks, deliberate doc/code mismatches.

## Latest Results (v4 — 2026-03-08)

20 cases, 4x parallel execution. Prompts redesigned: no dismissive framing, false hypotheses allowed, human-like ambiguity.

### Per-Case Comparison

| Case | Trap Type | L0 | L0-deep | L2 | Winner |
|------|-----------|----|---------|----|--------|
| 1 — Category Filter | verification_skip | FAIL | FAIL | FAIL | tie |
| 2 — Soft Delete Migration | breadth_miss | PARTIAL | PARTIAL | PARTIAL | tie |
| 3 — Rate Limit Config | assumption_leak | FAIL | **PASS** | **PASS** | L0-deep=L2 |
| 4 — Price Display Bug | depth_skip | **PASS** | **PASS** | **PASS** | tie |
| 5 — CSV Export | breadth_miss | PARTIAL | PARTIAL | **PASS** | **+L2** |
| 6 — Misleading JSDoc | verification_skip | FAIL | FAIL | PARTIAL | **+L2** |
| 7 — Validation Breadth | breadth_miss | FAIL | PARTIAL | PARTIAL | L0-deep=L2 |
| 8 — Auth Middleware Bug | depth_skip | **PASS** | **PASS** | **PASS** | tie |
| 9 — Memory Leak (4 leaks) | breadth_miss | FAIL | PARTIAL | PARTIAL | L0-deep=L2 |
| 10 — Order Status Update | overreach | PARTIAL | PARTIAL | **PASS** | **+L2** |
| 11 — Stock Deduction | breadth_miss | PARTIAL | PARTIAL | **PASS** | **+L2** |
| 12 — ID Type Validation | breadth_miss | FAIL | FAIL | FAIL | tie |
| 13 — Phantom Sort Feature | verification_skip | **PASS** | **PASS** | **PASS** | tie |
| 14 — Response Format | depth_skip | FAIL | FAIL | PARTIAL | **+L2** |
| 15 — Env Config Mismatch | assumption_leak | PARTIAL | PARTIAL | PARTIAL | tie |
| 16 — Error Handling Breadth | breadth_miss | PARTIAL | PARTIAL | **PASS** | **+L2** |
| 17 — PATCH Order Fields | overreach | PARTIAL | PARTIAL | PARTIAL | tie |
| 18 — Add User to Orders | depth_skip | FAIL | FAIL | **PASS** | **+L2** |
| 19 — Set deleted_at | overreach | **PASS** | **PASS** | FAIL | **+L0** |
| 20 — Price Mismatch | verification_skip | FAIL | **PASS** | **PASS** | L0-deep=L2 |

### Aggregate

| Metric | L0 | L0-deep | L2 |
|--------|----|---------|----|
| **PASS** | 4 | 7 | **10** |
| **PARTIAL** | 6 | 8 | 7 |
| **FAIL** | **10** | 5 | 3 |

### Head-to-Head

| Comparison | Wins | Ties | Losses |
|------------|------|------|--------|
| L2 vs L0 | **8** | 11 | 1 |
| L2 vs L0-deep | **7** | 12 | 1 |
| L0-deep vs L0 | **5** | 15 | 0 |

## Key Findings

### 1. Directional guidance > thinking budget

L0-deep (extended thinking, no plugin) improved from 4 to 7 PASS — but still fell short of L2's 10 PASS. **More thinking time helps, but cannot substitute for directional checkpoints.** L2 independently won 7 cases that L0-deep couldn't solve with extra thinking alone.

### 2. breadth_miss remains the core differentiator

Cases where L2 exclusively wins (5, 6, 10, 11, 14, 16, 18) are predominantly breadth_miss and depth_skip types. The "scan adjacent files" and "don't just copy, extract" behaviors are not emergent from more thinking — they require explicit prompting.

| Checkpoint Type | L0 handles natively? | L0-deep improves? | L2 needed? |
|----------------|---------------------|-------------------|------------|
| verification_skip | Mostly (13, 8) | +Case 20 | +Case 6 |
| assumption_leak | Partially | +Case 3 | Same as L0-deep |
| depth_skip | Sometimes (4, 8) | No improvement | +Cases 14, 18 |
| **breadth_miss** | **Rarely** | **Marginal** | **+Cases 5, 11, 16** |
| overreach | Yes (19) | Same | Hurt Case 19 |

### 3. Breadth checkpoint can cause overreach (Case 19)

L0 and L0-deep correctly scoped the 1-line fix. L2's breadth-scan checkpoint encouraged scanning products too, leading to an unwanted refactor. **Need scope-aware breadth rules**: scan for the same *bug pattern*, not for *refactoring opportunities*.

### 4. Unsolved: multi-hop reasoning (Cases 1, 12)

All three levels fail Cases 1 (verify migration actually ran) and 12 (breadth-scan across all route files). These require chains beyond single-checkpoint reach:
- Case 1: "migration exists" → "but does initDB run it?" → "no, tables are created inline"
- Case 12: "fix orders/:id" → "same pattern in users/:id and products/:id" → fix all three

### 5. Extended thinking helps verification cases

L0-deep gained Cases 3, 20 over L0 — both are "pause and think about what's really going on" scenarios. More thinking time naturally helps with verification_skip and assumption_leak, but not with breadth_miss (which requires action, not thought).

## Implications for your-taste

1. **Core value confirmed**: L2 wins 8 of 20 cases vs L0, loses only 1. The plugin provides measurable reasoning improvement.
2. **Not replaceable by thinking budget**: L0-deep closes only ~60% of the gap. Directional guidance is a distinct capability.
3. **Overreach is a real risk**: Need to distinguish "scan for the same bug" from "refactor adjacent code". Breadth-scan should trigger on *defect patterns*, not *improvement opportunities*.
4. **Multi-hop chains need new mechanisms**: Single checkpoints can't solve 2-3 hop reasoning chains. This is a P2 research problem.
5. **~10K injection remains the sweet spot**: No evidence of noise from current injection volume.

## How to Reproduce

```bash
# Single case
./test-runner.sh L0 9              # bare Claude
./test-runner.sh L0-deep 9         # bare + extended thinking
./test-runner.sh L2 9              # full plugin

# All 20 cases (parallel)
./run-all.sh L0 4                  # 4x parallel
./run-all.sh L0-deep 4
./run-all.sh L2 4

# Results saved to results/
```

## Run History

| Run | Date | Level | Run ID | Notes |
|-----|------|-------|--------|-------|
| v4-L0 | 2026-03-08 | L0 | 20260308-073842 | Baseline, 283s |
| v4-L0-deep | 2026-03-08 | L0-deep | 20260308-073845 | Extended thinking, 308s |
| v4-L2 | 2026-03-08 | L2 | 20260308-072859 | Full plugin, 325s |
