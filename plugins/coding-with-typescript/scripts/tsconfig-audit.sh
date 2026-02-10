#!/usr/bin/env bash
#
# tsconfig-audit.sh
# Reads tsconfig.json and checks against best practices.
# Flags: missing recommended settings, conflicts, performance issues.
#
# Usage: ./tsconfig-audit.sh [path/to/tsconfig.json]

set -euo pipefail

TSCONFIG="${1:-tsconfig.json}"

if [ ! -f "$TSCONFIG" ]; then
  echo "Error: $TSCONFIG not found"
  exit 1
fi

echo "Auditing: $TSCONFIG"
echo ""

warnings=0
errors=0
infos=0

warn() {
  echo "  [WARN]  $1"
  warnings=$((warnings + 1))
}

error() {
  echo "  [ERROR] $1"
  errors=$((errors + 1))
}

info() {
  echo "  [INFO]  $1"
  infos=$((infos + 1))
}

pass() {
  echo "  [OK]    $1"
}

# Read the resolved config. Use tsc --showConfig if available, otherwise parse raw JSON.
# Strip comments and trailing commas for basic JSON parsing via python/node.
read_config_value() {
  local key="$1"
  # Try node first (most likely available in TS projects)
  if command -v node &>/dev/null; then
    node -e "
      const fs = require('fs');
      const text = fs.readFileSync('$TSCONFIG', 'utf8');
      // Strip single-line comments and trailing commas
      const clean = text.replace(/\/\/.*$/gm, '').replace(/,(\s*[}\]])/g, '\$1');
      try {
        const config = JSON.parse(clean);
        const val = config?.compilerOptions?.['$key'];
        if (val !== undefined) process.stdout.write(String(val));
      } catch {}
    " 2>/dev/null
  fi
}

echo "=== Type Safety ==="

strict=$(read_config_value "strict")
if [ "$strict" = "true" ]; then
  pass "strict: true"
else
  error "strict is not enabled. This is the foundation of type safety."
fi

noUnchecked=$(read_config_value "noUncheckedIndexedAccess")
if [ "$noUnchecked" = "true" ]; then
  pass "noUncheckedIndexedAccess: true"
else
  warn "noUncheckedIndexedAccess not enabled. Array/object index access will not return T | undefined."
fi

exactOptional=$(read_config_value "exactOptionalPropertyTypes")
if [ "$exactOptional" = "true" ]; then
  pass "exactOptionalPropertyTypes: true"
else
  info "exactOptionalPropertyTypes not enabled. Consider enabling for stricter optional handling."
fi

echo ""
echo "=== Performance ==="

skipLibCheck=$(read_config_value "skipLibCheck")
if [ "$skipLibCheck" = "true" ]; then
  pass "skipLibCheck: true"
else
  warn "skipLibCheck not enabled. Builds will type-check all .d.ts files (slower)."
fi

incremental=$(read_config_value "incremental")
composite=$(read_config_value "composite")
if [ "$incremental" = "true" ] || [ "$composite" = "true" ]; then
  pass "incremental/composite enabled"
else
  warn "Neither incremental nor composite is enabled. Every build is a full rebuild."
fi

isolatedModules=$(read_config_value "isolatedModules")
if [ "$isolatedModules" = "true" ]; then
  pass "isolatedModules: true"
else
  info "isolatedModules not enabled. Required for swc/esbuild transpilation."
fi

echo ""
echo "=== Module System ==="

module=$(read_config_value "module")
moduleRes=$(read_config_value "moduleResolution")

module_lower=$(echo "$module" | tr '[:upper:]' '[:lower:]')
moduleRes_lower=$(echo "$moduleRes" | tr '[:upper:]' '[:lower:]')

if [ -z "$module" ]; then
  warn "module not set. Should be node20, nodenext, esnext, or commonjs."
elif [[ "$module_lower" == "commonjs" ]]; then
  info "module: commonjs. Consider migrating to ESM (node20/nodenext) for modern Node.js."
elif [[ "$module_lower" =~ ^(node20|nodenext|esnext|es2022|preserve)$ ]]; then
  pass "module: $module"
else
  warn "module: $module may be outdated. Prefer node20, nodenext, esnext, or bundler."
fi

if [ -z "$moduleRes" ]; then
  # Modern TS infers moduleResolution from module, so this may be fine
  info "moduleResolution not explicitly set. TypeScript will infer it from module."
elif [[ "$moduleRes_lower" == "node" ]]; then
  warn "moduleResolution: node is the legacy setting. Use node20, nodenext, or bundler."
elif [[ "$moduleRes_lower" =~ ^(node20|nodenext|bundler)$ ]]; then
  pass "moduleResolution: $moduleRes"
fi

echo ""
echo "=== Module Settings ==="

verbatim=$(read_config_value "verbatimModuleSyntax")
if [ "$verbatim" = "true" ]; then
  pass "verbatimModuleSyntax: true"
else
  info "verbatimModuleSyntax not enabled. Enforces import type for type-only imports."
fi

moduleDetection=$(read_config_value "moduleDetection")
if [ "$moduleDetection" = "force" ]; then
  pass "moduleDetection: force"
else
  info "moduleDetection not set to force. All files will be treated as modules only if they have import/export."
fi

echo ""
echo "=== Potential Conflicts ==="

esModuleInterop=$(read_config_value "esModuleInterop")
if [ "$verbatim" = "true" ] && [ "$esModuleInterop" = "true" ]; then
  warn "esModuleInterop is unnecessary with verbatimModuleSyntax. Remove esModuleInterop."
fi

allowJs=$(read_config_value "allowJs")
checkJs=$(read_config_value "checkJs")
if [ "$checkJs" = "true" ] && [ "$allowJs" != "true" ]; then
  error "checkJs: true requires allowJs: true."
fi

target=$(read_config_value "target")
target_lower=$(echo "$target" | tr '[:upper:]' '[:lower:]')
if [[ "$target_lower" =~ ^(es5|es6|es2015|es2016|es2017)$ ]]; then
  warn "target: $target is old. Consider es2022 or es2023 for modern runtimes."
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"

if [ "$errors" -gt 0 ]; then
  echo "Fix errors first, then address warnings."
  exit 1
elif [ "$warnings" -gt 0 ]; then
  echo "No errors, but some improvements recommended."
  exit 0
else
  echo "Configuration looks good!"
  exit 0
fi
