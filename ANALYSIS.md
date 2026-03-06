# Analysis: your-taste A/B Testing

## Executive Summary

**breadth_miss is the only checkpoint type that creates measurable L0/L2 differentiation.** Opus 4.6 natively handles verification_skip, assumption_leak, overreach, and depth_skip. The only gap the checkpoints reliably fill is "scan adjacent files after completing the primary fix."

Even within breadth_miss, differentiation is fragile: it works when the task naturally requires 2-3 files (Case 2), but fails when it requires 4+ files (Case 9) — both L0 and L2 stop at the same depth.

## Test Configuration

| Layer | Size |
|-------|------|
| CLAUDE.md (your-taste section) | ~3K |
| SessionStart (slim) | ~0.5K |
| UserPromptSubmit (abstract checkpoints) | ~2.5K |
| **Total L2-slim injection** | **~6K** |

Source codebase: 15+ files Express/Knex order API with varied soft-delete patterns, service layer, middleware, deliberate inconsistencies.

## V3 Results (10 cases × L0/L2-slim)

| Case | Checkpoint | L0 | L2-slim | Winner |
|------|-----------|-----|---------|--------|
| **2** Soft Delete Migration | breadth_miss | PARTIAL — missed products `is_active` | **PASS** — noted users done, products different | **+L2** |
| **3** Rate Limit Config | assumption_leak | **PASS** — caught env inconsistency | PARTIAL — bumped value but got distracted by requestLog | **+L0** |
| **6** Misleading JSDoc | verification_skip | FAIL — added redundant filter, missed users.js | FAIL — same | Tie |
| **8** Auth Never Enforces | assumption_leak | PASS — found decorative auth | PASS — same, more detail | Tie |
| **9** Memory Leak (4 leaks) | breadth_miss | PARTIAL 2/4 | PARTIAL 2/4 | Tie |
| **10** Order Status Update | second-order | PASS — blocked 'deleted', validated | PASS — same | Tie |
| **15** .env vs config.js | verification_skip | PASS — found hardcoded RATE_LIMIT | PASS — same + dotenv warning | Tie |
| **18** Add User to Orders | depth_skip | PASS — used JOIN | PASS — used JOIN | Tie |
| **19** Set deleted_at | overreach | PASS — 1-line fix, scoped | PASS — same | Tie |
| **20** Price Mismatch | verification_skip | PASS — correctly refused | PASS — same | Tie |

### Score Summary

| Result | Count | Cases |
|--------|-------|-------|
| **+L2** | 1 | Case 2 |
| **+L0** | 1 | Case 3 |
| Both pass | 6 | Cases 8, 10, 15, 18, 19, 20 |
| Both fail | 1 | Case 6 |
| Both partial | 1 | Case 9 |

## Key Findings

### 1. breadth_miss is the ONLY effective differentiator

Across v2 and v3 testing, only breadth_miss cases (2, 6) showed L2 advantage. All other checkpoint types are natively handled by Opus:

| Checkpoint Type | Opus Native? | Evidence |
|----------------|-------------|----------|
| verification_skip | Yes | Cases 8, 15, 20: L0 reads code before trusting docs |
| assumption_leak | Yes | Cases 3, 8: L0 notices env inconsistencies, decorative code |
| overreach | Yes | Cases 19, 20: L0 scopes correctly, doesn't over-fix |
| depth_skip | Yes | Case 18: L0 uses JOIN instead of N+1 |
| **breadth_miss** | **No** | Case 2: L0 misses products pattern. Case 9: both miss 2/4 leaks |

### 2. Checkpoints can hurt (Case 3: +L0)

L2-slim on Case 3 bumped the rate limit value correctly but then got sidetracked reporting the `requestLog` memory leak — the breadth_miss checkpoint triggered a scan of rate-limiter.js and found an unrelated issue, **derailing from the user's actual request**. L0 stayed focused.

This is the cost of always-on breadth scanning: it can distract from simple, focused tasks.

### 3. Case 9 reveals the breadth ceiling

Both L0 and L2-slim found 2/4 memory leaks (requestLog + recentErrors). Neither found the caches in service files. L0 rationalized "bounded by entity count." L2-slim added TTL but classified them as low severity.

The breadth_miss checkpoint says "scan adjacent files" but doesn't overcome the AI's tendency to rationalize away lower-severity issues once the obvious fix is found.

### 4. Case 6 is genuinely hard — both fail

Neither L0 nor L2-slim found the real bug: `user-service.js:getUserOrders()` uses `whereNull('deleted_at')` to filter orders, but orders use status-based soft-delete and never set `deleted_at`. Both focused on the reported getOrder JSDoc issue and stopped there.

The bug requires:
1. Recognizing the reported issue is actually false (GET /orders/:id works fine)
2. Thinking "where ELSE are orders queried?"
3. Tracing through user-service.js to find the cross-file soft-delete mismatch

This is a 3-hop reasoning chain that neither the checkpoints nor Opus's native ability reliably triggers.

### 5. Prompt humanization had no measurable effect

Making prompts more casual (typos, abbreviations, ambiguity) didn't change outcomes compared to clean prompts. Opus handles informal input well natively.

## Historical Context (v1 → v3)

### v1 (original slim, 6 differentiating cases)
- Found that examples disambiguate principles, domain examples anchor to wrong contexts
- Imperative wording > suggestive
- 30K→10K injection improved pass rate from 44% to 75%

### v2 (upgraded difficulty, 10 "both pass" cases)
- Cases 2, 6 showed L2 advantage (breadth_miss)
- Cases 3, 8, 9, 10, 19, 20: all L0 PASS — no differentiation

### v3 (service layer + 4 memory leaks + human prompts)
- Case 2 still differentiates (+L2)
- Case 3 shows L2 regression (+L0)
- Case 9 at 4 leaks is too hard for both
- 6/10 remain both-pass

## Implications for your-taste

1. **breadth_miss is the product's core value proposition.** All other reasoning improvements are nice-to-have that Opus already handles.

2. **The checkpoint needs better calibration.** Current formulation either doesn't trigger (Case 9: stops at 2/4) or over-triggers (Case 3: finds unrelated issues).

3. **Potential refinement**: Instead of "scan all adjacent files," use task-type-aware breadth rules:
   - Bug fix → "grep for all callers of the function you're changing"
   - Migration → "enumerate all entity types that use the same pattern"
   - Memory leak → "grep for all module-level arrays, Maps, and objects"

4. **Hard problems (Case 6) need reasoning chains, not rules.** The 3-hop chain "verify claim → where else is this queried? → trace service layer" can't be encoded as a single checkpoint. This may require a different mechanism.

5. **Context budget is well-optimized at ~6K.** Going above this adds noise. The checkpoints should stay lean and focused on breadth_miss variants.
