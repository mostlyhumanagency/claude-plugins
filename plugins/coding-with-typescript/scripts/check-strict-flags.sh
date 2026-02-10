#!/usr/bin/env bash
#
# check-strict-flags.sh
# Runs tsc --noEmit with each strict flag individually.
# Reports error count per flag, suggests migration order.
#
# Usage: ./check-strict-flags.sh [path/to/tsconfig.json]

set -euo pipefail

TSCONFIG="${1:-tsconfig.json}"

if [ ! -f "$TSCONFIG" ]; then
  echo "Error: $TSCONFIG not found"
  exit 1
fi

# Verify tsc is available
if ! command -v tsc &>/dev/null; then
  if [ -x ./node_modules/.bin/tsc ]; then
    TSC="./node_modules/.bin/tsc"
  else
    echo "Error: tsc not found. Install TypeScript: npm install -D typescript"
    exit 1
  fi
else
  TSC="tsc"
fi

echo "Using tsconfig: $TSCONFIG"
echo "TypeScript: $($TSC --version)"
echo ""

# Strict sub-flags in recommended migration order (easiest to hardest)
FLAGS=(
  alwaysStrict
  strictBindCallApply
  strictFunctionTypes
  noImplicitThis
  noImplicitAny
  strictNullChecks
  strictPropertyInitialization
  useUnknownInCatchVariables
  noUncheckedIndexedAccess
  exactOptionalPropertyTypes
)

declare -A results
max_flag_len=0
for flag in "${FLAGS[@]}"; do
  len=${#flag}
  if (( len > max_flag_len )); then
    max_flag_len=$len
  fi
done

echo "Checking each strict flag individually..."
echo "==========================================="
echo ""

total_flags=${#FLAGS[@]}
pass_count=0

for flag in "${FLAGS[@]}"; do
  # Run tsc with --noEmit and the specific flag; count error lines
  error_count=$($TSC --noEmit -p "$TSCONFIG" --"$flag" 2>&1 | grep -c '^.*error TS' || true)

  results[$flag]=$error_count

  # Format output
  if [ "$error_count" -eq 0 ]; then
    status="PASS"
    pass_count=$((pass_count + 1))
  else
    status="$error_count errors"
  fi

  printf "  %-${max_flag_len}s  %s\n" "$flag" "$status"
done

echo ""
echo "==========================================="
echo "Summary: $pass_count/$total_flags flags pass with zero errors"
echo ""

# Suggest migration order: flags with 0 errors first, then ascending error count
echo "Suggested migration order:"
echo ""

step=1

# First: flags that already pass
for flag in "${FLAGS[@]}"; do
  if [ "${results[$flag]}" -eq 0 ]; then
    printf "  %d. %-${max_flag_len}s  (ready now)\n" "$step" "$flag"
    step=$((step + 1))
  fi
done

# Then: flags sorted by ascending error count
for flag in "${FLAGS[@]}"; do
  if [ "${results[$flag]}" -gt 0 ]; then
    printf "  %d. %-${max_flag_len}s  (%d errors to fix)\n" "$step" "$flag" "${results[$flag]}"
    step=$((step + 1))
  fi
done

echo ""
if [ "$pass_count" -eq "$total_flags" ]; then
  echo "All strict flags pass. You can safely enable \"strict\": true."
else
  echo "Tip: Enable passing flags now, then work through the rest in order."
  echo "Once all sub-flags pass, replace them with \"strict\": true."
fi
