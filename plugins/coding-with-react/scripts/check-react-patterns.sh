#!/usr/bin/env bash
#
# check-react-patterns.sh
# Detect common React anti-patterns in source files.
#
# Usage: ./check-react-patterns.sh [directory]

set -euo pipefail

DIR="${1:-}"
if [ -z "$DIR" ]; then
  if [ -d "src" ]; then
    DIR="src"
  else
    DIR="."
  fi
fi

if [ ! -d "$DIR" ]; then
  echo "Error: directory '$DIR' not found"
  exit 1
fi

warnings=0
errors=0
infos=0

warn() { echo "  [WARN]  $1"; warnings=$((warnings + 1)); }
error() { echo "  [ERROR] $1"; errors=$((errors + 1)); }
info() { echo "  [INFO]  $1"; infos=$((infos + 1)); }
pass() { echo "  [OK]    $1"; }

EXCLUDE="--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=.next"
INCLUDE="--include=*.tsx --include=*.jsx --include=*.ts --include=*.js"

echo "=== React Anti-Pattern Detection ==="

echo ""
echo "--- useEffect with empty dependency analysis ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    info "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'useEffect\(\s*\(\)\s*=>' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found useEffect call(s) — review dependency arrays for correctness"
else
  pass "No useEffect calls found to review"
fi

echo ""
echo "--- useState in loops/conditions ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE '(for\s*\(|while\s*\(|if\s*\().*useState\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Hooks must not be called inside loops or conditions — move to top level"
else
  pass "No conditional hook calls detected"
fi

echo ""
echo "--- Direct DOM manipulation ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'document\.(getElementById|querySelector|querySelectorAll|getElementsBy)\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found direct DOM access(es) — use useRef instead"
else
  pass "No direct DOM manipulation found"
fi

echo ""
echo "--- Index as key in lists ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'key=\{(index|i|idx)\}' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found index-as-key usage(s) — use stable unique IDs instead"
else
  pass "No index-as-key usage found"
fi

echo ""
echo "--- Async useEffect ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'useEffect\(\s*async' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  useEffect callback must not be async — define async function inside and call it"
else
  pass "No async useEffect callbacks found"
fi

echo ""
echo "--- setState in useEffect without cleanup ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    info "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'useEffect\(.*set[A-Z]\w*\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found setState in useEffect — verify cleanup to prevent stale updates"
else
  pass "No setState-in-useEffect patterns to review"
fi

echo ""
echo "--- Inline object/array creation in JSX ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'style=\{\{' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found inline style object(s) — extract to const or use CSS modules to avoid re-renders"
else
  pass "No inline style objects found"
fi

echo ""
echo "--- Nested ternaries in JSX ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE '\?\s*.*\?\s*.*:' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found nested ternary(ies) — extract to helper or use early returns"
else
  pass "No nested ternaries found"
fi

echo ""
echo "=== Summary ==="
if [ "$warnings" -eq 0 ] && [ "$errors" -eq 0 ]; then
  pass "No major anti-patterns detected"
else
  if [ "$errors" -gt 0 ]; then
    error "Found $errors error(s) that need immediate attention"
  fi
  if [ "$warnings" -gt 0 ]; then
    warn "Found $warnings anti-pattern(s) to review"
  fi
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
