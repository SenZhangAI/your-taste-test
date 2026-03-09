#!/bin/bash
# Compact decay test — does L1's CLAUDE.md survive compaction?
# Usage: ./compact-test.sh <level> <critical_case> [filler_count]
#
# Flow:
#   1. Send N filler turns (real code tasks) to fill context
#   2. Send /compact to trigger compaction
#   3. Send the critical breadth-scan prompt
#   4. Capture and evaluate the response
#
# Uses --resume with captured session IDs for reliable multi-turn.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/results"
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude 2>/dev/null || echo "claude")}"
TASTE_PLUGIN_DIR="${TASTE_PLUGIN_DIR:-$(cd "$PROJECT_DIR/../your-taste" 2>/dev/null && pwd || echo "")}"
TURN_TIMEOUT="${TURN_TIMEOUT:-180}"

mkdir -p "$RESULTS_DIR"

LEVEL="${1:?Usage: ./compact-test.sh <L0|L1|L2> <critical_case> [filler_count]}"
CRITICAL_CASE="${2:?Usage: ./compact-test.sh <L0|L1|L2> <critical_case> [filler_count]}"
FILLER_COUNT="${3:-8}"
RUN_ID="compact-$(date +%Y%m%d-%H%M%S)"
START_SECONDS=$SECONDS

# Filler prompts — real code tasks that generate substantial output to fill context
FILLER_PROMPTS=(
  "Add a GET /api/health endpoint that returns { status: 'ok', uptime: process.uptime() }"
  "The 404 handler in index.js returns HTML. Change it to return JSON: { error: 'Not found' }"
  "Add a GET /api/orders/count endpoint that returns { count: N } with the total number of orders"
  "POST /api/orders should reject requests where product_name is empty string. Return 400 with a clear message"
  "Orders have created_at in the DB but it's not in the API response. Add it to the GET /api/orders response"
  "Add CORS middleware to index.js — allow all origins for now, we'll lock it down later"
  "The GET /api/products endpoint doesn't have any sorting. Add ?sort=price query param (ascending by default)"
  "Add a simple request counter: track total requests served since startup, expose it on GET /api/health as { status, uptime, requests }"
  "GET /api/orders/:id should return 404 instead of 500 when the order doesn't exist (not invalid ID, just a valid ID that has no matching row)"
  "Add a GET /api/users/count endpoint that returns { count: N } — same pattern as orders count"
)

# Critical case prompts
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

echo "=== Compact Decay Test ==="
echo "Level:    $LEVEL"
echo "Critical: Case $CRITICAL_CASE (after $FILLER_COUNT turns + /compact)"
echo "Output:   $OUTPUT_FILE"
echo ""

# Build base command
STANDALONE_CLAUDE_MD="${HOME}/.your-taste/standalone-CLAUDE.md"
ENV_PREFIX="env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT="

case "$LEVEL" in
  L0)
    echo "Mode: Bare Claude"
    LEVEL_FLAGS=(--setting-sources "")
    ;;
  L1)
    echo "Mode: Standalone CLAUDE.md"
    if [ ! -f "$STANDALONE_CLAUDE_MD" ]; then
      echo "Error: $STANDALONE_CLAUDE_MD not found. Run: taste export"; exit 1
    fi
    LEVEL_FLAGS=(--setting-sources "project")
    ;;
  L2)
    echo "Mode: Full plugin"
    if [ -z "$TASTE_PLUGIN_DIR" ]; then
      echo "Error: TASTE_PLUGIN_DIR not set"; exit 1
    fi
    LEVEL_FLAGS=(--plugin-dir "$TASTE_PLUGIN_DIR")
    ;;
  *)
    echo "Invalid level: $LEVEL"; exit 1 ;;
esac

COMMON_FLAGS=(
  --dangerously-skip-permissions
  --permission-mode bypassPermissions
)

# Reset codebase
cd "$PROJECT_DIR"
git checkout -- src/ docs/ .env.example CLAUDE.md 2>/dev/null || true

# Apply L1 CLAUDE.md
if [ "$LEVEL" = "L1" ]; then
  if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    printf '\n\n' >> "$PROJECT_DIR/CLAUDE.md"
    cat "$STANDALONE_CLAUDE_MD" >> "$PROJECT_DIR/CLAUDE.md"
  else
    cp "$STANDALONE_CLAUDE_MD" "$PROJECT_DIR/CLAUDE.md"
  fi
fi

# Helper: run a turn and return session ID
run_turn() {
  local prompt="$1"
  local session_flag="$2"  # empty for first turn, "--resume <id>" for subsequent
  local capture_output="$3"  # file path, or empty to discard

  local cmd_args=(-p "${LEVEL_FLAGS[@]}" "${COMMON_FLAGS[@]}")
  if [ -n "$session_flag" ]; then
    cmd_args+=(--resume "$session_flag")
  fi

  local out_file="${capture_output:-/dev/null}"

  # Use watchdog pattern (macOS has no timeout command)
  env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT= \
    "$CLAUDE_BIN" "${cmd_args[@]}" --output-format json "$prompt" > "$out_file" 2>/dev/null &
  local cmd_pid=$!
  ( sleep "$TURN_TIMEOUT" && kill "$cmd_pid" 2>/dev/null ) &
  local wd_pid=$!
  wait "$cmd_pid" 2>/dev/null || true
  kill "$wd_pid" 2>/dev/null
  wait "$wd_pid" 2>/dev/null || true
}

extract_session_id() {
  python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" < "$1" 2>/dev/null || echo ""
}

extract_result() {
  python3 -c "import sys,json; print(json.load(sys.stdin).get('result',''))" < "$1" 2>/dev/null || echo ""
}

TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# === Phase 1: First filler turn (creates session) ===
echo "--- Phase 1: Filler turns ---"
turn_out="$TMP_DIR/turn1.json"
prompt="${FILLER_PROMPTS[0]}"
echo "[Turn 1/$FILLER_COUNT] $prompt"

run_turn "$prompt" "" "$turn_out"
SESSION_ID=$(extract_session_id "$turn_out")

if [ -z "$SESSION_ID" ]; then
  echo "ERROR: Failed to capture session ID from first turn"
  cat "$turn_out"
  exit 1
fi
echo "  → Session: $SESSION_ID"

# === Phase 1 continued: More filler turns ===
for i in $(seq 2 "$FILLER_COUNT"); do
  idx=$(( (i - 1) % ${#FILLER_PROMPTS[@]} ))
  prompt="${FILLER_PROMPTS[$idx]}"
  echo ""
  echo "[Turn $i/$FILLER_COUNT] $prompt"

  turn_out="$TMP_DIR/turn${i}.json"
  run_turn "$prompt" "$SESSION_ID" "$turn_out"

  result_len=$(extract_result "$turn_out" | wc -c | tr -d ' ')
  echo "  → ${result_len} chars response"
done

# === Phase 2: Compact ===
echo ""
echo "--- Phase 2: /compact ---"
compact_out="$TMP_DIR/compact.json"
run_turn "/compact" "$SESSION_ID" "$compact_out"
compact_result=$(extract_result "$compact_out")
echo "  → Compact response: $(echo "$compact_result" | head -3)"

# === Phase 3: Critical turn ===
echo ""
echo "--- Phase 3: Critical case $CRITICAL_CASE ---"
echo "[Turn $((FILLER_COUNT + 2))] $CRITICAL_PROMPT"

critical_out="$TMP_DIR/critical.json"
run_turn "$CRITICAL_PROMPT" "$SESSION_ID" "$critical_out"

# Extract and save result
extract_result "$critical_out" > "$OUTPUT_FILE"

ELAPSED=$(( SECONDS - START_SECONDS ))

if [ ! -s "$OUTPUT_FILE" ]; then
  echo "WARNING: Empty output"
  echo "[EMPTY] Compact test case $CRITICAL_CASE returned empty" > "$OUTPUT_FILE"
fi

echo ""
echo "--- Result ---"
cat "$OUTPUT_FILE"
echo ""
echo "=== Saved to $OUTPUT_FILE (total: ${ELAPSED}s, $FILLER_COUNT filler + compact + critical) ==="

# Cleanup
git checkout -- src/ docs/ .env.example CLAUDE.md 2>/dev/null || true
[ "$LEVEL" = "L1" ] && rm -f "$PROJECT_DIR/CLAUDE.md" || true
