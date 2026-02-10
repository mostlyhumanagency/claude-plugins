#!/usr/bin/env bash
#
# check-node-version.sh
# Verify Node.js version consistency across config files.
#
# Usage: ./check-node-version.sh [directory]

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

declare -a sources=()
declare -a versions=()

echo "=== Detected Versions ==="

# package.json engines.node
if [ -f "$DIR/package.json" ]; then
  engines_node=$(node -e "
    const p=require('$DIR/package.json');
    console.log((p.engines&&p.engines.node)||'')
  " 2>/dev/null || echo "")
  if [ -n "$engines_node" ]; then
    info "package.json engines.node: $engines_node"
    sources+=("package.json")
    versions+=("$engines_node")
  else
    info "package.json: no engines.node field"
  fi
fi

# .nvmrc
if [ -f "$DIR/.nvmrc" ]; then
  nvmrc_ver=$(tr -d '[:space:]' < "$DIR/.nvmrc")
  info ".nvmrc: $nvmrc_ver"
  sources+=(".nvmrc")
  versions+=("$nvmrc_ver")
fi

# .node-version
if [ -f "$DIR/.node-version" ]; then
  nodever=$(tr -d '[:space:]' < "$DIR/.node-version")
  info ".node-version: $nodever"
  sources+=(".node-version")
  versions+=("$nodever")
fi

# .tool-versions (asdf)
if [ -f "$DIR/.tool-versions" ]; then
  toolver=$(grep -E '^nodejs ' "$DIR/.tool-versions" 2>/dev/null | awk '{print $2}' || true)
  if [ -n "$toolver" ]; then
    info ".tool-versions: $toolver"
    sources+=(".tool-versions")
    versions+=("$toolver")
  fi
fi

# Dockerfile
if [ -f "$DIR/Dockerfile" ]; then
  while IFS= read -r line; do
    docker_ver=$(echo "$line" | grep -oE 'node:[0-9]+[0-9.\-a-zA-Z]*' | head -1 | sed 's/node://')
    if [ -n "$docker_ver" ]; then
      info "Dockerfile: $docker_ver (FROM node:$docker_ver)"
      sources+=("Dockerfile")
      versions+=("$docker_ver")
    fi
  done < <(grep -iE '^FROM\s+node:' "$DIR/Dockerfile" 2>/dev/null || true)
fi

# GitHub Actions workflows
if [ -d "$DIR/.github/workflows" ]; then
  for wf in "$DIR"/.github/workflows/*.yml "$DIR"/.github/workflows/*.yaml; do
    [ -f "$wf" ] || continue
    wf_name=$(basename "$wf")
    while IFS= read -r ver; do
      ver=$(echo "$ver" | tr -d '[:space:]' | tr -d "'" | tr -d '"')
      if [ -n "$ver" ]; then
        info "GitHub Actions ($wf_name): $ver"
        sources+=("$wf_name")
        versions+=("$ver")
      fi
    done < <(grep -E 'node-version:' "$wf" 2>/dev/null | sed 's/.*node-version:[[:space:]]*//' || true)
  done
fi

echo ""
echo "=== Consistency Check ==="

if [ ${#versions[@]} -eq 0 ]; then
  warn "No Node.js version specifications found"
elif [ ${#versions[@]} -eq 1 ]; then
  info "Only one version source found (${sources[0]}): ${versions[0]}"
else
  # Extract major versions for comparison (strip v prefix, ranges, etc.)
  declare -a majors=()
  for v in "${versions[@]}"; do
    major=$(echo "$v" | sed 's/^[vV]//' | sed 's/^[>=<^~]*//' | cut -d'.' -f1)
    majors+=("$major")
  done

  all_match=true
  first="${majors[0]}"
  for m in "${majors[@]}"; do
    if [ "$m" != "$first" ]; then
      all_match=false
      break
    fi
  done

  if $all_match; then
    pass "All ${#versions[@]} version sources agree on major version $first"
  else
    error "Version mismatch detected across sources:"
    for i in "${!sources[@]}"; do
      error "  ${sources[$i]}: ${versions[$i]}"
    done
  fi
fi

echo ""
echo "==========================================="
echo "Results: $errors error(s), $warnings warning(s), $infos info(s)"
