# your-taste A/B Test Results

> Testing whether your-taste's reasoning quality injection makes Claude avoid specific reasoning traps.

## Setup

- **Model**: Claude Opus 4.6 via `claude -p`
- **L0** (baseline): raw Claude, no user CLAUDE.md, no plugins
- **L2** (your-taste): plugin hooks + user CLAUDE.md with learned rules
- **Date**: 2026-03-06, single run per level per case

## Results

| Case | Trap | L0 | L2 | Verdict |
|------|------|----|----|---------|
| 1 - Date Range | verification_skip: README says Prisma, code uses Knex | PASS | PASS | Both read actual code. Trap not triggered. |
| 2 - Soft Delete | breadth_miss: 3 routes share same pattern | FAIL | FAIL | Neither scanned adjacent routes. |
| 3 - Rate Limit | assumption_leak: config.js is dev default | PASS | PASS+ | Both wired env vars. L2 added scaling concern. |
| 4 - Price Bug | depth_skip: cents vs dollars contract mismatch | PARTIAL | PASS | **L0 changed getOrderTotal contract. L2 fixed at call site.** |
| 5 - CSV Export | domain reasoning: 5000 rows, 50/page pagination | FAIL | PASS | **L0 loaded all to memory. L2 streamed in batches.** |

**Score: L0 = 2.5/5, L2 = 4/5**

## Detailed Analysis

### Case 1: Date Range Query (verification_skip)
**Trap**: README claims Prisma ORM, but actual code uses Knex. Empty `schema.prisma` exists as decoy.

- **L0**: Used Knex syntax correctly. Read the actual source files.
- **L2**: Same, plus added inclusive end-of-day handling (`23:59:59`) and extracted `applyFilters` helper.
- **Why both passed**: `claude -p` reads the codebase files before implementing, so the README mismatch was caught naturally. This trap may need a more subtle design to trigger verification_skip.

### Case 2: Soft Delete Migration (breadth_miss)
**Trap**: 3 route files (orders/users/products) all use `status !== 'deleted'`. Only orders is mentioned in prompt.

- **L0**: Modified only orders.js and order-service.js. No mention of users.js or products.js.
- **L2**: Same scope. Added deeper architectural notes about query-level vs handler-level filtering, but didn't scan adjacent routes.
- **Why both failed**: The breadth_miss checkpoint exists in observations.md but wasn't sufficient to trigger scanning in this specific task. The prompt explicitly says "in orders.js" which may cause both levels to scope tightly. Consider a vaguer prompt like "migrate our soft-delete approach."

### Case 3: Rate Limit Increase (assumption_leak)
**Trap**: `config.js` has hardcoded defaults with a TODO comment about env vars. `.env.example` has the real config path.

- **L0**: Noticed the TODO, wired `process.env.RATE_LIMIT`, updated `.env.example`. Clean fix.
- **L2**: Same fix, plus added a forward-looking note: "the in-memory rate limiter stores every timestamp per IP in an array. At 500 req/min under heavy traffic, this is fine, but if you ever need to go significantly higher, you'd want a Redis sliding window."
- **Delta**: L2's scaling observation demonstrates domain reasoning beyond the immediate task.

### Case 4: Price Display Bug (depth_skip)
**Trap**: `getOrderTotal()` returns cents. `formatPrice()` expects dollars. The bug is at the call site, not in either function.

- **L0**: Modified `getOrderTotal` to divide by 100 internally. **Changed the function's documented contract** (JSDoc says "returns cents") without updating all callers or considering downstream impact.
- **L2**: Added `/ 100` at the call site in `orders.js`, preserving `getOrderTotal`'s cents contract. Noted "as documented in its JSDoc."
- **Delta**: L2 respected the existing API contract and fixed at the correct level. This directly matches the "depth_skip" pattern - L0 patched the symptom at the wrong layer.

### Case 5: CSV Export (domain reasoning)
**Trap**: 5000 orders in DB, existing pagination uses limit=50. Naive approach = 100 API calls or load all to memory.

- **L0**: Created `getAllOrders()` that fetches all records at once. No streaming, no batching, no performance consideration.
- **L2**: "Streams all non-deleted orders as CSV in batches of 500 rows... to avoid loading all 5000+ orders into memory at once." Proper streaming implementation.
- **Delta**: Clear domain reasoning difference. L2 estimated the data scale and chose an appropriate approach.

## Observations

### What worked
- **Case 4 & 5 show clear your-taste value**: Contract preservation (depth_skip) and scale awareness (domain reasoning) are exactly the patterns observations.md targets.
- **L2's "extra notes"** (Case 3 scaling concern, Case 2 architectural commentary) demonstrate broader thinking even when both levels reach the same fix.

### What didn't work
- **Case 1 trap was too obvious**: Claude naturally reads source files in `claude -p` mode, making the README/Prisma mismatch easy to discover. Need a subtler verification_skip trap.
- **Case 2 breadth_miss wasn't triggered**: Even with the checkpoint, the explicit "in orders.js" scoping in the prompt overrode the scanning instinct. Prompt wording matters.

### Improvements for next run
1. Case 1: Make the mismatch subtler (e.g., README says "PostgreSQL" but DB is actually SQLite, affecting query syntax)
2. Case 2: Use vaguer prompt: "We're migrating soft-delete to use timestamps. Start with the orders module."
3. Run 3x per level for statistical significance
4. Add Case 6 targeting failure_pattern: "indirect source conclusions need primary verification"

## How to Reproduce

See [HOW-TO-TEST.md](HOW-TO-TEST.md) for full instructions.
