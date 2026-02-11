#!/usr/bin/env bash
# Enhanced skill quality review — primary validator for Claude Code skills.
# Usage: review-skill.sh <skill-dir> [--deep] [--fix] [--plugin-dir <dir>]
# Exit 0 = pass, Exit 1 = warnings only, Exit 2 = errors found
set -euo pipefail

# --- Helpers ---
info() { echo -e "\033[0;34mINFO:\033[0m $1"; }
warn() { echo -e "\033[0;33mWARN:\033[0m $1"; ((WARNINGS++)); }
err()  { echo -e "\033[0;31mFAIL:\033[0m $1"; ((ERRORS++)); }
ok()   { echo -e "\033[0;32m  OK:\033[0m $1"; }

ERRORS=0
WARNINGS=0
DEEP=false
FIX=false
PLUGIN_DIR=""
SKILL_DIR=""

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --deep) DEEP=true; shift ;;
    --fix)  FIX=true; shift ;;
    --plugin-dir) PLUGIN_DIR="$2"; shift 2 ;;
    -*)     echo "Unknown option: $1"; exit 2 ;;
    *)      SKILL_DIR="$1"; shift ;;
  esac
done

if [[ -z "$SKILL_DIR" ]]; then
  echo "Usage: review-skill.sh <skill-dir> [--deep] [--fix] [--plugin-dir <dir>]"
  exit 2
fi

SKILL_FILE="$SKILL_DIR/SKILL.md"

echo "=== Skill Review: $SKILL_DIR ==="
echo

# -------------------------------------------------------
echo "--- File Structure ---"

if [[ ! -f "$SKILL_FILE" ]]; then
  err "SKILL.md not found at $SKILL_FILE"
  echo
  echo "=== Results: $ERRORS error(s), $WARNINGS warning(s) ==="
  exit 2
fi
ok "SKILL.md exists"

# references/ one level deep
if [[ -d "$SKILL_DIR/references" ]]; then
  NESTED=$(find "$SKILL_DIR/references" -mindepth 2 -name '*.md' 2>/dev/null | head -5)
  if [[ -n "$NESTED" ]]; then
    err "nested reference files found (must be one level deep): $NESTED"
  else
    ok "reference files are one level deep"
  fi
fi

# scripts executable
if [[ -d "$SKILL_DIR/scripts" ]]; then
  while IFS= read -r -d '' script; do
    if [[ ! -x "$script" ]]; then
      if $FIX; then
        chmod +x "$script"
        info "fixed: chmod +x $script"
      else
        err "script not executable: $script"
      fi
    else
      ok "script executable: $(basename "$script")"
    fi
  done < <(find "$SKILL_DIR/scripts" -type f -print0)
fi

# templates non-empty
if [[ -d "$SKILL_DIR/templates" ]]; then
  while IFS= read -r -d '' tmpl; do
    if [[ ! -s "$tmpl" ]]; then
      err "template is empty: $tmpl"
    fi
  done < <(find "$SKILL_DIR/templates" -type f -print0)
  ok "templates non-empty check complete"
fi

# -------------------------------------------------------
echo
echo "--- Frontmatter ---"

# Extract frontmatter (between first pair of ---)
FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')

# name field
NAME=$(echo "$FRONTMATTER" | grep -E '^name:' | head -1 | sed 's/^name: *//' | tr -d ' ')
if [[ -z "$NAME" ]]; then
  err "name field missing from frontmatter"
else
  if echo "$NAME" | grep -qE '^[a-z0-9-]+$'; then
    ok "name field valid: $NAME"
  else
    err "name field contains invalid characters (use lowercase, numbers, hyphens): $NAME"
  fi
  if [[ ${#NAME} -gt 64 ]]; then
    err "name exceeds 64 characters: ${#NAME}"
  fi
fi

# description field
DESC_RAW=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')
if echo "$DESC_RAW" | grep -qi '^description:'; then
  # Grab multiline description (YAML folded scalar)
  DESC=$(echo "$DESC_RAW" | sed -n '/^description:/,/^[a-z_-]*:/p' | sed '$ d' | sed 's/^description: *>*//' | tr '\n' ' ' | sed 's/  */ /g' | xargs)
  DESC_LEN=${#DESC}

  if [[ "$DESC_LEN" -lt 50 ]]; then
    err "description too short ($DESC_LEN chars, minimum 50)"
  elif [[ "$DESC_LEN" -gt 500 ]]; then
    err "description too long ($DESC_LEN chars, maximum 500)"
  else
    ok "description length: $DESC_LEN chars"
  fi

  if echo "$DESC" | grep -qi 'should be used when\|triggers on'; then
    ok "description includes trigger conditions"
  else
    err "description should start with 'This skill should be used when...'"
  fi

  # Check for quoted trigger phrases
  if echo "$DESC" | grep -qE '"[^"]+"|"[^"]+"'; then
    ok "description contains quoted trigger phrases"
  else
    warn "description should contain quoted trigger phrases"
  fi

  # Check for workflow summary in description
  if echo "$DESC" | grep -qiE 'step [0-9]|phase [0-9]|first.*then.*finally'; then
    warn "description looks like a workflow summary — keep it to triggers only"
  fi
else
  err "description field missing from frontmatter"
  DESC=""
fi

# -------------------------------------------------------
echo
echo "--- Body Content ---"

BODY=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$SKILL_FILE")
WORD_COUNT=$(echo "$BODY" | wc -w | tr -d ' ')

# Router detection
IS_ROUTER=false
if echo "$DESC" | grep -qiE 'unsure which|route'; then
  IS_ROUTER=true
  info "detected as router skill — applying router rules"
fi

if $IS_ROUTER; then
  if [[ "$WORD_COUNT" -gt 200 ]]; then
    err "router skill body too long: $WORD_COUNT words (limit 200)"
  else
    ok "router body word count: $WORD_COUNT (limit 200)"
  fi
  if echo "$BODY" | grep -qE '^\s*```'; then
    err "router skill should not contain code blocks"
  fi
  if echo "$BODY" | grep -qE '^\|.*\|.*\|'; then
    ok "router has routing table"
  else
    err "router skill missing routing table"
  fi
  if [[ -d "$SKILL_DIR/references" ]] && [[ -n "$(ls -A "$SKILL_DIR/references" 2>/dev/null)" ]]; then
    err "router skill should not have references/"
  fi
else
  # Normal skill checks
  if [[ "$WORD_COUNT" -gt 5000 ]]; then
    err "body word count: $WORD_COUNT exceeds hard limit of 5,000"
  else
    ok "body word count: $WORD_COUNT (hard limit: 5,000)"
  fi
  if [[ "$WORD_COUNT" -ge 1000 && "$WORD_COUNT" -le 2500 ]]; then
    ok "body word count in ideal range (1,000-2,500)"
  elif [[ "$WORD_COUNT" -lt 1000 ]]; then
    warn "body word count $WORD_COUNT is below ideal range (1,000-2,500)"
  else
    warn "body word count $WORD_COUNT is above ideal range (1,000-2,500) — consider extracting to references/"
  fi
fi

# Required sections
for SECTION in "## Overview" "## When to Use" "## Common Mistakes"; do
  if grep -q "$SECTION" "$SKILL_FILE"; then
    ok "section present: $SECTION"
  else
    if $FIX; then
      echo -e "\n$SECTION\n\nTODO: Fill in this section.\n" >> "$SKILL_FILE"
      info "fixed: appended $SECTION with TODO placeholder"
    else
      err "missing section: $SECTION"
    fi
  fi
done

# Recommended sections
for SECTION in "## Core Patterns" "## Quick Reference"; do
  if grep -q "$SECTION" "$SKILL_FILE"; then
    ok "recommended section present: $SECTION"
  else
    warn "missing recommended section: $SECTION"
  fi
done

# Tables
if grep -qE '^\|.*\|.*\|' "$SKILL_FILE"; then
  ok "contains at least one table"
else
  warn "no tables found — consider adding a Quick Reference table"
fi

# Code blocks with language tags
CODE_BLOCKS=$(grep -c '^\s*```' "$SKILL_FILE" || true)
TAGGED_BLOCKS=$(grep -cE '^\s*```[a-z]+' "$SKILL_FILE" || true)
UNTAGGED=$(( (CODE_BLOCKS / 2) - TAGGED_BLOCKS ))
if [[ "$CODE_BLOCKS" -gt 0 ]]; then
  if [[ "$UNTAGGED" -gt 0 ]]; then
    warn "$UNTAGGED code block(s) missing language tags"
  else
    ok "all code blocks have language tags"
  fi
fi

# No emojis
if grep -P '[\x{1F300}-\x{1F9FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}]' "$SKILL_FILE" >/dev/null 2>&1; then
  warn "SKILL.md contains emojis — prefer plain text"
fi

# -------------------------------------------------------
echo
echo "--- File References ---"

# Check that referenced paths in SKILL.md exist on disk
while IFS= read -r ref_path; do
  full_path="$SKILL_DIR/$ref_path"
  if [[ ! -e "$full_path" ]]; then
    err "referenced path not found on disk: $ref_path"
  else
    ok "referenced path exists: $ref_path"
  fi
done < <(grep -oE '(references/[a-zA-Z0-9_./-]+|scripts/[a-zA-Z0-9_./-]+|templates/[a-zA-Z0-9_./-]+|examples/[a-zA-Z0-9_./-]+)' "$SKILL_FILE" | sort -u)

# -------------------------------------------------------
echo
echo "--- Reference File Quality ---"

if [[ -d "$SKILL_DIR/references" ]]; then
  for ref in "$SKILL_DIR/references"/*.md; do
    [[ -f "$ref" ]] || continue
    ref_name=$(basename "$ref")

    # Top-level header
    if head -5 "$ref" | grep -q '^# '; then
      ok "$ref_name has top-level header"
    else
      warn "$ref_name missing top-level header"
    fi

    # Word count
    ref_wc=$(wc -w < "$ref" | tr -d ' ')
    if [[ "$ref_wc" -lt 500 ]]; then
      warn "$ref_name is short: $ref_wc words (ideal 2,000-5,000)"
    elif [[ "$ref_wc" -gt 10000 ]]; then
      warn "$ref_name is very long: $ref_wc words (ideal 2,000-5,000)"
    else
      ok "$ref_name word count: $ref_wc"
    fi

    # Tables
    if grep -qE '^\|.*\|.*\|' "$ref"; then
      ok "$ref_name contains tables"
    else
      warn "$ref_name has no tables"
    fi
  done
fi

# -------------------------------------------------------
echo
echo "--- Writing Style ---"

# Non-imperative phrasing
for PHRASE in "you should" "you can" "we will" "you need to" "you must"; do
  COUNT=$(grep -ci "$PHRASE" "$SKILL_FILE" || true)
  if [[ "$COUNT" -gt 0 ]]; then
    warn "non-imperative phrasing found: \"$PHRASE\" ($COUNT occurrences)"
  fi
done

# CLAUDE_PLUGIN_ROOT in SKILL.md body
if grep -q 'CLAUDE_PLUGIN_ROOT' "$SKILL_FILE"; then
  # Check if it's in the body (not frontmatter)
  BODY_PLUGIN_ROOT=$(echo "$BODY" | grep -c 'CLAUDE_PLUGIN_ROOT' || true)
  if [[ "$BODY_PLUGIN_ROOT" -gt 0 ]]; then
    warn "SKILL.md body references CLAUDE_PLUGIN_ROOT — use relative paths from skill dir instead"
  fi
fi

# -------------------------------------------------------
# Plugin Packaging (only with --plugin-dir)
if [[ -n "$PLUGIN_DIR" ]]; then
  echo
  echo "--- Plugin Packaging ---"

  PJSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
  if [[ -f "$PJSON" ]]; then
    ok "plugin.json exists"
    for field in name version description; do
      if grep -q "\"$field\"" "$PJSON"; then
        ok "plugin.json has $field"
      else
        err "plugin.json missing $field"
      fi
    done
  else
    err "plugin.json not found at $PJSON"
  fi

  # Check no extra files in .claude-plugin/
  EXTRA=$(find "$PLUGIN_DIR/.claude-plugin" -type f ! -name 'plugin.json' 2>/dev/null)
  if [[ -n "$EXTRA" ]]; then
    warn "extra files in .claude-plugin/: $EXTRA"
  fi

  # Skills inside skills/ directory
  if [[ -d "$PLUGIN_DIR/skills" ]]; then
    ok "skills/ directory exists"
  else
    err "skills/ directory not found in plugin"
  fi

  # Overlap check — list sibling skills
  echo
  echo "--- Overlap Check ---"
  info "sibling skills in this plugin:"
  if [[ -d "$PLUGIN_DIR/skills" ]]; then
    for sibling in "$PLUGIN_DIR/skills"/*/SKILL.md; do
      [[ -f "$sibling" ]] || continue
      sib_dir=$(dirname "$sibling")
      sib_name=$(basename "$sib_dir")
      sib_desc=$(sed -n '/^---$/,/^---$/p' "$sibling" | grep -i 'description:' | head -1 | sed 's/^description: *>*//' | head -c 80)
      echo "  - $sib_name: $sib_desc"
    done
  fi
fi

# -------------------------------------------------------
# Deep Mode
if $DEEP; then
  echo
  echo "--- Deep Analysis (LLM) ---"
  if command -v claude >/dev/null 2>&1; then
    DEEP_PROMPT="Analyze this skill file for: 1) Are code examples correct and idiomatic? 2) Are trigger phrases specific enough to avoid false positives? 3) Rate overall quality 1-10 with brief justification. Be concise."
    SKILL_CONTENT=$(cat "$SKILL_FILE")
    DEEP_RESULT=$(claude -p "$DEEP_PROMPT

$SKILL_CONTENT" --model haiku --max-budget-usd 0.05 2>&1 || echo "LLM analysis failed")
    echo "$DEEP_RESULT"
  else
    warn "claude CLI not found — skipping deep analysis"
  fi
fi

# -------------------------------------------------------
echo
echo "=== Review Summary: $ERRORS error(s), $WARNINGS warning(s) ==="

if [[ "$ERRORS" -gt 0 ]]; then
  exit 2
elif [[ "$WARNINGS" -gt 0 ]]; then
  exit 1
fi
exit 0
