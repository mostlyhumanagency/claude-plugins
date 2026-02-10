#!/usr/bin/env bash
#
# check-package-json.sh
# Validate package.json against best practices.
#
# Usage: ./check-package-json.sh [path-to-package.json]

set -euo pipefail

PKG="${1:-package.json}"

if [ ! -f "$PKG" ]; then
  echo "Error: $PKG not found"
  exit 1
fi

warnings=0
errors=0
infos=0

warn() { echo "  [WARN]  $1"; warnings=$((warnings + 1)); }
error() { echo "  [ERROR] $1"; errors=$((errors + 1)); }
info() { echo "  [INFO]  $1"; infos=$((infos + 1)); }
pass() { echo "  [OK]    $1"; }

# Parse package.json once
PKG_DATA=$(node -e "
  const p = require('./$PKG');
  console.log(JSON.stringify({
    name: p.name || '',
    version: p.version || '',
    description: p.description || '',
    license: p.license || '',
    engines: p.engines ? JSON.stringify(p.engines) : '',
    type: p.type || '',
    main: p.main || '',
    exports: p.exports ? 'yes' : '',
    files: p.files ? 'yes' : '',
    private: p.private || false,
    testScript: (p.scripts && p.scripts.test) || '',
  }));
" 2>/dev/null || echo '{}')

get_field() {
  echo "$PKG_DATA" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d)['$1']||'')}catch(e){console.log('')}})"
}

NAME=$(get_field name)
VERSION=$(get_field version)
DESCRIPTION=$(get_field description)
LICENSE=$(get_field license)
ENGINES=$(get_field engines)
TYPE=$(get_field type)
MAIN=$(get_field main)
EXPORTS=$(get_field exports)
FILES=$(get_field files)
PRIVATE=$(get_field private)
TEST_SCRIPT=$(get_field testScript)

echo "=== Required Fields ==="

if [ -n "$NAME" ]; then
  pass "name: $NAME"
else
  error "Missing required field: name"
fi

if [ -n "$VERSION" ]; then
  pass "version: $VERSION"
else
  error "Missing required field: version"
fi

echo ""
echo "=== Recommended Fields ==="

if [ -n "$DESCRIPTION" ]; then
  pass "description is set"
else
  warn "Missing recommended field: description"
fi

if [ -n "$LICENSE" ]; then
  pass "license: $LICENSE"
else
  warn "Missing recommended field: license"
fi

if [ -n "$ENGINES" ]; then
  pass "engines is set: $ENGINES"
else
  warn "Missing recommended field: engines (specify supported Node.js version)"
fi

echo ""
echo "=== Module System ==="

if [ -n "$TYPE" ]; then
  pass "type: $TYPE"
else
  warn "Missing \"type\" field — defaults to \"commonjs\". Consider setting \"type\": \"module\" for ESM"
fi

echo ""
echo "=== Entry Points ==="

PKG_DIR=$(dirname "$PKG")

if [ -n "$MAIN" ]; then
  if [ -f "$PKG_DIR/$MAIN" ]; then
    pass "main: $MAIN (file exists)"
  else
    error "main: $MAIN (file NOT found)"
  fi
elif [ -n "$EXPORTS" ]; then
  pass "exports field is defined"
else
  warn "Neither \"main\" nor \"exports\" field is set"
fi

echo ""
echo "=== Publishing ==="

if [ "$PRIVATE" = "true" ]; then
  info "Package is private — publishing checks skipped"
else
  if [ -n "$FILES" ]; then
    pass "files field is set (controls what gets published)"
  else
    warn "Missing \"files\" field — entire directory will be published"
  fi

  if [ -z "$LICENSE" ]; then
    info "No license set on a non-private package — consider adding one or marking private"
  fi
fi

echo ""
echo "=== Scripts ==="

if [ -n "$TEST_SCRIPT" ]; then
  pass "test script is defined"
else
  warn "No \"test\" script found — consider adding one"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
