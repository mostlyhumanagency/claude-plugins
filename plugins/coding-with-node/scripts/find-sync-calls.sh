#!/usr/bin/env bash
#
# find-sync-calls.sh
# Find synchronous calls that may block the event loop.
#
# Usage: ./find-sync-calls.sh [directory]

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
# Also exclude test files
EXCLUDE_TEST="--exclude=*test* --exclude=*spec* --exclude-dir=__tests__ --exclude-dir=__mocks__"

search_sync() {
  local pattern="$1"
  local label="$2"
  local count=0

  while IFS= read -r match; do
    if [ -n "$match" ]; then
      warn "$match"
      count=$((count + 1))
    fi
  done < <(grep -rnE $EXCLUDE $EXCLUDE_TEST "$pattern" "$DIR" 2>/dev/null || true)

  if [ "$count" -eq 0 ]; then
    pass "No $label found"
  fi
  return $count
}

echo "=== File System Sync Calls ==="

fs_patterns="(readFileSync|writeFileSync|mkdirSync|statSync|readdirSync|existsSync|accessSync|copyFileSync|renameSync|unlinkSync|rmSync|appendFileSync)\("
fs_count=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    fs_count=$((fs_count + 1))
  fi
done < <(grep -rnE $EXCLUDE $EXCLUDE_TEST "$fs_patterns" "$DIR" 2>/dev/null || true)

if [ "$fs_count" -eq 0 ]; then
  pass "No synchronous fs calls found"
else
  info "$fs_count synchronous fs call(s) found"
fi

echo ""
echo "=== Child Process Sync Calls ==="

cp_patterns="(execSync|spawnSync|execFileSync)\("
cp_count=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    error "$match"
    cp_count=$((cp_count + 1))
  fi
done < <(grep -rnE $EXCLUDE $EXCLUDE_TEST "$cp_patterns" "$DIR" 2>/dev/null || true)

if [ "$cp_count" -eq 0 ]; then
  pass "No synchronous child_process calls found"
else
  info "$cp_count synchronous child_process call(s) — these can block for extended periods"
fi

echo ""
echo "=== Crypto Sync Calls ==="

crypto_patterns="(pbkdf2Sync|scryptSync)\("
crypto_count=0
while IFS= read -r match; do
  if [ -n "$match" ]; then
    warn "$match"
    crypto_count=$((crypto_count + 1))
  fi
done < <(grep -rnE $EXCLUDE $EXCLUDE_TEST "$crypto_patterns" "$DIR" 2>/dev/null || true)

if [ "$crypto_count" -eq 0 ]; then
  pass "No synchronous crypto calls found"
else
  info "$crypto_count synchronous crypto call(s) — consider using async variants"
fi

echo ""
echo "=== Summary ==="

total=$((fs_count + cp_count + crypto_count))
if [ "$total" -eq 0 ]; then
  pass "No blocking synchronous calls detected (excluding test files)"
else
  info "Total: $total synchronous call(s) found"
  if [ "$cp_count" -gt 0 ]; then
    error "child_process sync calls are especially dangerous in server code"
  fi
  info "Consider replacing with async equivalents in hot code paths"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
