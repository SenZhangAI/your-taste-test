#!/bin/bash
# Run all 20 cases for a given level
# Usage: ./run-all.sh <L0|L1|L2>
# Delegates to test-runner.sh for each case to avoid prompt duplication.

set -euo pipefail

LEVEL="${1:?Usage: ./run-all.sh <L0|L1|L2>}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"

echo "=== Running all cases for $LEVEL ==="
echo "Run ID: $RUN_ID"
echo ""

for CASE in $(seq 1 20); do
  echo "--- Case $CASE ---"
  ./test-runner.sh "$LEVEL" "$CASE" "$RUN_ID" > /dev/null 2>&1
  OUTPUT_FILE="results/${LEVEL}-case${CASE}-${RUN_ID}.md"
  LINES=$(wc -l < "$OUTPUT_FILE")
  echo "  Status: $? | Lines: $LINES | File: $(pwd)/$OUTPUT_FILE"
done

echo ""
echo "=== All $LEVEL cases complete ==="
echo "Results in: $(pwd)/results/"
