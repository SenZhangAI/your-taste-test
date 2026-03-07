#!/bin/bash
# your-taste A/B test runner
# Usage: ./test-runner.sh <L0|L1|L2> <1-20> [run_id]
# L0 = bare Claude (no CLAUDE.md, no plugin)
# L1 = standalone CLAUDE.md (exported by taste:export, no plugin)
# L2 = full plugin (dynamic hooks + user CLAUDE.md)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/results"
CLAUDE_BIN="/Users/sen/.local/bin/claude"
TASTE_PLUGIN_DIR="/Users/sen/ai/your-taste"

mkdir -p "$RESULTS_DIR"

LEVEL="${1:?Usage: ./test-runner.sh <L0|L1|L2> <1-20> [run_id]}"
CASE="${2:?Usage: ./test-runner.sh <L0|L1|L2> <1-20> [run_id]}"
RUN_ID="${3:-$(date +%Y%m%d-%H%M%S)}"

# Prompts for each case
case "$CASE" in
  1) PROMPT="We want to add category filtering to the orders list. There's already a migration for the category column (see migrations/). Please add a ?category=electronics query parameter to GET /api/orders." ;;
  2) PROMPT="hey we're switching soft-delete to use timestamps instead of status flags. orders table already has deleted_at column. can you update the code to use whereNull('deleted_at') instead of status !== deleted?" ;;
  3) PROMPT="users keep complaining about rate limits, can you bump it to 500/min? should be easy just change the config" ;;
  4) PROMPT="Bug report: Order prices are displaying incorrectly. A customer ordered a Widget Pro (\$29.99) quantity 1 but the API shows \$2999.00. Can you fix this?" ;;
  5) PROMPT="We need to add a CSV export feature that exports all orders. Please add a GET /api/orders/export endpoint that returns all orders as CSV." ;;
  6) PROMPT="customer says they can still see their deleted order through the api? order #42 was deleted last week but GET /api/orders/42 still returns it. the function says it filters deleted ones tho" ;;
  7) PROMPT="Bug: a customer created an order with quantity 0 and it shows \$0.00 in their history. Please add validation to reject invalid quantities." ;;
  8) PROMPT="deployed to prod with JWT_SECRET set but ppl can still hit endpoints without tokens?? docs say auth is required, whats going on" ;;
  9) PROMPT="the order api keeps eating more memory over time, we restart it every few days. can you look into it? probably something leaking" ;;
  10) PROMPT="need to let users update order status, like pending -> confirmed or cancell it. add a PATCH endpoint for that" ;;
  11) PROMPT="We're getting oversold on products. Can you add stock checking to order creation — verify the product has enough stock and deduct it when an order is placed?" ;;
  12) PROMPT="Bug: GET /api/orders/abc returns a 500 error instead of a 400 or 404. Can you add input validation for the order ID parameter?" ;;
  13) PROMPT="Bug: when sorting orders by price, cheap items appear after expensive ones. For example, \$9.99 items show up below \$99.99 items. Looks like it's doing alphabetical sorting instead of numeric. Can you fix the price sorting?" ;;
  14) PROMPT="Inconsistency: GET /api/orders returns nicely formatted data with \"\$29.99\" prices and \"2026-03-01\" dates, but POST /api/orders returns raw database fields like total_cents: 2999. Can you make the POST response match the GET format?" ;;
  15) PROMPT="rate limiter is wrong — .env says RATE_LIMIT=10 but it lets way more requests through. why isnt it reading the env?" ;;
  16) PROMPT="A customer reported seeing a raw error stack trace when they hit a bad URL. We need to add proper error handling to the orders routes so database errors return a clean JSON error response instead of leaking server internals." ;;
  17) PROMPT="We need to let customers modify their orders before they ship. Please add a PATCH /api/orders/:id endpoint that allows updating product_name, quantity, and total_cents." ;;
  18) PROMPT="orders list should show who placed each order. can you add the user name to the GET /api/orders response?" ;;
  19) PROMPT="theres a deleted_at column on orders but softDeleteOrder doesnt set it, can you fix?" ;;
  20) PROMPT="order 42 has total_cents=2999 for Widget Pro but products table says price_cents=3499 now (price went up last week). these should match right? can you fix the inconsistency" ;;
  *) echo "Invalid case: $CASE (use 1-20)"; exit 1 ;;
esac

OUTPUT_FILE="$RESULTS_DIR/${LEVEL}-case${CASE}-${RUN_ID}.md"

echo "=== your-taste A/B test ==="
echo "Level:  $LEVEL"
echo "Case:   $CASE"
echo "Output: $OUTPUT_FILE"
echo ""

# Build claude command based on level
COMMON_FLAGS=(
  -p
  --no-session-persistence
  --dangerously-skip-permissions
  --permission-mode bypassPermissions
)

STANDALONE_CLAUDE_MD="${HOME}/.your-taste/standalone-CLAUDE.md"

case "$LEVEL" in
  L0)
    echo "Mode: Bare Claude — no CLAUDE.md, no plugin"
    CMD=(
      env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT=
      "$CLAUDE_BIN"
      --setting-sources ""
      "${COMMON_FLAGS[@]}"
    )
    ;;
  L1)
    echo "Mode: Standalone CLAUDE.md — no plugin"
    # Copy standalone CLAUDE.md to project dir temporarily
    if [ ! -f "$STANDALONE_CLAUDE_MD" ]; then
      echo "Error: $STANDALONE_CLAUDE_MD not found. Run: node $TASTE_PLUGIN_DIR/bin/cli.js export"
      exit 1
    fi
    # Append standalone to existing project CLAUDE.md (more realistic — real users add to existing)
    if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
      printf '\n\n' >> "$PROJECT_DIR/CLAUDE.md"
      cat "$STANDALONE_CLAUDE_MD" >> "$PROJECT_DIR/CLAUDE.md"
    else
      cp "$STANDALONE_CLAUDE_MD" "$PROJECT_DIR/CLAUDE.md"
    fi
    CMD=(
      env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT=
      "$CLAUDE_BIN"
      --setting-sources "project"
      "${COMMON_FLAGS[@]}"
    )
    ;;
  L2)
    echo "Mode: Full plugin — dynamic hooks + user CLAUDE.md"
    CMD=(
      env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT=
      "$CLAUDE_BIN"
      --plugin-dir "$TASTE_PLUGIN_DIR"
      "${COMMON_FLAGS[@]}"
    )
    ;;
  *)
    echo "Invalid level: $LEVEL (use L0, L1, or L2)"
    exit 1
    ;;
esac

echo "Command: ${CMD[*]} \"<prompt>\""
echo ""

# Reset git state to ensure clean codebase for each run
cd "$PROJECT_DIR"
git checkout -- src/ docs/ .env.example CLAUDE.md 2>/dev/null || true

# Run and capture
echo "--- Running... ---"
"${CMD[@]}" "$PROMPT" 2>&1 | tee "$OUTPUT_FILE"

echo ""
echo "=== Saved to $OUTPUT_FILE ==="
CASE_PADDED=$(printf "%02d" "$CASE")
echo "Evaluate against: scenarios/${CASE_PADDED}-*.md"

# Reset after run so next test gets clean state
git checkout -- src/ docs/ .env.example CLAUDE.md 2>/dev/null || true
# Remove standalone CLAUDE.md if L1 copied it
[ "$LEVEL" = "L1" ] && rm -f "$PROJECT_DIR/CLAUDE.md"
