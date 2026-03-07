#!/bin/bash
# Run all 20 cases for a given level
# Usage: ./run-all.sh <L0|L0-deep|L1|L2|L2-deep> [max_parallel]
# max_parallel=1 for serial (default), up to 5 for parallel.
# Parallel mode copies project to temp dirs for isolation.

set -euo pipefail

LEVEL="${1:?Usage: ./run-all.sh <L0|L0-deep|L1|L2|L2-deep> [max_parallel]}"
MAX_PARALLEL="${2:-1}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/results"
mkdir -p "$RESULTS_DIR"

echo "=== Running all cases for $LEVEL (${MAX_PARALLEL}x parallel) ==="
echo "Run ID: $RUN_ID"
echo ""

TOTAL_START=$SECONDS

if [ "$MAX_PARALLEL" -le 1 ]; then
  # Serial mode — simple, no temp dirs needed
  for CASE in $(seq 1 20); do
    echo "--- Case $CASE ---"
    CASE_START=$SECONDS
    ./test-runner.sh "$LEVEL" "$CASE" "$RUN_ID" > /dev/null 2>&1 || true
    OUTPUT_FILE="$RESULTS_DIR/${LEVEL}-case${CASE}-${RUN_ID}.md"
    LINES=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo "0")
    ELAPSED=$(( SECONDS - CASE_START ))
    echo "  ${ELAPSED}s | ${LINES} lines | $OUTPUT_FILE"
  done
else
  # Parallel mode — isolate each case in a temp copy
  TMPBASE=$(mktemp -d)
  trap "rm -rf '$TMPBASE'" EXIT

  run_case() {
    local case=$1
    local workdir="$TMPBASE/case-$case"

    # Copy project (exclude heavy/output dirs)
    rsync -a \
      --exclude=node_modules \
      --exclude=results \
      --exclude=.git \
      "$PROJECT_DIR/" "$workdir/"

    # Init minimal git so L1 CLAUDE.md operations work
    (cd "$workdir" && git init -q && git add -A && git commit -q -m "init" --allow-empty) 2>/dev/null

    local case_start=$SECONDS
    "$PROJECT_DIR/test-runner.sh" "$LEVEL" "$case" "$RUN_ID" "$workdir" > /dev/null 2>&1 || true
    local elapsed=$(( SECONDS - case_start ))

    # Copy result back to main results dir
    local src="$RESULTS_DIR/${LEVEL}-case${case}-${RUN_ID}.md"
    local lines=$(wc -l < "$src" 2>/dev/null || echo "0")
    echo "  Case $case: ${elapsed}s | ${lines} lines"

    # Cleanup this case's temp dir immediately
    rm -rf "$workdir"
  }

  # Run in batches
  for batch_start in $(seq 1 "$MAX_PARALLEL" 20); do
    pids=()
    batch_cases=()
    for offset in $(seq 0 $(( MAX_PARALLEL - 1 ))); do
      CASE=$(( batch_start + offset ))
      [ "$CASE" -le 20 ] || continue
      batch_cases+=("$CASE")
      run_case "$CASE" &
      pids+=($!)
    done
    echo "--- Batch: cases ${batch_cases[*]} ---"
    for pid in "${pids[@]}"; do
      wait "$pid" || true
    done
  done
fi

TOTAL_ELAPSED=$(( SECONDS - TOTAL_START ))
echo ""
echo "=== All $LEVEL cases complete in ${TOTAL_ELAPSED}s ==="
echo "Results in: $RESULTS_DIR/"
