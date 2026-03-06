## Reasoning Checkpoints

- **Verify before executing.** Before calling a tool, running a command, or switching phases — confirm the current direction aligns with known information and the environment supports the operation. Don't assume paths exist, fields are valid, or tools are available.

- **Breadth-scan after completing a unit.** After finishing a fix, design change, or implementation — immediately run a grep/glob to find all sibling files and call sites with the same pattern. Fix them in the same change. This is not optional: a point-fix without breadth-scan is incomplete work. Concrete trigger: when you fix a route handler, validation rule, or error handling pattern in one file, search the entire routes/ directory (and equivalent directories) for the identical pattern before considering the task done.

- **Validate assumptions against actual state.** When about to implement based on a convention (field validity, framework type, directory naming, column existence) — confirm actual state via files, schema, or runtime checks first. Migrations may not be applied; docs may be stale; README claims may be false.

- **Treat indirect sources as hypotheses.** Conclusions from docs, comments, JSDoc, variable names, or error messages are not verified facts. Read the actual code path before acting. A function's JSDoc saying "filters deleted records" doesn't mean it does.

- **Validate hypotheses at minimum cost first.** Before expanding into broad analysis, run one cheap check (compare schema, cross-reference a second source, trace one call). Unvalidated hypotheses accumulate wasted search rounds.

- **Escalate abstraction level after fixing.** After completing a fix, ask "why did this happen?" to identify the underlying principle, not just the instance. A cents/dollars mismatch at the call site is a symptom of unclear contracts — fix at the right layer, don't change the contract to match the caller.

- **Question the premise of user reports.** When a user reports a "bug" or "inconsistency", verify whether it's actually a problem or by-design behavior before implementing a fix. Price snapshots at order time diverging from current prices is standard e-commerce, not a bug.

- **Scrutinize field editability on mutation endpoints.** Before implementing PATCH/PUT endpoints, question whether each writable field should be user-controllable. Computed values (totals, timestamps, derived prices) should not accept direct external input.

## Failure Patterns

- **Pattern**: Completing the main fix and stopping without scanning adjacent components for the same issue. **Fix**: After every fix, enumerate all sibling files/routes/fields that share the same pattern. For validation fixes: check every field in the same endpoint for similar weakness, not just the reported one. For route fixes: grep all route files for the identical vulnerability.

- **Pattern**: Changing a function's contract (return type, units, semantics) to fix a caller, instead of fixing the caller to match the contract. **Fix**: When two layers disagree, determine which layer's contract is authoritative, then fix the other layer.

- **Pattern**: Accepting user's framing ("this is a bug", "these should match") as fact without independent verification. **Fix**: Trace the actual behavior first. The "bug" may be correct behavior.
