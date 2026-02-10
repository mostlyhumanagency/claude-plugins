#!/usr/bin/env bash
#
# check-esm-compat.sh
# Scan a project for CommonJS patterns that would break in ESM mode.
#
# Usage: ./check-esm-compat.sh [directory]

set -euo pipefail

DIR="${1:-.}"

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

echo "=== Module System Config ==="

PKG="$DIR/package.json"
if [ -f "$PKG" ]; then
  TYPE_MODULE=$(node -e "const p=require('$PKG'); console.log(p.type||'')" 2>/dev/null || echo "")
  if [ "$TYPE_MODULE" = "module" ]; then
    pass "package.json has \"type\": \"module\""
  else
    warn "package.json missing \"type\": \"module\" — defaults to CJS"
  fi
else
  error "No package.json found in $DIR"
fi

echo ""
echo "=== CJS Patterns Found ==="

require_count=0
module_exports_count=0
exports_count=0
dirname_count=0
filename_count=0

while IFS= read -r -d '' file; do
  rel="${file#$DIR/}"

  c=$(grep -c 'require(' "$file" 2>/dev/null || true)
  if [ "$c" -gt 0 ]; then
    require_count=$((require_count + c))
    warn "require() found $c time(s) in $rel"
  fi

  c=$(grep -c 'module\.exports' "$file" 2>/dev/null || true)
  if [ "$c" -gt 0 ]; then
    module_exports_count=$((module_exports_count + c))
    warn "module.exports found $c time(s) in $rel"
  fi

  c=$(grep -c 'exports\.' "$file" 2>/dev/null || true)
  if [ "$c" -gt 0 ]; then
    exports_count=$((exports_count + c))
    info "exports.* found $c time(s) in $rel"
  fi

  c=$(grep -c '__dirname' "$file" 2>/dev/null || true)
  if [ "$c" -gt 0 ]; then
    dirname_count=$((dirname_count + c))
    warn "__dirname found $c time(s) in $rel"
  fi

  c=$(grep -c '__filename' "$file" 2>/dev/null || true)
  if [ "$c" -gt 0 ]; then
    filename_count=$((filename_count + c))
    warn "__filename found $c time(s) in $rel"
  fi
done < <(find "$DIR" -name '*.js' -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -print0 2>/dev/null)

total_cjs=$((require_count + module_exports_count + exports_count + dirname_count + filename_count))
if [ "$total_cjs" -eq 0 ]; then
  pass "No CJS patterns found in .js files"
fi

echo ""
echo "=== Missing Extensions ==="

missing_ext=0
while IFS= read -r -d '' file; do
  rel="${file#$DIR/}"
  while IFS= read -r line; do
    missing_ext=$((missing_ext + 1))
    warn "Missing file extension in import: $rel: $line"
  done < <(grep -nE "^[[:space:]]*(import|export).*from ['\"]\.\.?/[^'\"]+[^.][a-zA-Z]['\"]" "$file" 2>/dev/null | grep -vE "\.(js|mjs|cjs|json|css|node)['\"]" || true)
done < <(find "$DIR" -name '*.js' -o -name '*.mjs' -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -print0 2>/dev/null)

if [ "$missing_ext" -eq 0 ]; then
  pass "No missing file extensions in imports"
fi

echo ""
echo "=== Migration Effort Estimate ==="
if [ "$total_cjs" -eq 0 ] && [ "$missing_ext" -eq 0 ]; then
  info "Project appears ESM-ready or has no .js files to check"
elif [ "$total_cjs" -lt 10 ] && [ "$missing_ext" -lt 10 ]; then
  info "Low effort: ~$((total_cjs + missing_ext)) items to address"
elif [ "$total_cjs" -lt 50 ] && [ "$missing_ext" -lt 50 ]; then
  info "Medium effort: ~$((total_cjs + missing_ext)) items to address"
else
  info "High effort: ~$((total_cjs + missing_ext)) items to address — consider using a codemod"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
