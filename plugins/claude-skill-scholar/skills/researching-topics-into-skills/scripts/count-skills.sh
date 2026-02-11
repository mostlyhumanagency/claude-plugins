#!/usr/bin/env bash
# Plugin inventory with stats — count skills, agents, commands, and more.
# Usage: count-skills.sh <plugin-dir>
set -euo pipefail

# --- Helpers ---
info() { echo -e "\033[0;34mINFO:\033[0m $1"; }
warn() { echo -e "\033[0;33mWARN:\033[0m $1"; }
err()  { echo -e "\033[0;31mFAIL:\033[0m $1"; }
ok()   { echo -e "\033[0;32m  OK:\033[0m $1"; }

PLUGIN_DIR="${1:?Usage: count-skills.sh <plugin-dir>}"

if [[ ! -d "$PLUGIN_DIR" ]]; then
  err "directory not found: $PLUGIN_DIR"
  exit 2
fi

# --- Extract Plugin Name ---
PLUGIN_NAME=""
if [[ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]]; then
  PLUGIN_NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$PLUGIN_DIR/.claude-plugin/plugin.json" | head -1 | sed 's/.*: *"//;s/"//')
fi
[[ -z "$PLUGIN_NAME" ]] && PLUGIN_NAME=$(basename "$PLUGIN_DIR")

echo "=== Plugin Inventory: $PLUGIN_NAME ==="
echo

# --- Count Words Helper ---
count_words() {
  if [[ -f "$1" ]]; then
    wc -w < "$1" | tr -d ' '
  else
    echo "0"
  fi
}

# --- Format Number with Commas ---
fmt_num() {
  printf "%'d" "$1" 2>/dev/null || echo "$1"
}

# --- Skills ---
SKILL_DIRS=()
if [[ -d "$PLUGIN_DIR/skills" ]]; then
  while IFS= read -r -d '' skill_md; do
    SKILL_DIRS+=("$(dirname "$skill_md")")
  done < <(find "$PLUGIN_DIR/skills" -name 'SKILL.md' -print0 2>/dev/null)
fi

SKILL_COUNT=${#SKILL_DIRS[@]}
echo "Skills ($SKILL_COUNT):"

if [[ "$SKILL_COUNT" -gt 0 ]]; then
  printf "| %-30s | %15s | %4s | %10s | %7s | %8s |\n" "Name" "SKILL.md Words" "Refs" "Ref Words" "Scripts" "Examples"
  printf "|%s|%s|%s|%s|%s|%s|\n" "$(printf -- '-%.0s' {1..32})" "$(printf -- '-%.0s' {1..17})" "$(printf -- '-%.0s' {1..6})" "$(printf -- '-%.0s' {1..12})" "$(printf -- '-%.0s' {1..9})" "$(printf -- '-%.0s' {1..10})"

  for skill_dir in "${SKILL_DIRS[@]}"; do
    # Extract name from frontmatter
    S_NAME=$(sed -n '/^---$/,/^---$/p' "$skill_dir/SKILL.md" 2>/dev/null | grep -E '^name:' | head -1 | sed 's/^name: *//')
    [[ -z "$S_NAME" ]] && S_NAME=$(basename "$skill_dir")

    # SKILL.md word count
    S_WORDS=$(count_words "$skill_dir/SKILL.md")

    # Reference files
    REF_COUNT=0
    REF_WORDS=0
    if [[ -d "$skill_dir/references" ]]; then
      for ref in "$skill_dir/references"/*; do
        [[ -f "$ref" ]] || continue
        ((REF_COUNT++))
        rw=$(count_words "$ref")
        REF_WORDS=$((REF_WORDS + rw))
      done
    fi

    # Scripts
    SCRIPT_COUNT=0
    if [[ -d "$skill_dir/scripts" ]]; then
      SCRIPT_COUNT=$(find "$skill_dir/scripts" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi

    # Examples
    EXAMPLE_COUNT=0
    if [[ -d "$skill_dir/examples" ]]; then
      EXAMPLE_COUNT=$(find "$skill_dir/examples" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi

    printf "| %-30s | %15s | %4s | %10s | %7s | %8s |\n" \
      "$S_NAME" "$(fmt_num "$S_WORDS")" "$REF_COUNT" "$(fmt_num "$REF_WORDS")" "$SCRIPT_COUNT" "$EXAMPLE_COUNT"
  done
fi

echo

# --- Agents ---
AGENT_LIST=()
if [[ -d "$PLUGIN_DIR/agents" ]]; then
  for agent_file in "$PLUGIN_DIR/agents"/*.md; do
    [[ -f "$agent_file" ]] || continue
    a_name=$(sed -n '/^---$/,/^---$/p' "$agent_file" 2>/dev/null | grep -E '^name:' | head -1 | sed 's/^name: *//')
    [[ -z "$a_name" ]] && a_name=$(basename "$agent_file" .md)
    AGENT_LIST+=("$a_name")
  done
fi
echo "Agents (${#AGENT_LIST[@]}): ${AGENT_LIST[*]:-(none)}"

# --- Commands ---
CMD_LIST=()
if [[ -d "$PLUGIN_DIR/commands" ]]; then
  for cmd_file in "$PLUGIN_DIR/commands"/*.md; do
    [[ -f "$cmd_file" ]] || continue
    c_name=$(basename "$cmd_file" .md)
    CMD_LIST+=("/$c_name")
  done
fi
echo "Commands (${#CMD_LIST[@]}): ${CMD_LIST[*]:-(none)}"

# --- Templates ---
TMPL_LIST=()
if [[ -d "$PLUGIN_DIR/skills" ]]; then
  while IFS= read -r -d '' tmpl_dir; do
    for tmpl_file in "$tmpl_dir"/*; do
      [[ -f "$tmpl_file" ]] || continue
      TMPL_LIST+=("$(basename "$tmpl_file")")
    done
  done < <(find "$PLUGIN_DIR/skills" -type d -name 'templates' -print0 2>/dev/null)
fi
echo "Templates (${#TMPL_LIST[@]}): ${TMPL_LIST[*]:-(none)}"

# --- Scripts ---
SCRIPT_LIST=()
if [[ -d "$PLUGIN_DIR/skills" ]]; then
  while IFS= read -r -d '' script_dir; do
    for script_file in "$script_dir"/*; do
      [[ -f "$script_file" ]] || continue
      SCRIPT_LIST+=("$(basename "$script_file")")
    done
  done < <(find "$PLUGIN_DIR/skills" -type d -name 'scripts' -print0 2>/dev/null)
fi
echo "Scripts (${#SCRIPT_LIST[@]}): ${SCRIPT_LIST[*]:-(none)}"

echo
echo "=== Inventory Complete ==="
