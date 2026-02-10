#!/usr/bin/env bash
#
# check-deprecated-apis.sh
# Find deprecated Node.js API usage in source files.
#
# Usage: ./check-deprecated-apis.sh [directory]

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

check_pattern() {
  local pattern="$1"
  local description="$2"
  local replacement="$3"

  while IFS= read -r match; do
    if [ -n "$match" ]; then
      warn "$match"
      info "  $description -> use $replacement"
    fi
  done < <(grep -rnE $EXCLUDE "$pattern" "$DIR" 2>/dev/null || true)
}

echo "=== Deprecated APIs Found ==="

echo ""
echo "--- Buffer ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE 'new Buffer\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  new Buffer() is deprecated -> use Buffer.from() or Buffer.alloc()"
else
  pass "No new Buffer() usage found"
fi

echo ""
echo "--- URL ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE 'url\.parse\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  url.parse() is deprecated -> use new URL()"
else
  pass "No url.parse() usage found"
fi

echo ""
echo "--- querystring ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE 'querystring\.(parse|stringify)\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  querystring is deprecated -> use URLSearchParams"
else
  pass "No querystring usage found"
fi

echo ""
echo "--- domain ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE "(require\(['\"]domain['\"]|from ['\"]domain['\"])" "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  domain module is deprecated -> use structured error handling"
else
  pass "No domain module usage found"
fi

echo ""
echo "--- util.pump ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE 'util\.pump\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  util.pump() is deprecated -> use stream.pipeline()"
else
  pass "No util.pump() usage found"
fi

echo ""
echo "--- fs.exists ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE 'fs\.exists\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  fs.exists() is deprecated -> use fs.access() or fs.stat()"
else
  pass "No fs.exists() usage found"
fi

echo ""
echo "--- os.tmpDir ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE 'os\.tmpDir\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  os.tmpDir() is deprecated -> use os.tmpdir() (lowercase)"
else
  pass "No os.tmpDir() usage found"
fi

echo ""
echo "--- util type checks ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE 'util\.(isArray|isDate|isRegExp)\(' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  util.isArray/isDate/isRegExp deprecated -> use Array.isArray(), instanceof Date/RegExp"
else
  pass "No deprecated util type checks found"
fi

echo ""
echo "--- path._makeLong ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE 'path\._makeLong' "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  path._makeLong is deprecated -> use path.toNamespacedPath()"
else
  pass "No path._makeLong usage found"
fi

echo ""
echo "--- sys module ---"
found=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    found=$((found + 1))
  fi
done < <(grep -rnE $EXCLUDE "(require\(['\"]sys['\"]|from ['\"]sys['\"])" "$DIR" 2>/dev/null || true)
if [ "$found" -gt 0 ]; then
  info "  sys module is deprecated -> use util"
else
  pass "No sys module usage found"
fi

echo ""
echo "=== Summary ==="
if [ "$warnings" -eq 0 ]; then
  pass "No deprecated API usage detected"
else
  info "Found $warnings deprecated API usage(s) to address"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
