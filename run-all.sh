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
)

echo "=== Running all cases for $LEVEL ==="
echo "Run ID: $RUN_ID"
echo ""

for CASE in 1 2 3 4 5 6 7; do
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
