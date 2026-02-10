#!/usr/bin/env bash
#
# check-component-usage.sh
# Find raw HTML elements that could be replaced with LiftKit components.
#
# Usage: ./check-component-usage.sh [directory]

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

declare -A REPLACEMENTS
REPLACEMENTS=(
  ["<button"]="<Button"
  ["<input"]="<TextInput"
  ["<select"]="<Select"
  ["<nav"]="<NavBar"
  ["<img"]="<Image"
)

echo "=== Raw HTML Elements Replaceable by LiftKit ==="

total_found=0
for html_tag in "<button" "<input" "<select" "<nav" "<img"; do
  liftkit="${REPLACEMENTS[$html_tag]}"
  tag_count=0

  while IFS= read -r -d '' file; do
    rel="${file#$DIR/}"
    c=$(grep -c "$html_tag" "$file" 2>/dev/null || true)
    if [ "$c" -gt 0 ]; then
      tag_count=$((tag_count + c))
      info "$html_tag> found $c time(s) in $rel — consider using LiftKit $liftkit>"
    fi
  done < <(find "$DIR" \( -name '*.tsx' -o -name '*.jsx' \) -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.next/*' -print0 2>/dev/null)

  total_found=$((total_found + tag_count))
done

if [ "$total_found" -eq 0 ]; then
  pass "No raw HTML elements found that could use LiftKit components"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
