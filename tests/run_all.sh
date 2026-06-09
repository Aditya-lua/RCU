#!/usr/bin/env bash
# Run all Lua unit tests and report results.
set -e
cd "$(dirname "$0")"

PASS=0
FAIL=0

for test_file in test_*.lua; do
    echo "=========================================="
    echo "Running: $test_file"
    echo "=========================================="
    if lua5.4 "$test_file"; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
    fi
    echo ""
done

echo "=========================================="
echo "Summary: $PASS passed, $FAIL failed out of $((PASS + FAIL)) test suites"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
