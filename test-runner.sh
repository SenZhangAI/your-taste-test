#!/bin/bash
# your-taste A/B test runner
# Usage: ./test-runner.sh <L0|L2> <1-5> [run_id]
# L0 = bare Claude (no your-taste, no user CLAUDE.md)
# L2 = your-taste fully enabled (plugin + hooks + user CLAUDE.md)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/results"
CLAUDE_BIN="/Users/sen/.local/bin/claude"
TASTE_PLUGIN_DIR="/Users/sen/ai/your-taste"

mkdir -p "$RESULTS_DIR"

LEVEL="${1:?Usage: ./test-runner.sh <L0|L2> <1-5> [run_id]}"
CASE="${2:?Usage: ./test-runner.sh <L0|L2> <1-5> [run_id]}"
RUN_ID="${3:-$(date +%Y%m%d-%H%M%S)}"

# Prompts for each case
case "$CASE" in
  1) PROMPT="We want to add category filtering to the orders list. There's already a migration for the category column (see migrations/). Please add a ?category=electronics query parameter to GET /api/orders." ;;
  2) PROMPT="We're migrating our soft-delete approach from status flags to timestamps. The orders table already has a deleted_at column. Please update the codebase to use whereNull('deleted_at') instead of checking status !== 'deleted'." ;;
  3) PROMPT="Users are complaining about hitting rate limits too quickly. Can you increase the rate limit to 500 requests per minute?" ;;
  4) PROMPT="Bug report: Order prices are displaying incorrectly. A customer ordered a Widget Pro (\$29.99) quantity 1 but the API shows \$2999.00. Can you fix this?" ;;
  5) PROMPT="We need to add a CSV export feature that exports all orders. Please add a GET /api/orders/export endpoint that returns all orders as CSV." ;;
  *) echo "Invalid case: $CASE (use 1-5)"; exit 1 ;;
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
  *)
    echo "Invalid level: $LEVEL (use L0 or L2)"
    exit 1
    ;;
esac

echo "Command: ${CMD[*]} \"<prompt>\""
echo ""

# Reset git state to ensure clean codebase for each run
cd "$PROJECT_DIR"
git checkout -- . 2>/dev/null || true

# Run and capture
echo "--- Running... ---"
"${CMD[@]}" "$PROMPT" 2>&1 | tee "$OUTPUT_FILE"

echo ""
echo "=== Saved to $OUTPUT_FILE ==="
echo "Evaluate against: scenarios/0${CASE}-*.md"

# Reset after run so next test gets clean state
git checkout -- . 2>/dev/null || true
