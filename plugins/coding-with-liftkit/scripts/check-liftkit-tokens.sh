#!/usr/bin/env bash
#
# check-liftkit-tokens.sh
# Scan source files for hardcoded colors that should use LiftKit design tokens.
#
# Usage: ./check-liftkit-tokens.sh [directory]

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

echo "=== Hardcoded Hex Colors ==="

hex_count=0
while IFS= read -r -d '' file; do
  rel="${file#$DIR/}"
  while IFS= read -r match; do
    warn "Hex color in $rel: $match"
    hex_count=$((hex_count + 1))
  done < <(grep -nE '#[0-9a-fA-F]{3,8}\b' "$file" 2>/dev/null | grep -vE '^\s*//' || true)
done < <(find "$DIR" \( -name '*.tsx' -o -name '*.jsx' -o -name '*.css' \) -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.next/*' -print0 2>/dev/null)

if [ "$hex_count" -eq 0 ]; then
  pass "No hardcoded hex colors found"
fi

echo ""
echo "=== CSS Color Functions ==="

func_count=0
while IFS= read -r -d '' file; do
  rel="${file#$DIR/}"
  while IFS= read -r match; do
    warn "Color function in $rel: $match"
    func_count=$((func_count + 1))
  done < <(grep -nE '\b(rgb|rgba|hsl|hsla)\s*\(' "$file" 2>/dev/null | grep -vE '^\s*//' || true)
done < <(find "$DIR" \( -name '*.tsx' -o -name '*.jsx' -o -name '*.css' \) -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.next/*' -print0 2>/dev/null)

if [ "$func_count" -eq 0 ]; then
  pass "No hardcoded color functions found"
fi

echo ""
echo "=== Hardcoded Color Keywords in Style Props ==="

keyword_count=0
while IFS= read -r -d '' file; do
  rel="${file#$DIR/}"
  while IFS= read -r match; do
    warn "Hardcoded color keyword in $rel: $match"
    keyword_count=$((keyword_count + 1))
  done < <(grep -nE '(color|backgroundColor|background|borderColor)\s*[:=]\s*["\x27](red|blue|green|yellow|orange|purple|pink|white|black|gray|grey)["\x27]' "$file" 2>/dev/null || true)
done < <(find "$DIR" \( -name '*.tsx' -o -name '*.jsx' \) -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.next/*' -print0 2>/dev/null)

if [ "$keyword_count" -eq 0 ]; then
  pass "No hardcoded color keywords found in style props"
fi

total=$((hex_count + func_count + keyword_count))
if [ "$total" -gt 0 ]; then
  echo ""
  info "Use LiftKit color tokens (e.g., color='primary') instead of hardcoded values"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
