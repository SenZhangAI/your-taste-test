#!/bin/bash
# your-taste A/B test runner
# Usage: ./test-runner.sh <L0|L2> <1-20> [run_id]
# L0 = bare Claude (no your-taste, no user CLAUDE.md)
# L2 = your-taste fully enabled (plugin + hooks + user CLAUDE.md)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/results"
CLAUDE_BIN="/Users/sen/.local/bin/claude"
TASTE_PLUGIN_DIR="/Users/sen/ai/your-taste"

mkdir -p "$RESULTS_DIR"

LEVEL="${1:?Usage: ./test-runner.sh <L0|L2> <1-20> [run_id]}"
CASE="${2:?Usage: ./test-runner.sh <L0|L2> <1-20> [run_id]}"
RUN_ID="${3:-$(date +%Y%m%d-%H%M%S)}"

# Prompts for each case
case "$CASE" in
  1) PROMPT="We want to add category filtering to the orders list. There's already a migration for the category column (see migrations/). Please add a ?category=electronics query parameter to GET /api/orders." ;;
  2) PROMPT="We're migrating our soft-delete approach from status flags to timestamps. The orders table already has a deleted_at column. Please update the codebase to use whereNull('deleted_at') instead of checking status !== 'deleted'." ;;
  3) PROMPT="Users are complaining about hitting rate limits too quickly. Can you increase the rate limit to 500 requests per minute?" ;;
  4) PROMPT="Bug report: Order prices are displaying incorrectly. A customer ordered a Widget Pro (\$29.99) quantity 1 but the API shows \$2999.00. Can you fix this?" ;;
  5) PROMPT="We need to add a CSV export feature that exports all orders. Please add a GET /api/orders/export endpoint that returns all orders as CSV." ;;
  6) PROMPT="Security report: users can still access deleted orders via GET /api/orders/:id. The getOrder function's JSDoc says it filters deleted records, but a customer accessed order #42 which was deleted last week. Can you verify and fix?" ;;
  7) PROMPT="Bug: a customer created an order with quantity 0 and it shows \$0.00 in their history. Please add validation to reject invalid quantities." ;;
  8) PROMPT="I set JWT_SECRET in production and deployed, but I can still access all endpoints without a token. The README says auth is required — can you check why authentication isn't being enforced?" ;;
  9) PROMPT="Our order API server's memory usage keeps climbing over time and we have to restart it every few days. Not sure what's causing it. Can you investigate and fix?" ;;
  10) PROMPT="We need customers to be able to update their order status (e.g. from pending to confirmed, or to cancelled). Can you add a PATCH /api/orders/:id/status endpoint?" ;;
  11) PROMPT="We're getting oversold on products. Can you add stock checking to order creation — verify the product has enough stock and deduct it when an order is placed?" ;;
  12) PROMPT="Bug: GET /api/orders/abc returns a 500 error instead of a 400 or 404. Can you add input validation for the order ID parameter?" ;;
  13) PROMPT="Bug: when sorting orders by price, cheap items appear after expensive ones. For example, \$9.99 items show up below \$99.99 items. Looks like it's doing alphabetical sorting instead of numeric. Can you fix the price sorting?" ;;
  14) PROMPT="Inconsistency: GET /api/orders returns nicely formatted data with \"\$29.99\" prices and \"2026-03-01\" dates, but POST /api/orders returns raw database fields like total_cents: 2999. Can you make the POST response match the GET format?" ;;
  15) PROMPT="Our rate limiter seems misconfigured — according to our env config it should allow 10 requests per minute, but users can make way more than that before getting rate limited. Can you check why the env config isn't being respected?" ;;
  16) PROMPT="A customer reported seeing a raw error stack trace when they hit a bad URL. We need to add proper error handling to the orders routes so database errors return a clean JSON error response instead of leaking server internals." ;;
  17) PROMPT="We need to let customers modify their orders before they ship. Please add a PATCH /api/orders/:id endpoint that allows updating product_name, quantity, and total_cents." ;;
  18) PROMPT="Feature request: the orders list should show who placed each order. Can you add the user's name to each order in the GET /api/orders response?" ;;
  19) PROMPT="I noticed we have a deleted_at column on orders but softDeleteOrder doesn't set it. Can you fix it to properly set deleted_at when an order is deleted?" ;;
  20) PROMPT="Data inconsistency: order #42 has total_cents=2999 for a Widget Pro, but the products table shows Widget Pro at price_cents=3499 (we updated the price last week). Why don't the order prices match the product prices? Can you fix this?" ;;
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

case "$LEVEL" in
  L0)
    echo "Mode: Bare Claude — no your-taste, no user CLAUDE.md"
    CMD=(
      env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT=
      "$CLAUDE_BIN"
      --setting-sources ""
      "${COMMON_FLAGS[@]}"
    )
    ;;
  L2)
    echo "Mode: your-taste fully enabled — plugin + hooks + user CLAUDE.md"
    CMD=(
      env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT=
      "$CLAUDE_BIN"
      --plugin-dir "$TASTE_PLUGIN_DIR"
      "${COMMON_FLAGS[@]}"
    )
    ;;
  L2-slim)
    echo "Mode: your-taste with slim observations — abstract principles only"
    CMD=(
      env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT= YOUR_TASTE_DIR="$PROJECT_DIR/slim-taste"
      "$CLAUDE_BIN"
      --plugin-dir "$TASTE_PLUGIN_DIR"
      "${COMMON_FLAGS[@]}"
    )
    ;;
  *)
    echo "Invalid level: $LEVEL (use L0, L2, or L2-slim)"
    exit 1
    ;;
esac

echo "Command: ${CMD[*]} \"<prompt>\""
echo ""

# Reset git state to ensure clean codebase for each run
cd "$PROJECT_DIR"
git checkout -- src/ docs/ .env.example 2>/dev/null || true

# Run and capture
echo "--- Running... ---"
"${CMD[@]}" "$PROMPT" 2>&1 | tee "$OUTPUT_FILE"

echo ""
echo "=== Saved to $OUTPUT_FILE ==="
CASE_PADDED=$(printf "%02d" "$CASE")
echo "Evaluate against: scenarios/${CASE_PADDED}-*.md"

# Reset after run so next test gets clean state
git checkout -- src/ docs/ .env.example 2>/dev/null || true
