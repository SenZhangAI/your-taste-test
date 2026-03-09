#!/bin/bash
# Multi-turn A/B test runner — tests attention decay in long conversations
# Usage: ./multi-turn-runner.sh <level> <critical_case> [filler_count]
#
# Simulates a long conversation by embedding filler turn history into a single
# prompt. Tests whether CLAUDE.md instructions lose effectiveness when context
# is filled with prior work.
#
# Design: The filler history is presented as "[Previous conversation]" context,
# making it look like the AI already did 8 tasks. The actual question comes last.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/results"
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude 2>/dev/null || echo "claude")}"
TASTE_PLUGIN_DIR="${TASTE_PLUGIN_DIR:-$(cd "$PROJECT_DIR/../your-taste" 2>/dev/null && pwd || echo "")}"
CASE_TIMEOUT="${CASE_TIMEOUT:-300}"

mkdir -p "$RESULTS_DIR"

LEVEL="${1:?Usage: ./multi-turn-runner.sh <L0|L1|L2> <critical_case> [filler_count]}"
CRITICAL_CASE="${2:?Usage: ./multi-turn-runner.sh <L0|L1|L2> <critical_case> [filler_count]}"
FILLER_COUNT="${3:-8}"
RUN_ID="mt-$(date +%Y%m%d-%H%M%S)"
START_SECONDS=$SECONDS

# Simulated conversation history — realistic filler that fills context
# Each turn includes the request AND a plausible AI response summary
FILLER_TURNS='
[Turn 1]
User: Add a GET /api/health endpoint that returns { status: "ok", uptime: process.uptime() }
Assistant: Added GET /api/health to index.js. Returns JSON with status and uptime. Tested — works.

[Turn 2]
User: The 404 handler in index.js returns HTML. Change it to return JSON: { error: "Not found" }
Assistant: Updated the 404 handler in index.js from res.send() to res.status(404).json({ error: "Not found" }).

[Turn 3]
User: Add a GET /api/orders/count endpoint that returns { count: N } with the total number of orders
Assistant: Added to routes/orders.js. Uses knex count query. Returns { count: 47 } format.

[Turn 4]
User: POST /api/orders should reject requests where product_name is empty string. Return 400 with a clear message
Assistant: Added validation at the top of the POST handler. Returns { error: "product_name is required" } with 400 status.

[Turn 5]
User: Orders have created_at in the DB but its not in the API response. Add it to the GET /api/orders response
Assistant: The knex select() was explicitly listing columns and omitting created_at. Added it to the select list. Now included in both list and detail responses.

[Turn 6]
User: Add CORS middleware to index.js — allow all origins for now
Assistant: Added cors() middleware with npm cors package. app.use(cors()) before routes. All origins allowed.

[Turn 7]
User: The GET /api/products endpoint doesnt have sorting. Add ?sort=price query param (ascending by default)
Assistant: Added sort parameter handling to products route. Supports ?sort=price (ASC) and ?sort=-price (DESC). Defaults to no sort.

[Turn 8]
User: Add a simple request counter: track total requests served since startup, expose it on GET /api/health
Assistant: Added a let requestCount = 0 counter with middleware that increments on every request. Health endpoint now returns { status: "ok", uptime: 1234.5, requests: 892 }.
'

# Critical case prompts (same as test-runner.sh)
get_critical_prompt() {
  case "$1" in
    9)  echo "the order api keeps eating more memory over time, we restart it every few days. probably a database connection leak or something? can you check" ;;
    12) echo "Bug: GET /api/orders/abc returns a 500 error with a stack trace instead of a proper error. can you fix the orders endpoint to handle bad IDs?" ;;
    16) echo "A customer reported seeing a raw error stack trace when they hit a bad URL. Can you add try-catch error handling to the orders routes so errors return clean JSON instead of stack traces?" ;;
    7)  echo "Bug: a customer created an order with quantity 0 and it shows \$0.00 in their history. Please add validation to reject invalid quantities in the order creation endpoint." ;;
    2)  echo "hey we're switching soft-delete to use timestamps instead of status flags. the orders table already has a deleted_at column — can you update the order service to use whereNull('deleted_at') instead of the status check?" ;;
    *)  echo "Error: unsupported critical case $1" >&2; exit 1 ;;
  esac
}

CRITICAL_PROMPT=$(get_critical_prompt "$CRITICAL_CASE")
OUTPUT_FILE="$RESULTS_DIR/${LEVEL}-case${CRITICAL_CASE}-${RUN_ID}.md"

# Build the combined prompt
if [ "$FILLER_COUNT" -gt 0 ]; then
  COMBINED_PROMPT="Here's what we've been working on in this session so far:
${FILLER_TURNS}
---

Now for the next task:

${CRITICAL_PROMPT}"
else
  COMBINED_PROMPT="$CRITICAL_PROMPT"
fi

echo "=== Multi-turn A/B test ==="
echo "Level:    $LEVEL"
echo "Critical: Case $CRITICAL_CASE (after $FILLER_COUNT simulated turns)"
echo "Output:   $OUTPUT_FILE"
echo "Prompt:   $(echo "$COMBINED_PROMPT" | wc -c | tr -d ' ') chars"
echo ""

# Build claude command (same as test-runner.sh)
COMMON_FLAGS=(
  -p
  --no-session-persistence
  --dangerously-skip-permissions
  --permission-mode bypassPermissions
)

STANDALONE_CLAUDE_MD="${HOME}/.your-taste/standalone-CLAUDE.md"

case "$LEVEL" in
  L0)
    echo "Mode: Bare Claude"
    CMD=(
      env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT=
      "$CLAUDE_BIN"
      --setting-sources ""
      "${COMMON_FLAGS[@]}"
    )
    ;;
  L0-deep)
    echo "Mode: Bare Claude + extended thinking"
    CMD=(
      env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT=
      "$CLAUDE_BIN"
      --setting-sources ""
      --effort high
      "${COMMON_FLAGS[@]}"
    )
    ;;
  L1)
    echo "Mode: Standalone CLAUDE.md"
    if [ ! -f "$STANDALONE_CLAUDE_MD" ]; then
      echo "Error: $STANDALONE_CLAUDE_MD not found. Run: taste export"
      exit 1
    fi
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
    echo "Mode: Full plugin"
    if [ -z "$TASTE_PLUGIN_DIR" ]; then
      echo "Error: TASTE_PLUGIN_DIR not set"
      exit 1
    fi
    CMD=(
      env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT=
      "$CLAUDE_BIN"
      --plugin-dir "$TASTE_PLUGIN_DIR"
      "${COMMON_FLAGS[@]}"
    )
    ;;
  *)
    echo "Invalid level: $LEVEL"; exit 1 ;;
esac

# Reset codebase
cd "$PROJECT_DIR"
git checkout -- src/ docs/ .env.example CLAUDE.md 2>/dev/null || true
if [ "$LEVEL" = "L1" ]; then
  if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    printf '\n\n' >> "$PROJECT_DIR/CLAUDE.md"
    cat "$STANDALONE_CLAUDE_MD" >> "$PROJECT_DIR/CLAUDE.md"
  else
    cp "$STANDALONE_CLAUDE_MD" "$PROJECT_DIR/CLAUDE.md"
  fi
fi

# Run with timeout
echo "--- Running (timeout: ${CASE_TIMEOUT}s)... ---"
if [ "$CASE_TIMEOUT" -gt 0 ]; then
  "${CMD[@]}" "$COMBINED_PROMPT" > "$OUTPUT_FILE" 2>&1 &
  cmd_pid=$!
  ( sleep "$CASE_TIMEOUT" && kill "$cmd_pid" 2>/dev/null && sleep 3 && kill -9 "$cmd_pid" 2>/dev/null ) &
  watchdog_pid=$!
  trap 'kill "$cmd_pid" "$watchdog_pid" 2>/dev/null; wait "$cmd_pid" "$watchdog_pid" 2>/dev/null; exit 130' INT TERM
  wait "$cmd_pid" 2>/dev/null || true
  kill "$watchdog_pid" 2>/dev/null
  wait "$watchdog_pid" 2>/dev/null 2>&1 || true
  trap - INT TERM
else
  "${CMD[@]}" "$COMBINED_PROMPT" 2>&1 | tee "$OUTPUT_FILE" || true
fi

ELAPSED=$(( SECONDS - START_SECONDS ))

if [ ! -s "$OUTPUT_FILE" ]; then
  echo "WARNING: Empty output (possible timeout)"
  echo "[TIMEOUT] Multi-turn case $CRITICAL_CASE timed out" > "$OUTPUT_FILE"
fi

echo ""
echo "=== Saved to $OUTPUT_FILE (${ELAPSED}s) ==="

# Cleanup
git checkout -- src/ docs/ .env.example CLAUDE.md 2>/dev/null || true
[ "$LEVEL" = "L1" ] && rm -f "$PROJECT_DIR/CLAUDE.md" || true
