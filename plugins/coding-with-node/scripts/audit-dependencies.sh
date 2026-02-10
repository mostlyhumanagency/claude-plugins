#!/usr/bin/env bash
#
# audit-dependencies.sh
# Quick dependency health check for Node.js projects.
#
# Usage: ./audit-dependencies.sh [directory]

set -euo pipefail

DIR="${1:-.}"

if [ ! -d "$DIR" ]; then
  echo "Error: directory '$DIR' not found"
  exit 1
fi

if [ ! -f "$DIR/package.json" ]; then
  echo "Error: no package.json found in '$DIR'"
  exit 1
fi

warnings=0
errors=0
infos=0

warn() { echo "  [WARN]  $1"; warnings=$((warnings + 1)); }
error() { echo "  [ERROR] $1"; errors=$((errors + 1)); }
info() { echo "  [INFO]  $1"; infos=$((infos + 1)); }
pass() { echo "  [OK]    $1"; }

# Determine package manager
PM="npm"
if [ -f "$DIR/pnpm-lock.yaml" ]; then
  if command -v pnpm &>/dev/null; then
    PM="pnpm"
  fi
fi
info "Using package manager: $PM"

echo "=== Vulnerabilities ==="

audit_output=$( (cd "$DIR" && $PM audit --json 2>/dev/null) || true)

if [ -n "$audit_output" ]; then
  if [ "$PM" = "npm" ]; then
    for severity in low moderate high critical; do
      count=$(echo "$audit_output" | node -e "
        let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
          try{const j=JSON.parse(d);console.log((j.metadata&&j.metadata.vulnerabilities&&j.metadata.vulnerabilities['$severity'])||0)}
          catch(e){console.log(0)}
        })" 2>/dev/null || echo "0")
      if [ "$count" -gt 0 ]; then
        if [ "$severity" = "critical" ] || [ "$severity" = "high" ]; then
          error "$count $severity vulnerability(ies)"
        else
          warn "$count $severity vulnerability(ies)"
        fi
      else
        pass "No $severity vulnerabilities"
      fi
    done
  else
    # pnpm audit output
    info "pnpm audit completed (check output above for details)"
  fi
else
  info "Could not run audit (node_modules may not be installed)"
fi

echo ""
echo "=== Outdated Packages ==="

outdated_output=$( (cd "$DIR" && $PM outdated --json 2>/dev/null) || true)

if [ -n "$outdated_output" ] && [ "$outdated_output" != "{}" ]; then
  major=0
  minor=0
  patch=0

  counts=$(echo "$outdated_output" | node -e "
    let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
      try{
        const j=JSON.parse(d);
        let major=0,minor=0,patch=0;
        for(const [name,info] of Object.entries(j)){
          const current=(info.current||'0.0.0').split('.');
          const latest=(info.latest||'0.0.0').split('.');
          if(current[0]!==latest[0])major++;
          else if(current[1]!==latest[1])minor++;
          else patch++;
        }
        console.log(major+' '+minor+' '+patch);
      }catch(e){console.log('0 0 0')}
    })" 2>/dev/null || echo "0 0 0")

  major=$(echo "$counts" | cut -d' ' -f1)
  minor=$(echo "$counts" | cut -d' ' -f2)
  patch=$(echo "$counts" | cut -d' ' -f3)

  [ "$major" -gt 0 ] && warn "$major package(s) with major updates available"
  [ "$minor" -gt 0 ] && info "$minor package(s) with minor updates available"
  [ "$patch" -gt 0 ] && info "$patch package(s) with patch updates available"
  [ "$major" -eq 0 ] && [ "$minor" -eq 0 ] && [ "$patch" -eq 0 ] && pass "All packages up to date"
else
  pass "All packages up to date (or node_modules not installed)"
fi

echo ""
echo "=== Project Size ==="

if [ -d "$DIR/node_modules" ]; then
  nm_size=$(du -sh "$DIR/node_modules" 2>/dev/null | cut -f1)
  info "node_modules size: $nm_size"
else
  info "node_modules not installed"
fi

if [ -f "$DIR/package-lock.json" ]; then
  pass "package-lock.json exists"
elif [ -f "$DIR/pnpm-lock.yaml" ]; then
  pass "pnpm-lock.yaml exists"
elif [ -f "$DIR/yarn.lock" ]; then
  pass "yarn.lock exists"
else
  warn "No lockfile found (package-lock.json, pnpm-lock.yaml, or yarn.lock)"
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
