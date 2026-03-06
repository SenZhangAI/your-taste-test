#!/bin/bash
# Run all 5 cases for a given level
# Usage: ./run-all.sh <L0|L2>

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/results"
CLAUDE_BIN="/Users/sen/.local/bin/claude"
TASTE_PLUGIN_DIR="/Users/sen/ai/your-taste"
RUN_ID="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$RESULTS_DIR"

LEVEL="${1:?Usage: ./run-all.sh <L0|L2>}"

COMMON_FLAGS=(
  -p
  --no-session-persistence
  --dangerously-skip-permissions
  --permission-mode bypassPermissions
)

case "$LEVEL" in
  L0) CMD=(env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT= "$CLAUDE_BIN" --setting-sources "" "${COMMON_FLAGS[@]}") ;;
  L2) CMD=(env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT= "$CLAUDE_BIN" --plugin-dir "$TASTE_PLUGIN_DIR" "${COMMON_FLAGS[@]}") ;;
  *) echo "Invalid level: $LEVEL"; exit 1 ;;
esac

PROMPTS=(
  ""
  "We want to add category filtering to the orders list. There's already a migration for the category column (see migrations/). Please add a ?category=electronics query parameter to GET /api/orders."
  "We're migrating our soft-delete approach from status flags to timestamps. The orders table already has a deleted_at column. Please update the codebase to use whereNull('deleted_at') instead of checking status !== 'deleted'."
  "Users are complaining about hitting rate limits too quickly. Can you increase the rate limit to 500 requests per minute?"
  "Bug report: Order prices are displaying incorrectly. A customer ordered a Widget Pro (\$29.99) quantity 1 but the API shows \$2999.00. Can you fix this?"
  "We need to add a CSV export feature that exports all orders. Please add a GET /api/orders/export endpoint that returns all orders as CSV."
  "Security report: users can still access deleted orders via GET /api/orders/:id. The getOrder function's JSDoc says it filters deleted records, but a customer accessed order #42 which was deleted last week. Can you verify and fix?"
  "Bug: a customer created an order with quantity 0 and it shows \$0.00 in their history. Please add validation to reject invalid quantities."
  "Hey, the JWT auth middleware seems broken — I'm getting 401s on all requests after deploying. The README says it's in src/middleware/auth.js but I can't figure out what's wrong. Can you take a look?"
  "Our order API server's memory usage keeps climbing over time and we have to restart it every few days. Not sure what's causing it. Can you investigate and fix?"
  "We need customers to be able to update their order status (e.g. from pending to confirmed, or to cancelled). Can you add a PATCH /api/orders/:id/status endpoint?"
  "We're getting oversold on products. Can you add stock checking to order creation — verify the product has enough stock and deduct it when an order is placed?"
  "Bug: GET /api/orders/abc returns a 500 error instead of a 400 or 404. Can you add input validation for the order ID parameter?"
  "Bug: when sorting orders by price, cheap items appear after expensive ones. For example, \$9.99 items show up below \$99.99 items. Looks like it's doing alphabetical sorting instead of numeric. Can you fix the price sorting?"
  "Inconsistency: GET /api/orders returns nicely formatted data with \"\$29.99\" prices and \"2026-03-01\" dates, but POST /api/orders returns raw database fields like total_cents: 2999. Can you make the POST response match the GET format?"
  "Our rate limiter seems misconfigured — according to our env config it should allow 10 requests per minute, but users can make way more than that before getting rate limited. Can you check why the env config isn't being respected?"
  "A customer reported seeing a raw error stack trace when they hit a bad URL. We need to add proper error handling to the orders routes so database errors return a clean JSON error response instead of leaking server internals."
  "We need to let customers modify their orders before they ship. Please add a PATCH /api/orders/:id endpoint that allows updating product_name, quantity, and total_cents."
  "Feature request: the orders list should show who placed each order. Can you add the user's name to each order in the GET /api/orders response?"
  "I noticed we have a deleted_at column on orders but softDeleteOrder doesn't set it. Can you fix it to properly set deleted_at when an order is deleted?"
  "Data inconsistency: order #42 has total_cents=2999 for a Widget Pro, but the products table shows Widget Pro at price_cents=3499 (we updated the price last week). Why don't the order prices match the product prices? Can you fix this?"
)

echo "=== Running all cases for $LEVEL ==="
echo "Run ID: $RUN_ID"
echo ""

for CASE in $(seq 1 20); do
  OUTPUT_FILE="$RESULTS_DIR/${LEVEL}-case${CASE}-${RUN_ID}.md"
  echo "--- Case $CASE ---"

  cd "$PROJECT_DIR"
  git checkout -- . 2>/dev/null || true

  "${CMD[@]}" "${PROMPTS[$CASE]}" > "$OUTPUT_FILE" 2>&1
  STATUS=$?

  LINES=$(wc -l < "$OUTPUT_FILE")
  echo "  Status: $STATUS | Lines: $LINES | File: $OUTPUT_FILE"
done

echo ""
echo "=== All $LEVEL cases complete ==="
echo "Results in: $RESULTS_DIR/"
