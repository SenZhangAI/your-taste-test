# Analysis: your-taste A/B Testing

## Executive Summary

**Standalone CLAUDE.md (L1) outperforms per-message injection (L2).** Across 30 test cases with manually verified scoring:

| Level | PASS | Description |
|-------|:----:|-------------|
| **L1** | **83%** | Standalone CLAUDE.md, loaded once at session start |
| **L2** | 73% | Full plugin with per-message hook injection |
| **L0-deep** | 47% | Extended thinking, no guidance |
| **L0** | 37% | Bare Claude baseline |

The improvement from guidance is large and consistent. But simpler delivery (L1) beats more frequent delivery (L2). Per-message injection may cause the AI to "satisfy the checklist" rather than think deeply.

## L1 vs L2: Why Less Is More

### The surprising result

L1 wins 5 cases L2 doesn't, while L2 wins only 2 that L1 doesn't. The gap is concentrated in two areas:

| Category | L1 | L2 | Gap |
|----------|:--:|:--:|:---:|
| Feature Design | **83%** | 50% | +33% |
| Breadth-scan | **83%** | 67% | +16% |

### Case 9: The smoking gun

L1 found **all 4 memory leaks** (requestLog, recentErrors, userCache, priceCache). L2 found only 2 (requestLog, recentErrors). With per-message breadth-scan reminders, the AI appears to "check the box" after finding the first obvious issues, rather than doing an exhaustive scan.

### Hypothesis: over-prompting dampens exploration

When breadth-scan is injected every message, the AI treats it as an obligation to fulfill rather than a reasoning principle to internalize. Once 2 leaks are found, the breadth-scan obligation feels "met." When it's loaded once as a principle, the AI reasons from it more naturally and pushes further.

This has product implications: **the optimal injection frequency may be "once" rather than "always."**

## What the Checkpoints Solve

### Breadth-scan (the core differentiator)

L0 and L0-deep score **17%** on Breadth-scan cases. L1 scores **83%**. This is the largest gap across any dimension. Without explicit breadth-scan guidance, AI fixes the pointed-to file and stops.

| Case | Without checkpoint (L0) | With checkpoint (L1) |
|------|-------------------------|----------------------|
| 2 (soft-delete) | Fixes orders only | Scans all 3 entities, notes different patterns |
| 9 (memory leaks) | Finds 1/4 leaks | Finds **4/4** leaks |
| 12 (ID validation) | Fixes orders route only | Fixes orders + flags "same issue in products.js and users.js" |
| 16 (error handling) | Adds to orders only | Fixes orders + flags users.js/products.js |

### Verification (amplifies native ability)

AI already verifies sometimes; checkpoints make it consistent. L0 scores 50%, both L1 and L2 score 100%.

| Case | What the checkpoint prevents |
|------|------------------------------|
| 6 (JSDoc lie) | Trusting `getOrder` JSDoc instead of reading code |
| 20 (price mismatch) | "Fixing" correct price-snapshot behavior |
| 21 (stale cache) | Blaming the query instead of the cache |

### Scope control (prevents overreach AND underreach)

| Case | Challenge |
|------|-----------|
| 19 | Fix 1-line bug WITHOUT rewriting products (don't overreach) |
| 27 | Rename field BUT warn about breaking change (don't underreach) |

These two cases required opposite behaviors. Solved by:
- "Execute within scope; surface issues beyond scope"
- "Is this a breaking change?" in the Scan checkpoint
- "Don't unify — but when user asks, respond with analysis"

### Security generalization (Case 29)

Only L1 and L2 push back on the dangerous impersonation feature. L0 and L0-deep (even with extended thinking) blindly implement `?as_user` without noticing auth.js has no JWT verification. The principles "surface risks" + "challenge when warranted" + "what could go wrong?" generalize to security without any explicit security rules.

## What the Checkpoints Can't Solve

### Depth of operational thinking

Feature Design is the weakest category for L2 (50%) though L1 manages 83%. The hardest cases require multi-step operational reasoning: N+1 queries, unbounded array input, partial failure semantics.

This is the **3-hop problem**: a checkpoint says "what could go wrong?" but can't guarantee the AI chains 2-3 reasoning steps to reach "unbounded input = DoS" or "per-item getUser = N+1."

### The Case 30 ceiling

Both L1 and L2 score PARTIAL on bulk order creation. Transaction and validation are implemented, but neither considers array size limits or stock checking. Operational depth at this level seems to be at the edge of what principle-based approaches can reliably trigger.

## Prompt Engineering Insights

### Small changes, measurable impact

| Change | Mechanism | Case | Result |
|--------|-----------|------|--------|
| "Is this a breaking change to an API contract, response shape, or public interface?" | Makes AI check for breaking changes before acting | 27 | FAIL → PASS |
| "but when the user explicitly asks about alignment, respond with analysis" | Prevents over-application of "don't unify" rule | 19 | PARTIAL → PASS |
| "Internal code → clean breaks" changed to "Non-breaking → clean breaks" | Reframes decision from code ownership to impact | 27 | FAIL → PASS |

### Anti-patterns discovered

| Anti-pattern | Example | Fix |
|-------------|---------|-----|
| **Double reinforcement** | "Don't unify" in both breadth-scan AND code-clean bullets → AI refuses even when user asks | Qualify one instance with exception |
| **Ambiguous categorization** | "Internal code" vs "external consumers" → AI misclassifies API endpoints | Use impact-based framing ("breaking" vs "non-breaking") |
| **Checklist-style breadth rules** | "grep all module-level Arrays, Maps" → distracted AI on unrelated tasks (Case 3 regression) | Principle-based: "same issue elsewhere?" |
| **Over-injection** | Per-message repetition of breadth-scan → AI checks the box rather than exploring deeply | Once-at-start (L1) outperforms per-message (L2) |

### What works

- **Imperative > suggestive**: "Clean dead code when you encounter them" > "Consider cleaning dead code"
- **Principles with one example**: "Does the same issue exist elsewhere? E.g. you spot a missing input validation on one endpoint — check all sibling endpoints for the same gap"
- **Pipeline structure**: Infer A → Enumerate → Scan → Breadth-scan reads as a workflow, not a checklist
- **Qualified guards**: "Don't X — but when Y, do Z" prevents over-application
- **Load once, not every turn**: L1's single injection lets principles integrate naturally

## Injection Budget

| Component | Size | Content |
|-----------|:----:|---------|
| Standalone CLAUDE.md (L1, once) | ~6.8K | Reasoning Checkpoints + AI-First Principles + user rules |
| — or — | | |
| UserPromptSubmit (L2, per message) | ~2.5K | Reasoning Checkpoints + AI-First Principles |
| SessionStart (L2, once) | ~0.5K | Evolved Checkpoints + Failure Patterns |
| CLAUDE.md (L2, native) | ~3K | User confirmed rules |
| **L2 Total** | **~6K** | |

L1's ~6.8K loaded once outperforms L2's ~6K loaded repeatedly. Total token budget is similar; delivery mechanism matters.

## Evolution: v1 → v5

| Version | Cases | L2 PASS | Key change |
|---------|:-----:|:-------:|------------|
| v1 | 6 | 75% | Slim injection (10K→6K), imperative wording |
| v2 | 10 | ~50% | Added service layer, memory leaks |
| v3 | 10 | ~50% | Human-like prompts, no measurable effect |
| v4 | 20 | 50% | Added 10 new cases (21-28), L0-deep baseline |
| **v5** | **30** | **73%** | Refined Scan + scope rules, L1 added (83%) |

## Multi-turn & Compact Experiment (v5.1)

### Motivation

The v5 single-turn results showed L1 > L2. But does L1's one-time CLAUDE.md loading decay over long conversations? And does `/compact` (context compression) preserve or destroy the checkpoints?

### Experiment Design

**Compact test** (`compact-test.sh`): Real multi-turn sessions using `--resume` for session continuity.
1. 8 filler turns (simple single-point coding tasks to fill context)
2. `/compact` to trigger context compression
3. Critical breadth-scan prompt (Case 9: find 4 memory leaks)

Each condition (L0/L1/L2) run 3 times for reliability.

**Simulated multi-turn** (`multi-turn-runner.sh`): Single prompt with 8 turns of conversation history embedded in the prompt text. Tests attention dilution without session management complexity.

### Results: Compact Test (Case 9, 3 runs each)

| Run | L0 | L1 | L2 |
|:---:|:--:|:--:|:--:|
| 1 | 4/4 | 4/4 | 4/4 |
| 2 | 4/4 | 4/4 | 4/4 |
| 3 | 4/4 | 4/4 | 2/4 (+2 noted) |

**All levels perform well after compact.** Even L0 (bare Claude) finds all 4 leaks consistently.

### Results: Simulated Multi-turn (Case 9, 1 run each)

| Level | Leaks found | Score |
|-------|:-----------:|:-----:|
| L0 | 4/4 | PASS |
| L1 | 2/4 | PARTIAL |

Single runs have high variance — the L0 > L1 inversion is likely noise.

### Key Findings

**1. Compact preserves CLAUDE.md (system context, not compressed).**

CLAUDE.md is system context, not conversation history. `/compact` compresses the conversation but reloads CLAUDE.md fresh.

**2. Codebase familiarity is a confounding variable.**

The 8 filler turns caused the AI to read and modify files across the codebase — including files containing the 4 memory leaks (rate-limiter.js via "request counter" task, product-service.js via "product sorting" task, etc.). After compact, the summary retains "which files I've touched," giving the AI a mental map it wouldn't have in a cold-start scenario. This explains why even L0 scores 4/4 post-compact — it's not that compact "resets to clean state," but that **filler turns gave the AI prior exposure to the leak-containing files**.

**3. Two distinct capabilities being tested.**

| Scenario | What it tests | L0 | L1 |
|----------|--------------|:--:|:--:|
| Single-turn (cold start) | Active discovery via breadth-scan | 37% | **83%** |
| Multi-turn + compact (warm start) | Connecting previously-seen files to a new problem | 4/4 | 4/4 |

Cold-start discovery is where checkpoints shine — the AI has no prior knowledge and must actively search. Warm-start connection is easier because the AI already has a codebase map from prior turns. Both matter in practice: cold-start covers early-session and new-file scenarios; warm-start covers ongoing work in familiar code.

**4. L2's checklist effect persists regardless of context state.**

L2 run 3 found only 2/4 leaks (requestLog + recentErrors), noting the other 2 as "lower priority" without fixing them — even with warm-start advantage. This mirrors the single-turn L2 behavior on Case 9 (PARTIAL). The per-message injection pattern causes under-exploration independent of codebase familiarity.

**5. Single-turn testing remains the authoritative methodology.**

It isolates the cold-start discovery capability — the harder, more differentiating scenario. The v5 single-turn results (30 cases, 4 levels) remain the primary comparison. Multi-turn+compact results are supplementary, demonstrating that accumulated codebase knowledge can substitute for breadth-scan in warm-start scenarios.

### Implications

- **L1's value is concentrated in cold-start scenarios** — session start, new files, unfamiliar code. This is where checkpoints provide the most leverage.
- **Codebase familiarity naturally compensates for lack of checkpoints** in warm-start scenarios. This is good news: even without your-taste, AI improves as it works longer in a codebase.
- **L2's per-message injection hurts even in warm-start.** The checklist effect is inherent to the injection mechanism, not context state. This further supports L1 over L2.
- **Product recommendation unchanged: L1 (export) as default.**
- **Future experiment needed:** Repeat compact test with filler tasks that don't touch leak-containing files (e.g., README edits, config changes) to isolate compact's effect on CLAUDE.md preservation without the familiarity confound.

## Implications for your-taste

1. **Export (L1) should be the default recommendation.** Simpler to set up (no hooks), better results (83% vs 73%). The plugin's value is in generating and evolving the thinking-context, not in per-message injection.

2. **Breadth-scan is the product's differentiator.** 17% → 83% is a 5x improvement. Other reasoning skills are amplified but not as uniquely absent without guidance.

3. **Prompt quality matters more than quantity.** Small, precise changes (1 sentence) produce targeted case flips. The framework should stay lean (~6.8K) and each word should earn its place.

4. **Per-message hooks should be optional, not default.** They may be valuable for very long conversations where instructions decay, but for typical use they over-prompt. This needs separate testing with multi-turn conversations.

5. **Depth problems need different mechanisms.** Feature design quality and multi-hop reasoning can't be solved by prompts alone. Potential: extended thinking (L2-deep), structured planning, or iterative self-review.

6. **Generalization is partial but real.** Security principles generalize (Case 29 PASS) but operational scale concerns don't (Case 30 PARTIAL). This is an inherent limitation — and an acceptable one given the 83% overall success rate.
