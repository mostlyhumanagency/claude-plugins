#!/usr/bin/env bash
# Compare two versions of a skill (directories or git refs).
# Usage: diff-skill.sh <skill-dir-a> <skill-dir-b>
#    OR: diff-skill.sh <skill-dir> --ref <git-ref>
set -euo pipefail

# --- Helpers ---
info() { echo -e "\033[0;34mINFO:\033[0m $1"; }
warn() { echo -e "\033[0;33mWARN:\033[0m $1"; }
err()  { echo -e "\033[0;31mFAIL:\033[0m $1"; }
ok()   { echo -e "\033[0;32m  OK:\033[0m $1"; }

DIR_A=""
DIR_B=""
GIT_REF=""

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref) GIT_REF="$2"; shift 2 ;;
    -*)    echo "Unknown option: $1"; exit 2 ;;
    *)
      if [[ -z "$DIR_A" ]]; then
        DIR_A="$1"
      elif [[ -z "$DIR_B" ]]; then
        DIR_B="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$DIR_A" ]]; then
  echo "Usage: diff-skill.sh <skill-dir-a> <skill-dir-b>"
  echo "   OR: diff-skill.sh <skill-dir> --ref <git-ref>"
  exit 2
fi

# --- Helper Functions ---
count_words() {
  if [[ -f "$1" ]]; then
    wc -w < "$1" | tr -d ' '
  else
    echo "0"
  fi
}

extract_sections() {
  grep -E '^##+ ' "$1" 2>/dev/null | sed 's/^##* //' || true
}

extract_name() {
  local file="$1"
  sed -n '/^---$/,/^---$/p' "$file" 2>/dev/null | grep -E '^name:' | head -1 | sed 's/^name: *//'
}

# --- Setup Comparison Directories ---
CLEANUP_DIR=""

if [[ -n "$GIT_REF" ]]; then
  # Create temp copy of skill at the given git ref
  info "extracting skill at ref: $GIT_REF"

  # Find git root
  GIT_ROOT=$(cd "$DIR_A" && git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$GIT_ROOT" ]]; then
    err "not a git repository: $DIR_A"
    exit 2
  fi

  # Get relative path from git root
  REL_PATH=$(realpath --relative-to="$GIT_ROOT" "$DIR_A")

  DIR_B=$(mktemp -d /tmp/skill-diff-XXXXXX)
  CLEANUP_DIR="$DIR_B"

  # Extract files at the given ref
  mkdir -p "$DIR_B"
  (cd "$GIT_ROOT" && git show "$GIT_REF:$REL_PATH/SKILL.md" > "$DIR_B/SKILL.md" 2>/dev/null) || true

  # Extract references
  REF_FILES=$(cd "$GIT_ROOT" && git ls-tree --name-only "$GIT_REF" "$REL_PATH/references/" 2>/dev/null || true)
  if [[ -n "$REF_FILES" ]]; then
    mkdir -p "$DIR_B/references"
    while IFS= read -r rf; do
      fname=$(basename "$rf")
      (cd "$GIT_ROOT" && git show "$GIT_REF:$rf" > "$DIR_B/references/$fname" 2>/dev/null) || true
    done <<< "$REF_FILES"
  fi

  # Swap: A = old (git ref), B = current
  TEMP="$DIR_A"
  DIR_A="$DIR_B"
  DIR_B="$TEMP"

  info "comparing: $GIT_REF (old) vs current (new)"
elif [[ -z "$DIR_B" ]]; then
  echo "Usage: diff-skill.sh <skill-dir-a> <skill-dir-b>"
  exit 2
fi

# --- Validate ---
SKILL_A="$DIR_A/SKILL.md"
SKILL_B="$DIR_B/SKILL.md"

if [[ ! -f "$SKILL_A" ]]; then
  err "SKILL.md not found in directory A: $DIR_A"
  [[ -n "$CLEANUP_DIR" ]] && rm -rf "$CLEANUP_DIR"
  exit 2
fi
if [[ ! -f "$SKILL_B" ]]; then
  err "SKILL.md not found in directory B: $DIR_B"
  [[ -n "$CLEANUP_DIR" ]] && rm -rf "$CLEANUP_DIR"
  exit 2
fi

# --- Extract Skill Name ---
SKILL_NAME=$(extract_name "$SKILL_B")
[[ -z "$SKILL_NAME" ]] && SKILL_NAME=$(basename "$DIR_B")

echo "=== Skill Diff: $SKILL_NAME ==="
echo

# --- Compare SKILL.md ---
echo "--- SKILL.md ---"

WC_A=$(count_words "$SKILL_A")
WC_B=$(count_words "$SKILL_B")
WC_DELTA=$((WC_B - WC_A))
DELTA_SIGN=""
[[ "$WC_DELTA" -ge 0 ]] && DELTA_SIGN="+"
echo "SKILL.md: $WC_A -> $WC_B words (${DELTA_SIGN}${WC_DELTA})"

# Sections comparison
SECTIONS_A=$(extract_sections "$SKILL_A")
SECTIONS_B=$(extract_sections "$SKILL_B")

ADDED_SECTIONS=$(comm -13 <(echo "$SECTIONS_A" | sort) <(echo "$SECTIONS_B" | sort) 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
REMOVED_SECTIONS=$(comm -23 <(echo "$SECTIONS_A" | sort) <(echo "$SECTIONS_B" | sort) 2>/dev/null | tr '\n' ', ' | sed 's/, $//')

echo "Sections added: ${ADDED_SECTIONS:-(none)}"
echo "Sections removed: ${REMOVED_SECTIONS:-(none)}"

# Frontmatter changes
FM_A=$(sed -n '/^---$/,/^---$/p' "$SKILL_A" | sed '1d;$d')
FM_B=$(sed -n '/^---$/,/^---$/p' "$SKILL_B" | sed '1d;$d')

DESC_A=$(echo "$FM_A" | sed -n '/^description:/,/^[a-z_-]*:/p' | sed '$ d' | md5 2>/dev/null || echo "$FM_A" | grep -i 'description' | md5sum | cut -d' ' -f1)
DESC_B=$(echo "$FM_B" | sed -n '/^description:/,/^[a-z_-]*:/p' | sed '$ d' | md5 2>/dev/null || echo "$FM_B" | grep -i 'description' | md5sum | cut -d' ' -f1)

if [[ "$DESC_A" == "$DESC_B" ]]; then
  echo "Description changed: no"
else
  echo "Description changed: yes"
fi

# --- Compare References ---
echo
echo "--- References ---"

REF_A_DIR="$DIR_A/references"
REF_B_DIR="$DIR_B/references"

# Gather all reference filenames
ALL_REFS=()
if [[ -d "$REF_A_DIR" ]]; then
  for f in "$REF_A_DIR"/*.md; do
    [[ -f "$f" ]] && ALL_REFS+=("$(basename "$f")")
  done
fi
if [[ -d "$REF_B_DIR" ]]; then
  for f in "$REF_B_DIR"/*.md; do
    [[ -f "$f" ]] && ALL_REFS+=("$(basename "$f")")
  done
fi

# Deduplicate
UNIQUE_REFS=($(printf '%s\n' "${ALL_REFS[@]}" | sort -u))

if [[ ${#UNIQUE_REFS[@]} -eq 0 ]]; then
  echo "No reference files in either version."
else
  for ref in "${UNIQUE_REFS[@]}"; do
    FILE_A="$REF_A_DIR/$ref"
    FILE_B="$REF_B_DIR/$ref"

    if [[ ! -f "$FILE_A" ]] && [[ -f "$FILE_B" ]]; then
      WC=$(count_words "$FILE_B")
      echo "NEW: $ref ($WC words)"
    elif [[ -f "$FILE_A" ]] && [[ ! -f "$FILE_B" ]]; then
      echo "REMOVED: $ref"
    else
      WCA=$(count_words "$FILE_A")
      WCB=$(count_words "$FILE_B")
      DELTA=$((WCB - WCA))
      DS=""
      [[ "$DELTA" -ge 0 ]] && DS="+"
      echo "$ref: $WCA -> $WCB words (${DS}${DELTA})"
    fi
  done
fi

# --- Cleanup ---
if [[ -n "$CLEANUP_DIR" ]]; then
  rm -rf "$CLEANUP_DIR"
fi

echo
echo "=== Diff Complete ==="
