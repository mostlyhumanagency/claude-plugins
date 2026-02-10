#!/usr/bin/env bash
#
# check-liftkit-setup.sh
# Validate LiftKit project configuration and dependencies.
#
# Usage: ./check-liftkit-setup.sh [directory]

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

echo "=== Package Configuration ==="

PKG="$DIR/package.json"
if [ -f "$PKG" ]; then
  pass "package.json exists"

  HAS_LIFTKIT=$(node -e "const p=require('$PKG'); const d=p.devDependencies||{}; const dd=p.dependencies||{}; console.log(d['@chainlift/liftkit']||dd['@chainlift/liftkit']||'')" 2>/dev/null || echo "")
  if [ -n "$HAS_LIFTKIT" ]; then
    pass "@chainlift/liftkit found ($HAS_LIFTKIT)"
  else
    error "@chainlift/liftkit not found in dependencies or devDependencies"
  fi

  HAS_REACT=$(node -e "const p=require('$PKG'); const d=p.dependencies||{}; const dd=p.devDependencies||{}; console.log(d['react']||dd['react']||'')" 2>/dev/null || echo "")
  if [ -n "$HAS_REACT" ]; then
    pass "React found ($HAS_REACT)"
  else
    error "React not found in dependencies"
  fi

  HAS_NEXT=$(node -e "const p=require('$PKG'); const d=p.dependencies||{}; const dd=p.devDependencies||{}; console.log(d['next']||dd['next']||'')" 2>/dev/null || echo "")
  if [ -n "$HAS_NEXT" ]; then
    pass "Next.js found ($HAS_NEXT)"
  else
    warn "Next.js not found in dependencies"
  fi

  HAS_TAILWIND_PKG=$(node -e "const p=require('$PKG'); const d=p.dependencies||{}; const dd=p.devDependencies||{}; console.log(d['tailwindcss']||dd['tailwindcss']||'')" 2>/dev/null || echo "")
  if [ -n "$HAS_TAILWIND_PKG" ]; then
    warn "tailwindcss package found ($HAS_TAILWIND_PKG) — may conflict with LiftKit's built-in Tailwind"
  fi
else
  error "No package.json found in $DIR"
fi

echo ""
echo "=== LiftKit Config Files ==="

if [ -f "$DIR/components.json" ]; then
  pass "components.json exists"
else
  error "components.json not found — run LiftKit init to generate it"
fi

if [ -f "$DIR/tailwind.config.ts" ]; then
  pass "tailwind.config.ts exists"
elif [ -f "$DIR/tailwind.config.js" ]; then
  pass "tailwind.config.js exists"
else
  warn "No tailwind.config.ts found"
fi

echo ""
echo "=== CSS and Theme Setup ==="

CSS_IMPORT_FOUND=false
while IFS= read -r -d '' file; do
  if grep -q '@import.*@/lib/css/index\.css' "$file" 2>/dev/null; then
    CSS_IMPORT_FOUND=true
    rel="${file#$DIR/}"
    pass "LiftKit CSS import found in $rel"
    break
  fi
done < <(find "$DIR" -name '*.css' -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.next/*' -print0 2>/dev/null)

if [ "$CSS_IMPORT_FOUND" = false ]; then
  error "No CSS file imports @/lib/css/index.css — add @import url(\"@/lib/css/index.css\") to your globals.css"
fi

THEME_FOUND=false
for layout in "$DIR/app/layout.tsx" "$DIR/app/layout.jsx" "$DIR/src/app/layout.tsx" "$DIR/src/app/layout.jsx"; do
  if [ -f "$layout" ]; then
    if grep -q 'ThemeProvider' "$layout" 2>/dev/null; then
      THEME_FOUND=true
      rel="${layout#$DIR/}"
      pass "ThemeProvider found in $rel"
      break
    fi
  fi
done

if [ "$THEME_FOUND" = false ]; then
  warn "ThemeProvider not found in layout — wrap your app with <ThemeProvider> for theme support"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
