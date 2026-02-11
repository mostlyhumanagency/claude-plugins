#!/usr/bin/env bash
#
# find-deprecated-apis.sh
# Detect deprecated React APIs: findDOMNode, UNSAFE_ lifecycle, string refs,
# defaultProps on functions, PropTypes, legacy context.
#
# Usage: ./find-deprecated-apis.sh [directory]

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

echo "=== Deprecated React APIs ==="

echo ""
echo "--- findDOMNode ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    error "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE '(ReactDOM\.)?findDOMNode\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  findDOMNode is removed in React 19 -> use useRef"
else
  pass "No findDOMNode usage found"
fi

echo ""
echo "--- UNSAFE_ lifecycle methods ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    error "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'UNSAFE_(componentWillMount|componentWillReceiveProps|componentWillUpdate)' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  UNSAFE_ lifecycle methods are removed in React 19 -> refactor to useEffect or derived state"
else
  pass "No UNSAFE_ lifecycle methods found"
fi

echo ""
echo "--- String refs ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    error "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'ref="[^"]*"' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  String refs are removed in React 19 -> use useRef or callback refs"
else
  pass "No string refs found"
fi

echo ""
echo "--- defaultProps on function components ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE '\w+\.defaultProps\s*=' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  defaultProps on functions is deprecated in React 19 -> use ES default parameters"
else
  pass "No defaultProps assignments found"
fi

echo ""
echo "--- PropTypes ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE '(PropTypes\.\w+|\.propTypes\s*=)' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  PropTypes are removed from React 19 -> use TypeScript types"
else
  pass "No PropTypes usage found"
fi

echo ""
echo "--- Legacy Context (contextTypes / childContextTypes) ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    error "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE '(contextTypes|childContextTypes|getChildContext)\s*=' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Legacy context API is removed in React 19 -> use createContext/useContext"
else
  pass "No legacy context API usage found"
fi

echo ""
echo "--- forwardRef (simplified in React 19) ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    info "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE '(React\.)?forwardRef\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  Found $found forwardRef usage(s) — in React 19 ref is passed as a regular prop"
else
  pass "No forwardRef usage found"
fi

echo ""
echo "--- React.createFactory ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    error "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE '(React\.)?createFactory\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  createFactory is removed in React 19 -> use JSX"
else
  pass "No createFactory usage found"
fi

echo ""
echo "--- ReactDOM.render (legacy root API) ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    error "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'ReactDOM\.render\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  ReactDOM.render is removed in React 19 -> use createRoot().render()"
else
  pass "No legacy ReactDOM.render found"
fi

echo ""
echo "--- ReactDOM.hydrate (legacy hydration) ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    error "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE $INCLUDE 'ReactDOM\.hydrate\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  ReactDOM.hydrate is removed in React 19 -> use hydrateRoot()"
else
  pass "No legacy ReactDOM.hydrate found"
fi

echo ""
echo "=== Summary ==="
if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
  pass "No deprecated API usage detected"
else
  if [ "$errors" -gt 0 ]; then
    error "Found $errors removed API(s) that will break in React 19"
  fi
  if [ "$warnings" -gt 0 ]; then
    warn "Found $warnings deprecated pattern(s) to update"
  fi
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
