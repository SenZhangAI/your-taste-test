# your-taste A/B Test Results

> Does [your-taste](https://github.com/SenZhangAI/your-taste)'s reasoning checkpoint injection make Claude avoid reasoning traps?

## Configuration

| Component | L0 (bare Claude) | L2-slim (your-taste) |
|-----------|-------------------|----------------------|
| CLAUDE.md | None | 6.8K (optimized) |
| SessionStart hook | None | ~0.5K |
| UserPromptSubmit hook | None | ~2.5K (abstract checkpoints) |
| **Total injection** | **0** | **~10K** |

Codebase: 15+ file Express/Knex order API with service layer, 3 varied soft-delete patterns, 4 memory leaks, deliberate doc/code mismatches.

## Test Matrix (20 cases)

### v3 Results (10 stress-tested cases)

Source code upgraded with service layer indirection, 4 memory leaks across files, human-like prompts with typos/ambiguity.

|  | Checkpoint | L0 (bare) | L2-slim | Delta |
|--|-----------|-----------|---------|-------|
| **Case 2** — Soft Delete Migration | breadth_miss | ⚠️ PARTIAL — missed products `is_active` | ✅ PASS — noted all 3 patterns | **+L2** |
| **Case 3** — Rate Limit Config | assumption_leak | ✅ PASS — caught env inconsistency | ⚠️ PARTIAL — bumped value but distracted by requestLog | **+L0** |
| **Case 6** — Misleading JSDoc | verification_skip + breadth | ❌ FAIL — added redundant filter | ❌ FAIL — same, missed user-service.js bug | — |
| **Case 8** — Auth Never Enforces | assumption_leak | ✅ PASS — found decorative auth | ✅ PASS — same + more detail | — |
| **Case 9** — Memory Leak (4 leaks) | breadth_miss | ⚠️ PARTIAL 2/4 — requestLog + recentErrors | ⚠️ PARTIAL 2/4 — same + TTL on caches | — |
| **Case 10** — Order Status Update | second-order | ✅ PASS — blocked 'deleted', validated | ✅ PASS — same, used ORDER_STATUSES | — |
| **Case 15** — .env vs config.js | verification_skip | ✅ PASS — found hardcoded RATE_LIMIT | ✅ PASS — same + dotenv warning | — |
| **Case 18** — Add User to Orders | depth_skip | ✅ PASS — used JOIN | ✅ PASS — used JOIN | — |
| **Case 19** — Set deleted_at | overreach | ✅ PASS — 1-line fix, scoped | ✅ PASS — same | — |
| **Case 20** — Price Mismatch | verification_skip | ✅ PASS — correctly refused to "fix" | ✅ PASS — same | — |

### v1 Results (10 cases, pre-service-layer codebase)

These cases were tested on the simpler v1 codebase (11 files, no service layer). Results may differ on v3 codebase.

|  | Checkpoint | L0 (bare) | L2-slim | Delta |
|--|-----------|-----------|---------|-------|
| **Case 1** — Category Filter | verification_skip | ❌ FAIL | ❌ FAIL | — |
| **Case 4** — Price Bug | depth_skip | ❌ FAIL | ✅ PASS | **+L2** |
| **Case 5** — CSV Export | domain reasoning | ❌ FAIL | ⚠️ PARTIAL | +L2 |
| **Case 7** — Validation Breadth | breadth_miss | ❌ FAIL | ❌ FAIL | — |
| **Case 11** — Stock Deduction | second-order | ⚠️ PARTIAL | ✅ PASS | **+L2** |
| **Case 12** — ID Validation | breadth_miss | ❌ FAIL | ✅ PASS | **+L2** |
| **Case 13** — Phantom Sort | verification_skip | ✅ PASS | ✅ PASS | — |
| **Case 14** — Response Format | depth_skip | ❌ FAIL | ❌ FAIL | — |
| **Case 16** — Error Handling | breadth + depth | ❌ FAIL | ✅ PASS | **+L2** |
| **Case 17** — PATCH Fields | depth + second-order | ❌ FAIL | ⚠️ PARTIAL | +L2 |

### Aggregate (v3 stress tests)

| Metric | L0 | L2-slim |
|--------|----|----|
| PASS | 6 | 6 |
| PARTIAL | 2 | 2 |
| FAIL | 2 | 2 |
| Cases where L2 > L0 | — | 1 (Case 2) |
| Cases where L0 > L2 | 1 (Case 3) | — |

### Aggregate (all 20 cases, v1+v3 combined)

| Metric | L0 | L2-slim |
|--------|----|----|
| PASS | 10 | 13 |
| PARTIAL | 3 | 4 |
| FAIL | 7 | 3 |
| **L2 wins** | — | 6 (Cases 2, 4, 5, 11, 12, 16) |
| **L0 wins** | 1 (Case 3) | — |

## Key Findings

### 1. breadth_miss is the only reliable differentiator

Opus 4.6 natively handles verification_skip, assumption_leak, overreach, and depth_skip. The only checkpoint type that creates measurable L0/L2 differentiation is breadth_miss — "scan adjacent files after completing the primary fix."

| Checkpoint Type | Opus Native? | Evidence |
|----------------|-------------|----------|
| verification_skip | Yes | Cases 8, 15, 20: L0 reads code before trusting docs |
| assumption_leak | Yes | Cases 3, 8: L0 notices env inconsistencies |
| overreach | Yes | Cases 19, 20: L0 scopes correctly |
| depth_skip | Yes | Case 18: L0 uses JOIN instead of N+1 |
| **breadth_miss** | **No** | Case 2: L0 misses products pattern |

### 2. Checkpoints can hurt (Case 3: +L0)

L2-slim on Case 3 correctly bumped the rate limit but then got sidetracked reporting the `requestLog` memory leak — the breadth_miss checkpoint triggered an adjacent-file scan and found an unrelated issue, **derailing from the user's request**. L0 stayed focused.

### 3. Hard problems need reasoning chains, not rules

Case 6 requires a 3-hop chain: verify the reported bug is false → think "where ELSE are orders queried?" → trace through user-service.js to find the real bug. Neither L0 nor L2 can do this — it's beyond single-checkpoint reach.

### 4. 4-leak breadth test reveals ceiling

Case 9 has leaks in rate-limiter.js (requestLog), logger.js (recentErrors), user-service.js (userCache), product-service.js (priceCache). Both L0 and L2 find 2/4 — the "obvious" ones. Both rationalize caches as "bounded by entity count."

### 5. Human-like prompts don't change outcomes

Making prompts more casual (typos, abbreviations, ambiguity) had no measurable effect. Opus handles informal input well natively.

## Implications for your-taste

1. **breadth_miss is the core value proposition.** Focus checkpoint refinement here.
2. **Need task-type-aware breadth rules:** bug fix → grep callers; migration → enumerate patterns; memory leak → grep module-level collections.
3. **Checkpoint over-triggering is a real risk** (Case 3). Simple tasks don't need breadth scanning.
4. **3-hop reasoning chains** (Case 6) need a different mechanism than single checkpoints.
5. **~6K injection is the sweet spot.** More adds noise.

## How to Reproduce

```bash
# Single case
./test-runner.sh L0 9        # baseline
./test-runner.sh L2-slim 9   # your-taste enabled

# Results saved to results/
```

See [ANALYSIS.md](ANALYSIS.md) for the full optimization history (v1 → v3).
