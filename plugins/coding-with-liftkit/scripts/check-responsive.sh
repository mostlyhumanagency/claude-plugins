#!/usr/bin/env bash
#
# check-responsive.sh
# Scan for responsive design anti-patterns in a LiftKit project.
#
# Usage: ./check-responsive.sh [directory]

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

echo "=== Hardcoded Pixels in Inline Styles ==="

inline_count=0
while IFS= read -r -d '' file; do
  rel="${file#$DIR/}"
  while IFS= read -r match; do
    warn "Hardcoded px in inline style in $rel: $match"
    inline_count=$((inline_count + 1))
  done < <(grep -nE '(width|height|margin|padding|top|left|right|bottom)\s*:\s*["\x27][0-9]+px' "$file" 2>/dev/null || true)
done < <(find "$DIR" \( -name '*.tsx' -o -name '*.jsx' \) -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.next/*' -print0 2>/dev/null)

if [ "$inline_count" -eq 0 ]; then
  pass "No hardcoded pixel values in inline styles"
fi

echo ""
echo "=== Hardcoded Pixels in CSS ==="

css_count=0
while IFS= read -r -d '' file; do
  rel="${file#$DIR/}"
  while IFS= read -r match; do
    warn "Hardcoded px in $rel: $match"
    css_count=$((css_count + 1))
  done < <(grep -nE '(width|height|margin|padding|max-width|min-width|max-height|min-height)\s*:\s*[2-9][0-9]+px' "$file" 2>/dev/null || true)
done < <(find "$DIR" -name '*.css' -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.next/*' -print0 2>/dev/null)

if [ "$css_count" -eq 0 ]; then
  pass "No hardcoded pixel values in CSS files"
fi

echo ""
echo "=== Grid Without autoResponsive ==="

grid_count=0
while IFS= read -r -d '' file; do
  rel="${file#$DIR/}"
  while IFS= read -r match; do
    line_num=$(echo "$match" | cut -d: -f1)
    if ! sed -n "${line_num}p" "$file" | grep -q 'autoResponsive' 2>/dev/null; then
      info "Grid without autoResponsive in $rel:$line_num — consider adding autoResponsive prop"
      grid_count=$((grid_count + 1))
    fi
  done < <(grep -n '<Grid' "$file" 2>/dev/null || true)
done < <(find "$DIR" \( -name '*.tsx' -o -name '*.jsx' \) -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.next/*' -print0 2>/dev/null)

if [ "$grid_count" -eq 0 ]; then
  pass "All Grid components use autoResponsive (or none found)"
fi

total=$((inline_count + css_count + grid_count))
if [ "$total" -gt 0 ]; then
  echo ""
  info "Use LiftKit spacing tokens and Grid autoResponsive for responsive layouts"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
