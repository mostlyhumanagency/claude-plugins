#!/usr/bin/env bash
#
# check-bundle-imports.sh
# Find barrel imports and large dependency imports that hurt bundle size.
#
# Usage: ./check-bundle-imports.sh [directory]

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

echo "=== Bundle Import Analysis ==="

echo ""
echo "--- Barrel imports (index files) ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE "from ['\"]\.\.?/[^'\"]*/?index['\"]" "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found barrel import(s) from index files — import directly from source modules"
else
  pass "No barrel imports from index files found"
fi

echo ""
echo "--- Large library full imports ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE "import\s+\w+\s+from\s+['\"]lodash['\"]" "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found full lodash import(s) — use 'lodash/functionName' or lodash-es"
else
  pass "No full lodash imports found"
fi

echo ""
echo "--- Material UI full imports ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE "from ['\"]@mui/material['\"]" "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found MUI barrel import(s) — use '@mui/material/ComponentName' for better tree-shaking"
else
  pass "No MUI barrel imports found"
fi

echo ""
echo "--- moment.js usage ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE "(from ['\"]moment['\"]|require\(['\"]moment['\"])" "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found moment.js import(s) — consider date-fns or dayjs for smaller bundle"
else
  pass "No moment.js imports found"
fi

echo ""
echo "--- Wildcard re-exports ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE "export\s+\*\s+from" "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found wildcard re-export(s) — use named exports for better tree-shaking"
else
  pass "No wildcard re-exports found"
fi

echo ""
echo "--- Dynamic import opportunities ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    info "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE "from ['\"](@react-pdf|chart\.js|recharts|three|monaco-editor)['\"/]" "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found heavy library import(s) — consider lazy loading with React.lazy()"
else
  pass "No heavy library imports that need lazy loading"
fi

echo ""
echo "=== Summary ==="
if [ "$warnings" -eq 0 ]; then
  pass "No problematic import patterns detected"
else
  info "Found $warnings import pattern(s) that may increase bundle size"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
