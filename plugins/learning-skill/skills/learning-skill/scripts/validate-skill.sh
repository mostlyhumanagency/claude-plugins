#!/usr/bin/env bash
# Validate a produced Claude Code skill against quality checklist.
# Usage: validate-skill.sh <skill-directory>
# Exit 0 = all checks pass, Exit 2 = validation errors found

set -euo pipefail

SKILL_DIR="${1:?Usage: validate-skill.sh <skill-directory>}"
SKILL_FILE="$SKILL_DIR/SKILL.md"
ERRORS=0

err() { echo "FAIL: $1"; ((ERRORS++)); }
ok()  { echo "  OK: $1"; }

echo "=== Validating skill: $SKILL_DIR ==="
echo

# Check SKILL.md exists
if [[ ! -f "$SKILL_FILE" ]]; then
  err "SKILL.md not found at $SKILL_FILE"
  exit 2
fi
ok "SKILL.md exists"

# Extract frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')

# Check name field
if echo "$FRONTMATTER" | grep -q '^name:'; then
  NAME=$(echo "$FRONTMATTER" | grep '^name:' | head -1 | sed 's/^name: *//')
  if echo "$NAME" | grep -qE '^[a-z0-9-]+$'; then
    ok "name field valid: $NAME"
  else
    err "name field contains invalid characters (use lowercase, numbers, hyphens only): $NAME"
  fi
else
  err "name field missing from frontmatter"
fi

# Check description field
if echo "$FRONTMATTER" | grep -qi 'description:'; then
  DESC=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d' | sed -n '/^description:/,/^[a-z]/p' | head -5)
  if echo "$DESC" | grep -qi 'should be used when\|triggers on\|use when'; then
    ok "description includes trigger conditions"
  else
    err "description should include trigger conditions (e.g., 'This skill should be used when...')"
  fi
else
  err "description field missing from frontmatter"
fi

# Count body words (everything after second ---)
BODY=$(sed -n '/^---$/,/^---$/!p' "$SKILL_FILE" | tail -n +1)
WORD_COUNT=$(echo "$BODY" | wc -w | tr -d ' ')
if [[ "$WORD_COUNT" -le 5000 ]]; then
  ok "body word count: $WORD_COUNT (limit: 5,000)"
else
  err "body word count: $WORD_COUNT exceeds hard limit of 5,000"
fi

if [[ "$WORD_COUNT" -ge 1000 && "$WORD_COUNT" -le 2500 ]]; then
  ok "body word count in ideal range (1,000-2,500)"
elif [[ "$WORD_COUNT" -gt 2500 ]]; then
  echo "WARN: body word count $WORD_COUNT is above ideal range (1,000-2,500) — consider extracting to references/"
fi

# Check required sections
for SECTION in "## Overview" "## When to Use" "## Common Mistakes"; do
  if grep -q "$SECTION" "$SKILL_FILE"; then
    ok "section present: $SECTION"
  else
    err "missing section: $SECTION"
  fi
done

# Check for quick reference table
if grep -q '|.*|.*|' "$SKILL_FILE"; then
  ok "contains at least one table"
else
  err "no tables found — add a Quick Reference table"
fi

# Check reference files are one level deep
if [[ -d "$SKILL_DIR/references" ]]; then
  NESTED=$(find "$SKILL_DIR/references" -mindepth 2 -name '*.md' 2>/dev/null | head -5)
  if [[ -n "$NESTED" ]]; then
    err "nested reference files found (must be one level deep): $NESTED"
  else
    ok "reference files are one level deep"
  fi
fi

echo
echo "=== Results: $ERRORS error(s) ==="

if [[ "$ERRORS" -gt 0 ]]; then
  exit 2
fi
exit 0
