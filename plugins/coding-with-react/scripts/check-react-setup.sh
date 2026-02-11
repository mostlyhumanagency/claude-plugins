#!/usr/bin/env bash
#
# check-react-setup.sh
# Validate React project configuration: package.json, tsconfig, required deps.
#
# Usage: ./check-react-setup.sh [directory]

set -euo pipefail

DIR="${1:-}"
if [ -z "$DIR" ]; then
  DIR="."
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

echo "=== React Project Setup Check ==="

echo ""
echo "--- package.json ---"
PKG="$DIR/package.json"
if [ ! -f "$PKG" ]; then
  error "package.json not found in $DIR"
else
  pass "package.json found"

  # Check for react dependency
  if grep -qE '"react"\s*:' "$PKG" 2>/dev/null; then
    REACT_VER=$(grep -oE '"react"\s*:\s*"[^"]*"' "$PKG" | grep -oE '"[^"]*"$' | tr -d '"')
    pass "react dependency found: $REACT_VER"
  else
    error "react is not listed as a dependency"
  fi

  # Check for react-dom dependency
  if grep -qE '"react-dom"\s*:' "$PKG" 2>/dev/null; then
    RDOM_VER=$(grep -oE '"react-dom"\s*:\s*"[^"]*"' "$PKG" | grep -oE '"[^"]*"$' | tr -d '"')
    pass "react-dom dependency found: $RDOM_VER"

    # Check version mismatch
    if [ -n "${REACT_VER:-}" ] && [ "$REACT_VER" != "$RDOM_VER" ]; then
      warn "react ($REACT_VER) and react-dom ($RDOM_VER) versions do not match"
    fi
  else
    error "react-dom is not listed as a dependency"
  fi

  # Check for outdated dependencies
  if grep -qE '"react-scripts"\s*:' "$PKG" 2>/dev/null; then
    info "Using react-scripts (Create React App) — consider migrating to Vite or Next.js"
  fi

  if grep -qE '"prop-types"\s*:' "$PKG" 2>/dev/null; then
    warn "prop-types dependency found — use TypeScript types instead"
  fi

  if grep -qE '"enzyme"\s*:' "$PKG" 2>/dev/null; then
    warn "enzyme dependency found — migrate to React Testing Library"
  fi

  if grep -qE '"@testing-library/react"\s*:' "$PKG" 2>/dev/null; then
    pass "React Testing Library found"
  fi
fi

echo ""
echo "--- TypeScript Configuration ---"
TSCONFIG="$DIR/tsconfig.json"
if [ ! -f "$TSCONFIG" ]; then
  info "tsconfig.json not found — project may not use TypeScript"
else
  pass "tsconfig.json found"

  # Check jsx setting
  if grep -qE '"jsx"\s*:\s*"react-jsx"' "$TSCONFIG" 2>/dev/null; then
    pass "jsx is set to 'react-jsx' (modern transform)"
  elif grep -qE '"jsx"\s*:\s*"react"' "$TSCONFIG" 2>/dev/null; then
    warn "jsx is set to 'react' (legacy transform) — use 'react-jsx' for React 17+"
  elif grep -qE '"jsx"\s*:' "$TSCONFIG" 2>/dev/null; then
    pass "jsx setting found"
  else
    warn "No jsx setting in tsconfig.json — add \"jsx\": \"react-jsx\""
  fi

  # Check moduleResolution
  if grep -qE '"moduleResolution"\s*:\s*"node"' "$TSCONFIG" 2>/dev/null; then
    info "moduleResolution is 'node' — consider 'bundler' for modern setups"
  fi

  # Check strict mode
  if grep -qE '"strict"\s*:\s*true' "$TSCONFIG" 2>/dev/null; then
    pass "Strict mode enabled"
  else
    warn "Strict mode not enabled in tsconfig.json"
  fi
fi

echo ""
echo "--- Build Tool ---"
if [ -f "$DIR/vite.config.ts" ] || [ -f "$DIR/vite.config.js" ]; then
  pass "Vite configuration found"
elif [ -f "$DIR/next.config.js" ] || [ -f "$DIR/next.config.ts" ] || [ -f "$DIR/next.config.mjs" ]; then
  pass "Next.js configuration found"
elif [ -f "$DIR/webpack.config.js" ] || [ -f "$DIR/webpack.config.ts" ]; then
  info "Webpack configuration found — consider migrating to Vite"
else
  info "No recognized build tool configuration found"
fi

echo ""
echo "=== Summary ==="
if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
  pass "React project setup looks good"
else
  if [ "$errors" -gt 0 ]; then
    error "Found $errors error(s) that should be fixed"
  fi
  if [ "$warnings" -gt 0 ]; then
    warn "Found $warnings warning(s) to review"
  fi
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
