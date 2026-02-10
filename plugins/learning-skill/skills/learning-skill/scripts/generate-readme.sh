#!/usr/bin/env bash
# Auto-generate README.md from plugin contents.
# Usage: generate-readme.sh <plugin-dir>
# Output: README.md content to stdout (caller redirects to file)
set -euo pipefail

# --- Helpers ---
info() { echo -e "\033[0;34mINFO:\033[0m $1" >&2; }
warn() { echo -e "\033[0;33mWARN:\033[0m $1" >&2; }
err()  { echo -e "\033[0;31mFAIL:\033[0m $1" >&2; }
ok()   { echo -e "\033[0;32m  OK:\033[0m $1" >&2; }

PLUGIN_DIR="${1:?Usage: generate-readme.sh <plugin-dir>}"

if [[ ! -d "$PLUGIN_DIR" ]]; then
  err "directory not found: $PLUGIN_DIR"
  exit 2
fi

# --- Extract Plugin Metadata ---
PLUGIN_NAME=""
PLUGIN_VERSION=""
PLUGIN_DESC=""

if [[ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]]; then
  PJSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
  PLUGIN_NAME=$(python3 -c "import json; d=json.load(open('$PJSON')); print(d.get('name',''))" 2>/dev/null || true)
  PLUGIN_VERSION=$(python3 -c "import json; d=json.load(open('$PJSON')); print(d.get('version',''))" 2>/dev/null || true)
  PLUGIN_DESC=$(python3 -c "import json; d=json.load(open('$PJSON')); print(d.get('description',''))" 2>/dev/null || true)
fi

[[ -z "$PLUGIN_NAME" ]] && PLUGIN_NAME=$(basename "$PLUGIN_DIR")
[[ -z "$PLUGIN_VERSION" ]] && PLUGIN_VERSION="0.0.0"

info "generating README for $PLUGIN_NAME v$PLUGIN_VERSION"

# --- Header ---
echo "# $PLUGIN_NAME"
echo
if [[ -n "$PLUGIN_DESC" ]]; then
  echo "$PLUGIN_DESC"
  echo
fi
echo "**Version:** $PLUGIN_VERSION"
echo

# --- Skills ---
SKILL_DIRS=()
if [[ -d "$PLUGIN_DIR/skills" ]]; then
  while IFS= read -r -d '' skill_md; do
    SKILL_DIRS+=("$(dirname "$skill_md")")
  done < <(find "$PLUGIN_DIR/skills" -name 'SKILL.md' -print0 2>/dev/null | sort -z)
fi

if [[ ${#SKILL_DIRS[@]} -gt 0 ]]; then
  echo "## Skills"
  echo
  echo "| Skill | Description |"
  echo "|---|---|"

  for skill_dir in "${SKILL_DIRS[@]}"; do
    S_NAME=$(sed -n '/^---$/,/^---$/p' "$skill_dir/SKILL.md" 2>/dev/null | grep -E '^name:' | head -1 | sed 's/^name: *//')
    [[ -z "$S_NAME" ]] && S_NAME=$(basename "$skill_dir")

    # Extract first line of description
    S_DESC=$(sed -n '/^---$/,/^---$/p' "$skill_dir/SKILL.md" 2>/dev/null | \
      sed -n '/^description:/,/^[a-z_-]*:/p' | sed '$ d' | \
      sed 's/^description: *>*//' | tr '\n' ' ' | sed 's/  */ /g' | xargs)
    # Truncate for table readability
    S_DESC="${S_DESC:0:120}"
    [[ ${#S_DESC} -ge 120 ]] && S_DESC="${S_DESC}..."

    echo "| $S_NAME | $S_DESC |"
  done
  echo
fi

# --- Agents ---
AGENT_FILES=()
if [[ -d "$PLUGIN_DIR/agents" ]]; then
  for f in "$PLUGIN_DIR/agents"/*.md; do
    [[ -f "$f" ]] && AGENT_FILES+=("$f")
  done
fi

if [[ ${#AGENT_FILES[@]} -gt 0 ]]; then
  echo "## Agents"
  echo
  echo "| Agent | Model | Description |"
  echo "|---|---|---|"

  for agent_file in "${AGENT_FILES[@]}"; do
    FM=$(sed -n '/^---$/,/^---$/p' "$agent_file" 2>/dev/null | sed '1d;$d')
    A_NAME=$(echo "$FM" | grep -E '^name:' | head -1 | sed 's/^name: *//')
    [[ -z "$A_NAME" ]] && A_NAME=$(basename "$agent_file" .md)
    A_MODEL=$(echo "$FM" | grep -E '^model:' | head -1 | sed 's/^model: *//')
    A_DESC=$(echo "$FM" | sed -n '/^description:/,/^[a-z_-]*:/p' | sed '$ d' | sed 's/^description: *>*//' | tr '\n' ' ' | xargs)
    A_DESC="${A_DESC:0:100}"

    echo "| $A_NAME | ${A_MODEL:--} | $A_DESC |"
  done
  echo
fi

# --- Commands ---
CMD_FILES=()
if [[ -d "$PLUGIN_DIR/commands" ]]; then
  for f in "$PLUGIN_DIR/commands"/*.md; do
    [[ -f "$f" ]] && CMD_FILES+=("$f")
  done
fi

if [[ ${#CMD_FILES[@]} -gt 0 ]]; then
  echo "## Commands"
  echo
  echo "| Command | Description |"
  echo "|---|---|"

  for cmd_file in "${CMD_FILES[@]}"; do
    C_NAME=$(basename "$cmd_file" .md)
    FM=$(sed -n '/^---$/,/^---$/p' "$cmd_file" 2>/dev/null | sed '1d;$d')
    C_DESC=$(echo "$FM" | sed -n '/^description:/,/^[a-z_-]*:/p' | sed '$ d' | sed 's/^description: *>*//' | tr '\n' ' ' | xargs)
    [[ -z "$C_DESC" ]] && C_DESC=$(echo "$FM" | grep -i 'description:' | head -1 | sed 's/^description: *//')
    C_DESC="${C_DESC:0:120}"

    echo "| /$C_NAME | $C_DESC |"
  done
  echo
fi

# --- Scripts ---
SCRIPT_FILES=()
if [[ -d "$PLUGIN_DIR/skills" ]]; then
  while IFS= read -r -d '' sf; do
    SCRIPT_FILES+=("$sf")
  done < <(find "$PLUGIN_DIR/skills" -path '*/scripts/*' -type f -print0 2>/dev/null | sort -z)
fi

if [[ ${#SCRIPT_FILES[@]} -gt 0 ]]; then
  echo "## Scripts"
  echo
  echo "| Script | Description |"
  echo "|---|---|"

  for script_file in "${SCRIPT_FILES[@]}"; do
    SC_NAME=$(basename "$script_file")
    # Extract description from comment header (first comment line after shebang)
    SC_DESC=$(sed -n '2,5p' "$script_file" | grep '^#' | head -1 | sed 's/^# *//')
    [[ -z "$SC_DESC" ]] && SC_DESC="-"
    SC_DESC="${SC_DESC:0:120}"

    echo "| $SC_NAME | $SC_DESC |"
  done
  echo
fi

# --- Templates ---
TMPL_FILES=()
if [[ -d "$PLUGIN_DIR/skills" ]]; then
  while IFS= read -r -d '' tf; do
    TMPL_FILES+=("$tf")
  done < <(find "$PLUGIN_DIR/skills" -path '*/templates/*' -type f -print0 2>/dev/null | sort -z)
fi

if [[ ${#TMPL_FILES[@]} -gt 0 ]]; then
  echo "## Templates"
  echo
  echo "| Template | Description |"
  echo "|---|---|"

  for tmpl_file in "${TMPL_FILES[@]}"; do
    T_NAME=$(basename "$tmpl_file")
    # Try first heading, then filename
    T_DESC=$(grep -m1 '^# ' "$tmpl_file" 2>/dev/null | sed 's/^# //' || true)
    [[ -z "$T_DESC" ]] && T_DESC="$T_NAME"
    T_DESC="${T_DESC:0:120}"

    echo "| $T_NAME | $T_DESC |"
  done
  echo
fi

# --- Installation ---
# Derive install path from directory name
DIR_NAME=$(basename "$PLUGIN_DIR")
echo "## Installation"
echo
echo '```bash'
echo "claude plugin add mostlyhumanagency/claude-plugins --path plugins/$DIR_NAME"
echo '```'

info "README generation complete"
