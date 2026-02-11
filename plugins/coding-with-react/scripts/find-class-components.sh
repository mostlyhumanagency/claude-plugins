#!/usr/bin/env bash
#
# find-class-components.sh
# Find class components that could be converted to function components.
#
# Usage: ./find-class-components.sh [directory]

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

echo "=== Class Component Detection ==="

echo ""
echo "--- extends Component ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'class\s+\w+\s+extends\s+(React\.)?Component' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found class component(s) extending Component — convert to function components with hooks"
else
  pass "No class components extending Component found"
fi

echo ""
echo "--- extends PureComponent ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'class\s+\w+\s+extends\s+(React\.)?PureComponent' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found PureComponent(s) — convert to function components (React Compiler handles memoization)"
else
  pass "No PureComponent usage found"
fi

echo ""
echo "--- componentDidMount / componentDidUpdate / componentDidCatch ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'componentDid(Mount|Update|Catch)\s*\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found lifecycle method(s) — replace with useEffect or error boundaries"
else
  pass "No lifecycle methods found"
fi

echo ""
echo "--- componentWillUnmount ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'componentWillUnmount\s*\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found componentWillUnmount — replace with useEffect cleanup"
else
  pass "No componentWillUnmount found"
fi

echo ""
echo "--- shouldComponentUpdate ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'shouldComponentUpdate\s*\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found shouldComponentUpdate — React Compiler handles this automatically"
else
  pass "No shouldComponentUpdate found"
fi

echo ""
echo "--- this.setState ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'this\.setState\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found this.setState call(s) — replace with useState hook"
else
  pass "No this.setState calls found"
fi

echo ""
echo "=== Summary ==="
if [ "$warnings" -eq 0 ]; then
  pass "No class components detected — project uses modern function components"
else
  info "Found $warnings class component pattern(s) to migrate"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
