#!/usr/bin/env bash
#
# find-arktype-usage.sh
# Scan project for ArkType API usage and report stats.
#
# Usage: ./find-arktype-usage.sh [directory]

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

type_count=0
scope_count=0
match_count=0
module_count=0
declare_count=0
configure_count=0
arkenv_count=0
all_files=""

scan_api() {
  local pattern="$1"
  local label="$2"
  local count=0

  while IFS= read -r match; do
    if [ -n "$match" ]; then
      info "$match"
      count=$((count + 1))
      local file
      file="$(echo "$match" | cut -d: -f1)"
      all_files="$all_files
$file"
    fi
  done < <(grep -rnE $EXCLUDE "$pattern" "$DIR" 2>/dev/null || true)

  if [ "$count" -eq 0 ]; then
    pass "No $label found"
  fi

  echo "$count"
}

echo "=== type() Calls ==="
type_count=$(scan_api '[^a-zA-Z_.]type\(' "type() calls")

echo ""
echo "=== scope() Calls ==="
scope_count=$(scan_api '[^a-zA-Z_.]scope\(' "scope() calls")

echo ""
echo "=== match() Calls (from arktype) ==="
match_count=$(scan_api '[^a-zA-Z_.]match\(' "match() calls")

echo ""
echo "=== type.module() Calls ==="
module_count=$(scan_api 'type\.module\(' "type.module() calls")

echo ""
echo "=== type.declare() Calls ==="
declare_count=$(scan_api 'type\.declare\(' "type.declare() calls")

echo ""
echo "=== configure() Calls (from arktype/config) ==="
configure_count=$(scan_api "configure\(" "configure() calls")

echo ""
echo "=== arkenv() Calls ==="
arkenv_count=$(scan_api 'arkenv\(' "arkenv() calls")

echo ""
echo "=== Summary ==="

total=$((type_count + scope_count + match_count + module_count + declare_count + configure_count + arkenv_count))

if [ "$total" -eq 0 ]; then
  pass "No ArkType API usage detected in '$DIR'"
else
  unique_files=$(echo "$all_files" | sort -u | grep -c '.' || true)
  info "type()      : $type_count call(s)"
  info "scope()     : $scope_count call(s)"
  info "match()     : $match_count call(s)"
  info "type.module(): $module_count call(s)"
  info "type.declare(): $declare_count call(s)"
  info "configure() : $configure_count call(s)"
  info "arkenv()    : $arkenv_count call(s)"
  info "Total       : $total ArkType API call(s) across $unique_files file(s)"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
