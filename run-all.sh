#!/bin/bash
# Run all 28 cases for a given level
# Usage: ./run-all.sh <L0|L0-deep|L1|L2|L2-deep> [max_parallel] [cases...]
#
# Examples:
#   ./run-all.sh L2                    # serial, all 28 cases
#   ./run-all.sh L2 4                  # 4x parallel, all 28 cases
#   ./run-all.sh L2 1 2 19 22         # serial, specific cases only (retry)
#
# Parallel mode copies project to temp dirs for isolation.
#
# Environment variables:
#   CASE_TIMEOUT - per-case timeout in seconds (default: 180)
#   CLAUDE_BIN   - path to claude binary
#   TASTE_PLUGIN_DIR - path to your-taste plugin

set -euo pipefail

LEVEL="${1:?Usage: ./run-all.sh <L0|L0-deep|L1|L2|L2-deep> [max_parallel] [cases...]}"
MAX_PARALLEL="${2:-1}"
shift 2 2>/dev/null || shift 1 2>/dev/null || true

# Remaining args = specific cases to run; default = all 28
if [ $# -gt 0 ]; then
  CASES=("$@")
else
  CASES=($(seq 1 30))
fi
TOTAL_CASES=${#CASES[@]}

RUN_ID="$(date +%Y%m%d-%H%M%S)"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/results"
mkdir -p "$RESULTS_DIR"

echo "=== Running ${TOTAL_CASES} cases for $LEVEL (${MAX_PARALLEL}x parallel) ==="
echo "Run ID: $RUN_ID"
echo "Timeout: ${CASE_TIMEOUT:-180}s per case"
echo ""

TOTAL_START=$SECONDS
FAILED_CASES=()
TIMEOUT_CASES=()

check_result() {
  local case=$1
  local output_file="$RESULTS_DIR/${LEVEL}-case${case}-${RUN_ID}.md"
  local lines=0
  if [ -f "$output_file" ]; then
    lines=$(wc -l < "$output_file" | tr -d ' ')
    # Check if output is a timeout marker
    if head -1 "$output_file" 2>/dev/null | grep -q '^\[TIMEOUT\]'; then
      TIMEOUT_CASES+=("$case")
      return 1
    elif [ "$lines" -eq 0 ]; then
      FAILED_CASES+=("$case")
      return 1
    fi
  else
    FAILED_CASES+=("$case")
    return 1
  fi
  return 0
}

if [ "$MAX_PARALLEL" -le 1 ]; then
  # Serial mode — simple, no temp dirs needed
  for CASE in "${CASES[@]}"; do
    echo "--- Case $CASE ---"
    CASE_START=$SECONDS
    "$PROJECT_DIR/test-runner.sh" "$LEVEL" "$CASE" "$RUN_ID" > /dev/null 2>&1 || true
    OUTPUT_FILE="$RESULTS_DIR/${LEVEL}-case${CASE}-${RUN_ID}.md"
    LINES=$(wc -l < "$OUTPUT_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    ELAPSED=$(( SECONDS - CASE_START ))

    if check_result "$CASE"; then
      echo "  ${ELAPSED}s | ${LINES} lines | OK"
    else
      echo "  ${ELAPSED}s | ${LINES} lines | FAILED/TIMEOUT"
    fi
  done
else
  # Parallel mode — isolate each case in a temp copy
  TMPBASE=$(mktemp -d)
  trap 'rm -rf "$TMPBASE"' EXIT

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

    local src="$RESULTS_DIR/${LEVEL}-case${case}-${RUN_ID}.md"
    local lines=$(wc -l < "$src" 2>/dev/null | tr -d ' ' || echo "0")
    echo "  Case $case: ${elapsed}s | ${lines} lines"

    # Cleanup this case's temp dir immediately
    rm -rf "$workdir"
  }

  # Run in batches
  idx=0
  while [ $idx -lt $TOTAL_CASES ]; do
    pids=()
    batch_cases=()
    for offset in $(seq 0 $(( MAX_PARALLEL - 1 ))); do
      batch_idx=$(( idx + offset ))
      [ "$batch_idx" -lt "$TOTAL_CASES" ] || continue
      CASE="${CASES[$batch_idx]}"
      batch_cases+=("$CASE")
      run_case "$CASE" &
      pids+=($!)
    done
    echo "--- Batch: cases ${batch_cases[*]} ---"
    for pid in "${pids[@]}"; do
      wait "$pid" || true
    done
    # Check results for this batch
    for CASE in "${batch_cases[@]}"; do
      check_result "$CASE" || true
    done
    idx=$(( idx + MAX_PARALLEL ))
  done
fi

TOTAL_ELAPSED=$(( SECONDS - TOTAL_START ))
echo ""
echo "=== All $LEVEL cases complete in ${TOTAL_ELAPSED}s ==="
echo "Results in: $RESULTS_DIR/"

# Summary
if [ ${#TIMEOUT_CASES[@]} -gt 0 ]; then
  echo ""
  echo "TIMED OUT (${#TIMEOUT_CASES[@]}): cases ${TIMEOUT_CASES[*]}"
  echo "Retry: ./run-all.sh $LEVEL 1 ${TIMEOUT_CASES[*]}"
fi

if [ ${#FAILED_CASES[@]} -gt 0 ]; then
  echo ""
  echo "FAILED (${#FAILED_CASES[@]}): cases ${FAILED_CASES[*]}"
  echo "Retry: ./run-all.sh $LEVEL 1 ${FAILED_CASES[*]}"
fi

if [ ${#TIMEOUT_CASES[@]} -eq 0 ] && [ ${#FAILED_CASES[@]} -eq 0 ]; then
  echo "All ${TOTAL_CASES} cases completed successfully."
fi
