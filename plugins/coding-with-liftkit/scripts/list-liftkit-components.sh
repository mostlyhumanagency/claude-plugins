#!/usr/bin/env bash
#
# list-liftkit-components.sh
# List installed LiftKit components from the project's components.json.
#
# Usage: ./list-liftkit-components.sh [directory]

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

echo "=== Installed LiftKit Components ==="

COMPONENTS_FILE="$DIR/components.json"

if [ ! -f "$COMPONENTS_FILE" ]; then
  error "components.json not found in $DIR — run LiftKit init to generate it"
  echo ""
  echo "==========================================="
  echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
  exit 0
fi

COMPONENTS=$(node -e "
  const fs = require('fs');
  const data = JSON.parse(fs.readFileSync('$COMPONENTS_FILE', 'utf8'));
  const components = data.components || Object.keys(data).filter(k => k !== '\$schema' && k !== 'style' && k !== 'rsc' && k !== 'tsx' && k !== 'tailwind' && k !== 'aliases');
  if (Array.isArray(components)) {
    components.forEach(c => console.log(c));
  } else {
    Object.keys(components).forEach(c => console.log(c));
  }
" 2>/dev/null || echo "")

if [ -z "$COMPONENTS" ]; then
  info "No components found in components.json"
else
  count=0
  while IFS= read -r comp; do
    pass "$comp"
    count=$((count + 1))
  done <<< "$COMPONENTS"
  echo ""
  info "$count component(s) installed"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
