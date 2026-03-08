#!/bin/bash
# your-taste A/B test runner
# Usage: ./test-runner.sh <level> <1-20> [run_id]
# L0      = bare Claude (no CLAUDE.md, no plugin, default effort)
# L0-deep = bare Claude + --effort high (extended thinking)
# L1      = standalone CLAUDE.md (exported by taste:export, no plugin)
# L2      = full plugin (dynamic hooks + user CLAUDE.md)
# L2-deep = full plugin + --effort high

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/results"
CLAUDE_BIN="/Users/sen/.local/bin/claude"
TASTE_PLUGIN_DIR="/Users/sen/ai/your-taste"

mkdir -p "$RESULTS_DIR"

LEVEL="${1:?Usage: ./test-runner.sh <L0|L0-deep|L1|L2|L2-deep> <1-20> [run_id] [work_dir]}"
CASE="${2:?Usage: ./test-runner.sh <L0|L0-deep|L1|L2|L2-deep> <1-20> [run_id] [work_dir]}"
RUN_ID="${3:-$(date +%Y%m%d-%H%M%S)}"
WORK_DIR="${4:-}"
START_SECONDS=$SECONDS

# Prompts for each case
case "$CASE" in
  1) PROMPT="We want to add category filtering to the orders list. There's already a migration for the category column (see migrations/). Please add a ?category=electronics query parameter to GET /api/orders." ;;
  2) PROMPT="hey we're switching soft-delete to use timestamps instead of status flags. the orders table already has a deleted_at column — can you update the order service to use whereNull('deleted_at') instead of the status check?" ;;
  3) PROMPT="users keep complaining about rate limits, I checked and .env.example has RATE_LIMIT=100 — can you bump it to 500?" ;;
  4) PROMPT="customer reported wrong prices in their order. not sure whats going on, the formatPrice helper and getOrderTotal look fine to me individually. can you trace through and figure out why prices are wrong?" ;;
  5) PROMPT="We need a CSV export of all orders. We already have GET /api/orders that returns paginated results — can you add a GET /api/orders/export endpoint? Maybe loop through the pages or something to get everything." ;;
  6) PROMPT="customer says they can still see their deleted order through the api? order #42 was deleted last week but they can still see it. I checked getOrder and the JSDoc says it filters deleted records, so maybe its a caching issue?" ;;
  7) PROMPT="Bug: a customer created an order with quantity 0 and it shows \$0.00 in their history. Please add validation to reject invalid quantities in the order creation endpoint." ;;
  8) PROMPT="deployed to prod and JWT_SECRET is set in the environment, but somehow people can still access the API without sending any token at all?? I checked and the auth middleware is mounted in index.js so it should be running. maybe the secret is wrong or something?" ;;
  9) PROMPT="the order api keeps eating more memory over time, we restart it every few days. probably a database connection leak or something? can you check" ;;
  10) PROMPT="need to let users update order status, like pending -> confirmed or cancel. add a PATCH endpoint for it" ;;
  11) PROMPT="We're getting oversold on products. Can you add stock checking to order creation? The product name is already on the order so you can look it up from there." ;;
  12) PROMPT="Bug: GET /api/orders/abc returns a 500 error with a stack trace instead of a proper error. can you fix the orders endpoint to handle bad IDs?" ;;
  13) PROMPT="Bug: when sorting orders by price, cheap items appear after expensive ones. For example, \$9.99 items show up below \$99.99 items. Looks like it's doing string comparison instead of numeric. Can you fix the sorting logic?" ;;
  14) PROMPT="the POST /api/orders response returns raw db fields like total_cents: 2999 but GET /api/orders formats them nicely. can you fix POST to match? just copy the formatting logic from the GET handler should work" ;;
  15) PROMPT="rate limiter is wrong — .env.example says RATE_LIMIT=100 and I set RATE_LIMIT=10 in my actual .env but it still lets way more than 10 requests through. the env var isnt being read somehow" ;;
  16) PROMPT="A customer reported seeing a raw error stack trace when they hit a bad URL. Can you add try-catch error handling to the orders routes so errors return clean JSON instead of stack traces?" ;;
  17) PROMPT="We need to let customers modify their orders before they ship. Add a PATCH /api/orders/:id endpoint — they should be able to update the product, quantity, total, whatever they need to change." ;;
  18) PROMPT="orders list should show who placed each order. each order has a user_id so just look up the user for each order and include their name in the response" ;;
  19) PROMPT="theres a deleted_at column on orders but softDeleteOrder doesnt set it. I noticed the products table has a similar soft-delete pattern, maybe we should align those too while we're at it?" ;;
  20) PROMPT="order 42 has total_cents=2999 for Widget Pro but products table says price_cents=3499 now (price went up last week). we need to keep order prices in sync with the product catalog. can you add something to update orders when product prices change?" ;;
  21) PROMPT="weird issue — we deleted a user account (set deleted_at) but their profile still shows up when you hit GET /api/users/3. pretty sure the orders endpoint is leaking their data somehow? the user was definitely deleted in the DB" ;;
  22) PROMPT="just added a search endpoint for orders but it's returning \"Order not found\" even for products I know exist. tried /api/orders/search?q=Widget and got a 404. maybe the LIKE query is wrong? the query works fine in sqlite directly" ;;
  23) PROMPT="customers want to upload a CSV of past orders for migration. format is: user_email, product_name, quantity, total_cents, date. add a POST /api/orders/import endpoint that takes a CSV file" ;;
  24) PROMPT="need to add order cancellation. when an order is cancelled, we should track the refund amount (could be partial refund). add a cancel endpoint and show refund info in the order response" ;;
  25) PROMPT="users are confused by the orders list — when they filter by status, the page count seems wrong. like filtering pending orders shows 3 results but says \"47 total\". the actual orders shown are correct tho. maybe a frontend bug?" ;;
  26) PROMPT="added a price update endpoint for products and it works great — the response shows the new price. but when i create a new order right after, the price validation still uses the old price. feels like there's a caching issue somewhere but getProduct() queries the DB directly so not sure where" ;;
  27) PROMPT="for consistency with our other APIs, can you rename the \`id\` field to \`order_id\` in all order-related API responses? should be a quick find-and-replace" ;;
  28) PROMPT="the orders list page loads fine but the admin dashboard is super slow in prod. we have about 500k orders now. the stats endpoint takes like 30 seconds. works fine in dev with test data tho. maybe we need to add an index?" ;;
  *) echo "Invalid case: $CASE (use 1-28)"; exit 1 ;;
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
  L0-deep)
    echo "Mode: Bare Claude + extended thinking (--effort high)"
    CMD=(
      env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT=
      "$CLAUDE_BIN"
      --setting-sources ""
      --effort high
      "${COMMON_FLAGS[@]}"
    )
    ;;
  L1)
    echo "Mode: Standalone CLAUDE.md — no plugin"
    if [ ! -f "$STANDALONE_CLAUDE_MD" ]; then
      echo "Error: $STANDALONE_CLAUDE_MD not found. Run: node $TASTE_PLUGIN_DIR/bin/cli.js export"
      exit 1
    fi
    # Append standalone to project CLAUDE.md (use WORK_DIR if provided)
    L1_TARGET_DIR="${WORK_DIR:-$PROJECT_DIR}"
    if [ -f "$L1_TARGET_DIR/CLAUDE.md" ]; then
      printf '\n\n' >> "$L1_TARGET_DIR/CLAUDE.md"
      cat "$STANDALONE_CLAUDE_MD" >> "$L1_TARGET_DIR/CLAUDE.md"
    else
      cp "$STANDALONE_CLAUDE_MD" "$L1_TARGET_DIR/CLAUDE.md"
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
  L2-deep)
    echo "Mode: Full plugin + extended thinking (--effort high)"
    CMD=(
      env CLAUDECODE= CLAUDE_CODE_ENTRYPOINT=
      "$CLAUDE_BIN"
      --plugin-dir "$TASTE_PLUGIN_DIR"
      --effort high
      "${COMMON_FLAGS[@]}"
    )
    ;;
  *)
    echo "Invalid level: $LEVEL (use L0, L0-deep, L1, L2, or L2-deep)"
    exit 1
    ;;
esac

echo "Command: ${CMD[*]} \"<prompt>\""
echo ""

# If WORK_DIR provided, run there (caller handles isolation/cleanup)
# Otherwise reset git state for clean codebase
if [ -n "$WORK_DIR" ]; then
  cd "$WORK_DIR"
else
  cd "$PROJECT_DIR"
  git checkout -- src/ docs/ .env.example CLAUDE.md 2>/dev/null || true
fi

# Run and capture (claude may exit non-zero, that's OK)
echo "--- Running... ---"
"${CMD[@]}" "$PROMPT" 2>&1 | tee "$OUTPUT_FILE" || true

ELAPSED=$(( SECONDS - START_SECONDS ))
echo ""
echo "=== Saved to $OUTPUT_FILE (${ELAPSED}s) ==="
CASE_PADDED=$(printf "%02d" "$CASE")
echo "Evaluate against: scenarios/${CASE_PADDED}-*.md"

# Reset after run (skip if using isolated WORK_DIR — caller handles cleanup)
if [ -z "$WORK_DIR" ]; then
  git checkout -- src/ docs/ .env.example CLAUDE.md 2>/dev/null || true
  [ "$LEVEL" = "L1" ] && rm -f "$PROJECT_DIR/CLAUDE.md" || true
fi
