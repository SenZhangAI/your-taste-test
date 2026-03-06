# Analysis: Abstract Principles vs Domain Examples

> Core finding: **Examples disambiguate principles; domain-specific examples anchor to irrelevant contexts.**
>
> The role of examples is to clarify scope and completion criteria — not to demonstrate domain expertise. Good examples are universal operations (grep, search, check) with explicit scope (same directory, same endpoint). Bad examples reference specific business entities or tech stacks.

This document records the evidence behind this conclusion, derived from controlled A/B testing of your-taste's injection payload.

## The Problem

The original observations.md (18K chars, Chinese) contains 8 reasoning checkpoints, each with 10-20 domain-specific examples from Sen's real projects (card processing, Prisma queries, supplier integrations, i18n, Docker). When injected into a test codebase (simple Express/Knex orders API), these examples:

1. **Dilute attention** on simple tasks (Cases 3, 15: L0 outperforms L2)
2. **Anchor AI to irrelevant domains** — the breadth_miss checkpoint's examples about "cardNumber desc_key" and "Prisma调用" don't trigger when the task involves Express route files
3. **Compete for context** — 10.5K chars of Chinese text alongside an English codebase

## The Experiment

Created a "slim" observations.md (3K chars, English) with:
- Same abstract principles, stripped of all domain examples
- 1-2 generic examples per checkpoint instead of 10-20 domain-specific ones
- 2 new checkpoints for uncovered failure modes (field editability, user premise questioning)
- Domain Reasoning and detailed Failure Patterns sections removed entirely

### Injection Size Comparison

| Layer | Original | Slim |
|-------|----------|------|
| CLAUDE.md your-taste section | ~3K | ~3K (unchanged) |
| SessionStart (Domain + Failures) | ~4.2K | ~0.5K |
| UserPromptSubmit (Checkpoints) | ~3.3K | ~2.5K |
| **Total** | **~10.5K** | **~6K** |

## Results (6 differentiating cases, 2-3 rounds each)

| Case | Checkpoint | L0 | L2 (18K) | Slim v1 (3K) | Slim v2 (3K) |
|------|-----------|-----|----------|-------------|-------------|
| **3** Rate Limit | assumption_leak | 3/3 | 2/3 | 3/3 | — |
| **4** Price Bug | depth_skip | 0/3 | 2/3 | 3/3 | — |
| **7** Validation | breadth_miss | 0/3 | **3/4** | 0.5/3 | 0.5/2 |
| **12** ID Validation | breadth_miss | 0/2 | 0/2 | 1.5/3 | **2/2** |
| **15** .env Mismatch | verify+assumption | 1/2 | 0/2 | 0.5/3 | — |
| **17** PATCH Fields | depth+business | 0/2 | 0/2 | 3/3 | — |

### What Improved

- **Case 3** (3/3): Context dilution eliminated. L2-original lost R2 because 10.5K of irrelevant Chinese text competed for attention on a simple "wire env vars" task. Slim has no such problem.
- **Case 4** (3/3): More stable than L2-original (2/3). The abstract principle "fix at the right layer, don't change the contract" triggers 100% vs ~67% with domain examples.
- **Case 12** (2/2 after v2): From 0% to 100%. The strengthened breadth-scan wording ("immediately grep... this is not optional... search the entire routes/ directory before considering the task done") made the difference.
- **Case 17** (3/3): New checkpoint "scrutinize field editability on mutation endpoints" converted a both-fail case to 100% pass.

### What Regressed

- **Case 7** (0.5/3 vs 3/4): The original Chinese breadth_miss examples — while domain-specific — included "修改配置时只更新第一个相关项而未先枚举所有同类配置项" which happened to generalize to validation fields. Stripping all examples lost this serendipitous hit. This is the cost of full abstraction.

### What Stayed Hard

- **Case 15** (0.5/3): Requires understanding that `.env.example` has no runtime effect without dotenv — neither abstract principles nor domain examples help with this kind of infrastructure knowledge gap.

## Key Insights

### 1. Examples disambiguate; domain examples anchor

A principle without examples is ambiguous — "scan adjacent components" doesn't tell AI *what* to scan or *how far*. But the wrong examples are worse than none: "cardNumber desc_key" anchors the AI to SQL batch operations when the task is Express routes.

The right examples clarify **scope** (same directory, same endpoint, all call sites) and **action** (grep, check, enumerate) without referencing specific tech stacks or business entities.

| Example type | Effect | Instance |
|-------------|--------|----------|
| **Domain-anchoring** | Harmful noise | "cardNumber desc_key batch SQL", "Prisma调用" |
| **Disambiguating** | Effective | "grep sibling route files in the same directory" |
| **No example (pure abstract)** | Unstable | "list all parallel components" |

### 2. Imperative wording > suggestive wording

Case 12's breakthrough came from changing:
```
"list all parallel components... Check each one."  (suggestive)
```
to:
```
"immediately run a grep... This is not optional... before considering the task done."  (imperative)
```

The AI treats suggestive language as optional advice. Imperative language with explicit completion criteria ("before considering the task done") acts as a gate.

### 3. Fewer, sharper checkpoints beat comprehensive coverage

8 checkpoints at 3K chars outperform 8 checkpoints at 18K chars. The marginal value of each additional example is negative after the first one — it adds noise without adding understanding.

### 4. New targeted checkpoints unlock previously impossible cases

Case 17 went from 0% (both L0 and L2-original) to 100% with a single new checkpoint about field editability. This proves that checkpoint quality matters more than checkpoint quantity.

### 5. Some failures are beyond checkpoint reach

Case 15 requires infrastructure knowledge (dotenv mechanics) that no amount of reasoning scaffolding can provide. This represents the boundary of what reasoning checkpoints can do — they improve *how* AI thinks, not *what* AI knows.

## CLAUDE.md Optimization

After optimizing observations.md, we also trimmed CLAUDE.md itself:
- Moved Systematic Thinking (6 bullets) and Infer A from C (4 bullets) into your-taste rules
- Consolidated 15 your-taste rules into 13, organized by category (Reasoning Style, Verification, Action Principles, Data & Communication)
- Result: 12.6K → 6.8K with zero regression

### Final Configuration Comparison

| Config | Total injection | 6-case score | Pass rate |
|--------|----------------|-------------|-----------|
| L0 (bare Claude) | 0 | 4.5/17 | 26% |
| L2 original (old CLAUDE 12.6K + obs 18K) | ~30K | 7.5/17 | 44% |
| L2-slim v2 (old CLAUDE 12.6K + slim obs 3K) | ~16K | 9/12 | 75% |
| **L2-slim v2 (new CLAUDE 6.8K + slim obs 3K)** | **~10K** | **9/12** | **75%** |

Less injection, better results. The 30K→10K reduction (67% smaller) improved pass rate from 44% to 75%.

### Per-Case Final Results (new CLAUDE.md + slim obs, 2 rounds)

| Case | L0 | L2 original | **Optimized** | Delta vs L0 |
|------|-----|-------------|--------------|-------------|
| 3 Rate Limit | 3/3 | 2/3 | **2/2** | even |
| 4 Price Bug | 0/3 | 2/3 | **2/2** | **+2** |
| 7 Validation | 0/3 | 3/4 | **1/2** | **+1** |
| 12 ID Validation | 0/2 | 0/2 | **2/2** | **+2** |
| 15 .env Mismatch | 1/2 | 0/2 | **0/2** | even |
| 17 PATCH Fields | 0/2 | 0/2 | **2/2** | **+2** |

## Implications for your-taste

1. **Stage 2 synthesis should extract principles with disambiguating examples.** Domain examples are raw material for deriving principles — the output should be: abstract principle + 1-2 universal examples that clarify scope/action. Domain examples should not appear in the final output.
2. **Good examples have three properties**: universal action (grep, check, enumerate), explicit scope (same directory, same endpoint, all call sites), and completion criteria ("before considering the task done"). Bad examples reference specific entities (cardNumber, Prisma, supplier) or tech stacks.
3. **Injection should be project-aware**: Domain Reasoning section only injects when the project domain matches. For unmatched projects, only abstract Reasoning Checkpoints inject.
4. **Checkpoint wording matters**: imperative > suggestive. Include explicit completion criteria.
5. **Budget**: ~3K chars of well-crafted checkpoints is the sweet spot. Beyond that, returns are negative.
6. **CLAUDE.md should contain identity/preferences, not reasoning patterns.** Reasoning enhancement belongs in your-taste rules where it can evolve. CLAUDE.md duplication wastes context budget.
