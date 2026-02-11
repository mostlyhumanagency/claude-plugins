#!/usr/bin/env bash
# Smoke-test a skill by running Claude CLI instances against generated scenarios.
# Usage: test-skill.sh <skill-dir> [--model haiku] [--verbose] [--budget 0.25]
set -euo pipefail

# --- Helpers ---
info() { echo -e "\033[0;34mINFO:\033[0m $1"; }
warn() { echo -e "\033[0;33mWARN:\033[0m $1"; }
err()  { echo -e "\033[0;31mFAIL:\033[0m $1"; }
ok()   { echo -e "\033[0;32m  OK:\033[0m $1"; }

MODEL="haiku"
VERBOSE=false
BUDGET="0.25"
SKILL_DIR=""

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)   MODEL="$2"; shift 2 ;;
    --verbose) VERBOSE=true; shift ;;
    --budget)  BUDGET="$2"; shift 2 ;;
    -*)        echo "Unknown option: $1"; exit 2 ;;
    *)         SKILL_DIR="$1"; shift ;;
  esac
done

if [[ -z "$SKILL_DIR" ]]; then
  echo "Usage: test-skill.sh <skill-dir> [--model haiku] [--verbose] [--budget 0.25]"
  exit 2
fi

SKILL_FILE="$SKILL_DIR/SKILL.md"
if [[ ! -f "$SKILL_FILE" ]]; then
  err "SKILL.md not found at $SKILL_FILE"
  exit 2
fi

echo "=== Skill Smoke Test: $SKILL_DIR ==="
echo

# --- Parse Frontmatter ---
echo "--- Parsing Skill Metadata ---"

FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')
SKILL_NAME=$(echo "$FRONTMATTER" | grep -E '^name:' | head -1 | sed 's/^name: *//')
info "skill name: $SKILL_NAME"

# Extract description
DESC=$(echo "$FRONTMATTER" | sed -n '/^description:/,/^[a-z_-]*:/p' | sed '$ d' | sed 's/^description: *>*//' | tr '\n' ' ' | sed 's/  */ /g' | xargs)
info "description: ${DESC:0:100}..."

# Extract quoted trigger phrases from description
TRIGGERS=()
while IFS= read -r trigger; do
  [[ -n "$trigger" ]] && TRIGGERS+=("$trigger")
done < <(echo "$DESC" | grep -oE '"[^"]+"|"[^"]+"' | sed 's/^[""]//;s/[""]$//')

info "found ${#TRIGGERS[@]} trigger phrase(s)"

# Extract "When to Use" bullets
WHEN_BULLETS=()
BODY=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$SKILL_FILE")
IN_WHEN=false
while IFS= read -r line; do
  if echo "$line" | grep -q '## When to Use'; then
    IN_WHEN=true
    continue
  fi
  if $IN_WHEN && echo "$line" | grep -q '^## '; then
    break
  fi
  if $IN_WHEN && echo "$line" | grep -qE '^- '; then
    bullet=$(echo "$line" | sed 's/^- //')
    WHEN_BULLETS+=("$bullet")
  fi
done <<< "$BODY"

info "found ${#WHEN_BULLETS[@]} when-to-use condition(s)"

# --- Find Plugin Directory ---
echo
echo "--- Locating Plugin ---"

PLUGIN_DIR=""
SEARCH_DIR="$SKILL_DIR"
for _ in 1 2 3 4 5; do
  SEARCH_DIR=$(dirname "$SEARCH_DIR")
  if [[ -f "$SEARCH_DIR/.claude-plugin/plugin.json" ]]; then
    PLUGIN_DIR="$SEARCH_DIR"
    break
  fi
done

if [[ -n "$PLUGIN_DIR" ]]; then
  ok "plugin directory: $PLUGIN_DIR"
else
  warn "could not locate plugin directory — tests will run without --plugin-dir"
fi

# --- Generate Scenarios ---
echo
echo "--- Generating Scenarios ---"

SCENARIOS=()

# From trigger phrases
for trigger in "${TRIGGERS[@]}"; do
  SCENARIOS+=("I want to $trigger")
done

# From when-to-use bullets
for bullet in "${WHEN_BULLETS[@]}"; do
  SCENARIOS+=("$bullet")
done

# Ensure minimum 3 scenarios
if [[ ${#SCENARIOS[@]} -lt 3 ]]; then
  SCENARIOS+=("Help me with $SKILL_NAME")
  SCENARIOS+=("How do I use $SKILL_NAME effectively?")
  SCENARIOS+=("Show me best practices for $SKILL_NAME")
fi

info "generated ${#SCENARIOS[@]} test scenario(s)"

# --- Extract Key Terms for Pattern Matching ---
KEY_TERMS=()
while IFS= read -r term; do
  [[ -n "$term" ]] && KEY_TERMS+=("$term")
done < <(grep -oE '`[^`]+`' "$SKILL_FILE" | sed 's/`//g' | sort -u | head -20)

while IFS= read -r header; do
  [[ -n "$header" ]] && KEY_TERMS+=("$header")
done < <(grep -E '^##+ ' "$SKILL_FILE" | sed 's/^##* //' | head -10)

info "extracted ${#KEY_TERMS[@]} key terms for pattern matching"

# --- Run Scenarios ---
echo
echo "--- Running Scenarios ---"

PASSED=0
FAILED=0
TOTAL=${#SCENARIOS[@]}

for i in "${!SCENARIOS[@]}"; do
  SCENARIO="${SCENARIOS[$i]}"
  NUM=$((i + 1))
  echo
  info "scenario $NUM/$TOTAL: ${SCENARIO:0:80}"

  # Create temp project directory with scaffolding
  TMPDIR=$(mktemp -d /tmp/skill-test-XXXXXX)

  # Detect domain and create appropriate scaffolding
  if echo "$SKILL_NAME $DESC" | grep -qiE 'node|javascript|typescript|npm|react|vue|svelte'; then
    echo '{"name":"test-project","version":"1.0.0","description":"test"}' > "$TMPDIR/package.json"
    echo "console.log('hello');" > "$TMPDIR/index.js"
  elif echo "$SKILL_NAME $DESC" | grep -qiE 'python|django|flask|pip'; then
    echo "print('hello')" > "$TMPDIR/main.py"
    touch "$TMPDIR/requirements.txt"
  else
    echo "# Test Project" > "$TMPDIR/README.md"
  fi

  # Build claude command
  CMD=(claude -p "$SCENARIO" --model "$MODEL" --print --dangerously-skip-permissions --max-budget-usd "$BUDGET")
  CMD+=(--allowedTools "Read,Write,Edit,Bash,Glob,Grep")
  CMD+=(--cwd "$TMPDIR")

  if [[ -n "$PLUGIN_DIR" ]]; then
    CMD+=(--plugin-dir "$PLUGIN_DIR")
  fi

  # Run and capture output
  RESPONSE=""
  if RESPONSE=$("${CMD[@]}" 2>/dev/null); then
    RESP_WORDS=$(echo "$RESPONSE" | wc -w | tr -d ' ')

    # Pattern matching: count how many key terms appear
    MATCHES=0
    for term in "${KEY_TERMS[@]}"; do
      if echo "$RESPONSE" | grep -qi "$term" 2>/dev/null; then
        ((MATCHES++))
      fi
    done

    TOTAL_TERMS=${#KEY_TERMS[@]}
    if [[ "$TOTAL_TERMS" -gt 0 ]]; then
      MATCH_PCT=$(( (MATCHES * 100) / TOTAL_TERMS ))
    else
      MATCH_PCT=100
    fi

    if [[ "$MATCH_PCT" -ge 20 && "$RESP_WORDS" -gt 50 ]]; then
      ok "PASS — $RESP_WORDS words, $MATCHES/$TOTAL_TERMS terms matched ($MATCH_PCT%)"
      ((PASSED++))
    else
      err "FAIL — $RESP_WORDS words, $MATCHES/$TOTAL_TERMS terms matched ($MATCH_PCT%)"
      ((FAILED++))
    fi

    if $VERBOSE; then
      echo "--- Response Preview ---"
      echo "$RESPONSE" | head -20
      echo "--- End Preview ---"
    fi
  else
    err "FAIL — claude command failed"
    ((FAILED++))
  fi

  # Cleanup
  rm -rf "$TMPDIR"
done

# --- Summary ---
echo
echo "=== Test Summary: $PASSED/$TOTAL passed, $FAILED/$TOTAL failed ==="

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
exit 0
