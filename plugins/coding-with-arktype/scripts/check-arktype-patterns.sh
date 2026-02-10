#!/usr/bin/env bash
#
# check-arktype-patterns.sh
# Detect common ArkType anti-patterns in source files.
#
# Usage: ./check-arktype-patterns.sh [directory]

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

EXCLUDE="--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build"

echo "=== type() Inside scope() Body ==="
found=0
while IFS= read -r file; do
  if [ -n "$file" ]; then
    # Look for files that use scope() and also call type() inside the scope body
    # A scope body should use bare string definitions, not type() wrappers
    in_scope=false
    line_num=0
    while IFS= read -r line; do
      line_num=$((line_num + 1))
      if echo "$line" | grep -qE 'scope\(' 2>/dev/null; then
        in_scope=true
      fi
      if [ "$in_scope" = true ]; then
        if echo "$line" | grep -qE '[^a-zA-Z_.]type\(' 2>/dev/null; then
          error "$file:$line_num: type() used inside scope() body — use bare string definitions instead"
          found=$((found + 1))
        fi
        # Crude scope-end detection: closing brace + parenthesis
        if echo "$line" | grep -qE '^\s*\}\s*\)' 2>/dev/null; then
          in_scope=false
        fi
      fi
    done < "$file"
  fi
done < <(grep -rlE $EXCLUDE 'scope\(' "$DIR" 2>/dev/null || true)

if [ "$found" -eq 0 ]; then
  pass "No type() calls inside scope() bodies"
fi

echo ""
echo "=== type()/scope() Inside Function Bodies ==="
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match — types should be defined at module level for performance (JIT compilation happens once)"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE '(function\s+\w+|=>)\s*\{' "$DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.mjs" -l 2>/dev/null | while read -r file; do
  # For each file with functions, check if type() or scope() appear inside function bodies
  awk '
    /function[[:space:]]+[a-zA-Z_]/ || /=>.*\{/ || /\)\s*\{/ {
      in_func = 1
      depth = 0
    }
    in_func {
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (c == "{") depth++
        if (c == "}") depth--
        if (depth <= 0 && c == "}") { in_func = 0; break }
      }
      if (in_func && /[^a-zA-Z_.]type\(/ || in_func && /[^a-zA-Z_.]scope\(/) {
        print FILENAME ":" NR ": " $0
      }
    }
  ' "$file"
done 2>/dev/null || true)

if [ "$found" -eq 0 ]; then
  pass "No type()/scope() calls inside function bodies"
fi

echo ""
echo "=== .assert() Without try/catch ==="
found=0
while IFS= read -r file; do
  if [ -n "$file" ]; then
    while IFS=: read -r line_num line_content; do
      if [ -n "$line_num" ]; then
        # Check surrounding context (10 lines before) for try
        start=$((line_num - 10))
        if [ "$start" -lt 1 ]; then start=1; fi
        has_try=$(sed -n "${start},${line_num}p" "$file" 2>/dev/null | grep -c 'try\s*{' || true)
        if [ "$has_try" -eq 0 ]; then
          warn "$file:$line_num: .assert() call without surrounding try/catch — unhandled throws"
          found=$((found + 1))
        fi
      fi
    done < <(grep -nE '\.assert\(' "$file" 2>/dev/null || true)
  fi
done < <(grep -rlE $EXCLUDE '\.assert\(' "$DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.mjs" 2>/dev/null || true)

if [ "$found" -eq 0 ]; then
  pass "No unguarded .assert() calls found"
fi

echo ""
echo "=== tsconfig.json: strict Mode ==="
tsconfig="$DIR/tsconfig.json"
if [ ! -f "$tsconfig" ] && [ -f "./tsconfig.json" ]; then
  tsconfig="./tsconfig.json"
fi

if [ -f "$tsconfig" ]; then
  if grep -qE '"strict"\s*:\s*true' "$tsconfig" 2>/dev/null; then
    pass "\"strict\": true is set in $tsconfig"
  else
    warn "Missing \"strict\": true in $tsconfig (required for ArkType)"
  fi
else
  warn "No tsconfig.json found — ArkType requires \"strict\": true"
fi

echo ""
echo "=== tsconfig.json: skipLibCheck ==="
if [ -f "$tsconfig" ]; then
  if grep -qE '"skipLibCheck"\s*:\s*true' "$tsconfig" 2>/dev/null; then
    pass "\"skipLibCheck\": true is set in $tsconfig"
  else
    warn "Missing \"skipLibCheck\": true in $tsconfig"
  fi
else
  warn "No tsconfig.json found — ArkType recommends \"skipLibCheck\": true"
fi

echo ""
echo "=== Large scope() Definitions ==="
found=0
while IFS= read -r file; do
  if [ -n "$file" ]; then
    # Count properties inside scope() calls — crude heuristic: count lines between scope({ and })
    awk '
      /scope\(\{/ || /scope\(/ { in_scope = 1; depth = 0; props = 0; start = NR }
      in_scope {
        for (i = 1; i <= length($0); i++) {
          c = substr($0, i, 1)
          if (c == "{") depth++
          if (c == "}") depth--
          if (depth <= 0 && c == "}") {
            if (props > 20) {
              print FILENAME ":" start ": scope() with ~" props " type definitions — consider splitting into submodules"
            }
            in_scope = 0
            break
          }
        }
        if (in_scope && /[a-zA-Z_]+\s*:/) props++
      }
    ' "$file"
  fi
done < <(grep -rlE $EXCLUDE 'scope\(' "$DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.mjs" 2>/dev/null || true) | while IFS= read -r match; do
  if [ -n "$match" ]; then
    info "$match"
    found=$((found + 1))
  fi
done

if [ "$found" -eq 0 ]; then
  pass "No overly large scope() definitions found"
fi

echo ""
echo "=== Summary ==="
if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
  pass "No ArkType anti-patterns detected"
elif [ "$errors" -eq 0 ]; then
  info "No errors, but $warnings warning(s) to review"
else
  error "$errors error(s) should be fixed"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
