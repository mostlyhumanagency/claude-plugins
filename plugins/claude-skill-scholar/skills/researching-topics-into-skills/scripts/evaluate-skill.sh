#!/usr/bin/env bash
# A/B evaluation comparing Claude WITH vs WITHOUT a skill.
# Usage: evaluate-skill.sh <skill-dir> [--trials 3] [--model haiku] [--budget 2.00] [--judge-model sonnet]
set -euo pipefail

# --- Helpers ---
info() { echo -e "\033[0;34mINFO:\033[0m $1"; }
warn() { echo -e "\033[0;33mWARN:\033[0m $1"; }
err()  { echo -e "\033[0;31mFAIL:\033[0m $1"; }
ok()   { echo -e "\033[0;32m  OK:\033[0m $1"; }

MODEL="haiku"
JUDGE_MODEL="sonnet"
TRIALS=3
BUDGET="2.00"
SKILL_DIR=""

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --trials)      TRIALS="$2"; shift 2 ;;
    --model)       MODEL="$2"; shift 2 ;;
    --budget)      BUDGET="$2"; shift 2 ;;
    --judge-model) JUDGE_MODEL="$2"; shift 2 ;;
    -*)            echo "Unknown option: $1"; exit 2 ;;
    *)             SKILL_DIR="$1"; shift ;;
  esac
done

if [[ -z "$SKILL_DIR" ]]; then
  echo "Usage: evaluate-skill.sh <skill-dir> [--trials 3] [--model haiku] [--budget 2.00] [--judge-model sonnet]"
  exit 2
fi

SKILL_FILE="$SKILL_DIR/SKILL.md"
if [[ ! -f "$SKILL_FILE" ]]; then
  err "SKILL.md not found at $SKILL_FILE"
  exit 2
fi

# Per-run budget = total / (trials * 2 for control+treatment + trials for judging)
RUN_BUDGET=$(echo "scale=2; $BUDGET / ($TRIALS * 3)" | bc)

echo "=== Skill A/B Evaluation ==="
echo "  skill: $SKILL_DIR"
echo "  model: $MODEL | judge: $JUDGE_MODEL"
echo "  trials: $TRIALS | budget: \$$BUDGET (per-run: \$$RUN_BUDGET)"
echo

# --- Find Plugin Directory ---
PLUGIN_DIR=""
SEARCH_DIR="$SKILL_DIR"
for _ in 1 2 3 4 5; do
  SEARCH_DIR=$(dirname "$SEARCH_DIR")
  if [[ -f "$SEARCH_DIR/.claude-plugin/plugin.json" ]]; then
    PLUGIN_DIR="$SEARCH_DIR"
    break
  fi
done

if [[ -z "$PLUGIN_DIR" ]]; then
  err "could not locate plugin directory"
  exit 2
fi
ok "plugin directory: $PLUGIN_DIR"

# --- Phase 1: Extract Skill Metadata ---
echo
echo "--- Phase 1: Extract Skill Metadata ---"

FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')
SKILL_NAME=$(echo "$FRONTMATTER" | grep -E '^name:' | head -1 | sed 's/^name: *//')
DESC=$(echo "$FRONTMATTER" | sed -n '/^description:/,/^[a-z_-]*:/p' | sed '$ d' | sed 's/^description: *>*//' | tr '\n' ' ' | sed 's/  */ /g' | xargs)
BODY=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$SKILL_FILE")

# Extract key sections
WHEN_TO_USE=$(echo "$BODY" | sed -n '/^## When to Use/,/^## /p' | sed '1d;$ d')
COMMON_MISTAKES=$(echo "$BODY" | sed -n '/^## Common Mistakes/,/^## /p' | sed '1d;$ d')
CORE_PATTERNS=$(echo "$BODY" | sed -n '/^## Core Patterns/,/^## /p' | sed '1d;$ d' 2>/dev/null || echo "")

# Write metadata JSON
EVAL_DIR=$(mktemp -d /tmp/skill-eval-XXXXXX)
cat > "$EVAL_DIR/metadata.json" <<METAEOF
{
  "name": "$SKILL_NAME",
  "description": $(echo "$DESC" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'),
  "when_to_use": $(echo "$WHEN_TO_USE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'),
  "common_mistakes": $(echo "$COMMON_MISTAKES" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'),
  "core_patterns": $(echo "$CORE_PATTERNS" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))')
}
METAEOF

ok "metadata extracted to $EVAL_DIR/metadata.json"

# --- Phase 2: Generate Evaluation Prompts ---
echo
echo "--- Phase 2: Generate Evaluation Prompts ---"

GEN_PROMPT="Given this skill metadata, generate exactly $((TRIALS * 2)) realistic evaluation prompts that a developer would ask. Each prompt should test whether the skill improves Claude's response. Output one prompt per line, no numbering, no quotes.

Skill: $SKILL_NAME
Description: $DESC
When to use: $WHEN_TO_USE"

PROMPTS_RAW=$(claude -p "$GEN_PROMPT" --model "$MODEL" --max-budget-usd "$RUN_BUDGET" --print --dangerously-skip-permissions 2>/dev/null || echo "")

if [[ -z "$PROMPTS_RAW" ]]; then
  warn "prompt generation failed — using fallback prompts"
  PROMPTS_RAW="How do I use $SKILL_NAME effectively?
Show me best practices for $SKILL_NAME
Help me implement a project using $SKILL_NAME"
fi

# Pick N random prompts
EVAL_PROMPTS=()
while IFS= read -r line; do
  line=$(echo "$line" | xargs)
  [[ -n "$line" ]] && EVAL_PROMPTS+=("$line")
done <<< "$PROMPTS_RAW"

# Shuffle and take TRIALS count
SELECTED=()
for i in $(shuf -i 0-$((${#EVAL_PROMPTS[@]} - 1)) -n "$TRIALS" 2>/dev/null || seq 0 $((TRIALS - 1))); do
  idx=$((i % ${#EVAL_PROMPTS[@]}))
  SELECTED+=("${EVAL_PROMPTS[$idx]}")
done

info "selected ${#SELECTED[@]} evaluation prompts"

# --- Phase 3: Run Control vs Treatment ---
echo
echo "--- Phase 3: Running A/B Trials ---"

RESULTS_DIR="$EVAL_DIR/results"
mkdir -p "$RESULTS_DIR"

for i in "${!SELECTED[@]}"; do
  PROMPT="${SELECTED[$i]}"
  TRIAL_NUM=$((i + 1))
  echo
  info "trial $TRIAL_NUM/$TRIALS: ${PROMPT:0:80}"

  # Create identical project scaffolding
  CONTROL_DIR=$(mktemp -d /tmp/skill-eval-ctrl-XXXXXX)
  TREATMENT_DIR=$(mktemp -d /tmp/skill-eval-treat-XXXXXX)

  echo "# Test Project" > "$CONTROL_DIR/README.md"
  echo "# Test Project" > "$TREATMENT_DIR/README.md"
  echo '{"name":"test","version":"1.0.0"}' > "$CONTROL_DIR/package.json"
  echo '{"name":"test","version":"1.0.0"}' > "$TREATMENT_DIR/package.json"

  # Control: no plugin
  info "  running control (no skill)..."
  CONTROL_RESP=$(claude --print -p "$PROMPT" --model "$MODEL" --max-budget-usd "$RUN_BUDGET" \
    --dangerously-skip-permissions --cwd "$CONTROL_DIR" \
    --allowedTools "Read,Write,Edit,Bash,Glob,Grep" 2>/dev/null || echo "ERROR: control failed")

  # Treatment: with plugin
  info "  running treatment (with skill)..."
  TREATMENT_RESP=$(claude --print -p "$PROMPT" --model "$MODEL" --max-budget-usd "$RUN_BUDGET" \
    --dangerously-skip-permissions --cwd "$TREATMENT_DIR" \
    --plugin-dir "$PLUGIN_DIR" \
    --allowedTools "Read,Write,Edit,Bash,Glob,Grep" 2>/dev/null || echo "ERROR: treatment failed")

  # Save responses
  echo "$CONTROL_RESP" > "$RESULTS_DIR/trial-${TRIAL_NUM}-control.txt"
  echo "$TREATMENT_RESP" > "$RESULTS_DIR/trial-${TRIAL_NUM}-treatment.txt"
  echo "$PROMPT" > "$RESULTS_DIR/trial-${TRIAL_NUM}-prompt.txt"

  ok "  trial $TRIAL_NUM responses saved"

  # Cleanup scaffolding
  rm -rf "$CONTROL_DIR" "$TREATMENT_DIR"
done

# --- Phase 4: Judge Each Pair ---
echo
echo "--- Phase 4: Judging Responses ---"

for i in $(seq 1 "$TRIALS"); do
  PROMPT=$(cat "$RESULTS_DIR/trial-${i}-prompt.txt")
  CONTROL=$(cat "$RESULTS_DIR/trial-${i}-control.txt")
  TREATMENT=$(cat "$RESULTS_DIR/trial-${i}-treatment.txt")

  info "judging trial $i..."

  JUDGE_PROMPT="You are evaluating two AI responses to the same prompt. Score each on 5 dimensions (0-10 scale).

PROMPT: $PROMPT

RESPONSE A (control):
$CONTROL

RESPONSE B (treatment):
$TREATMENT

Score each response on these dimensions. Output ONLY valid JSON with this exact structure:
{
  \"control\": {\"accuracy\": N, \"completeness\": N, \"best_practices\": N, \"error_avoidance\": N, \"specificity\": N},
  \"treatment\": {\"accuracy\": N, \"completeness\": N, \"best_practices\": N, \"error_avoidance\": N, \"specificity\": N}
}"

  JUDGE_RESULT=$(claude -p "$JUDGE_PROMPT" --model "$JUDGE_MODEL" --max-budget-usd "$RUN_BUDGET" \
    --print --dangerously-skip-permissions 2>/dev/null || echo '{}')

  # Extract JSON from response (handle markdown wrapping)
  JUDGE_JSON=$(echo "$JUDGE_RESULT" | grep -o '{.*}' | tail -1 || echo '{}')
  echo "$JUDGE_JSON" > "$RESULTS_DIR/trial-${i}-scores.json"
  ok "trial $i scored"
done

# --- Phase 5: Aggregate Results ---
echo
echo "--- Phase 5: Aggregation ---"

python3 - "$RESULTS_DIR" "$TRIALS" "$EVAL_DIR" <<'PYEOF'
import json, sys, os

results_dir = sys.argv[1]
trials = int(sys.argv[2])
eval_dir = sys.argv[3]
dimensions = ["accuracy", "completeness", "best_practices", "error_avoidance", "specificity"]

control_totals = {d: 0.0 for d in dimensions}
treatment_totals = {d: 0.0 for d in dimensions}
valid_trials = 0

for i in range(1, trials + 1):
    scores_file = os.path.join(results_dir, f"trial-{i}-scores.json")
    if not os.path.exists(scores_file):
        continue
    try:
        with open(scores_file) as f:
            scores = json.load(f)
        if "control" not in scores or "treatment" not in scores:
            continue
        for d in dimensions:
            control_totals[d] += float(scores["control"].get(d, 0))
            treatment_totals[d] += float(scores["treatment"].get(d, 0))
        valid_trials += 1
    except (json.JSONDecodeError, ValueError, KeyError):
        continue

if valid_trials == 0:
    print("ERROR: No valid trial results to aggregate")
    sys.exit(1)

print(f"\n{'Dimension':<20} {'Control':>10} {'Treatment':>10} {'Delta':>10} {'Impact':>15}")
print("-" * 70)

overall_control = 0.0
overall_treatment = 0.0

report = {"trials": valid_trials, "dimensions": {}, "overall": {}}

for d in dimensions:
    c_avg = control_totals[d] / valid_trials
    t_avg = treatment_totals[d] / valid_trials
    delta = t_avg - c_avg
    overall_control += c_avg
    overall_treatment += t_avg

    if delta >= 2.0:
        impact = "STRONG+"
    elif delta >= 0.5:
        impact = "MODERATE+"
    elif delta > -0.5:
        impact = "NEUTRAL"
    elif delta > -2.0:
        impact = "MODERATE-"
    else:
        impact = "STRONG-"

    print(f"{d:<20} {c_avg:>10.1f} {t_avg:>10.1f} {delta:>+10.1f} {impact:>15}")
    report["dimensions"][d] = {
        "control": round(c_avg, 2),
        "treatment": round(t_avg, 2),
        "delta": round(delta, 2),
        "impact": impact
    }

overall_c = overall_control / len(dimensions)
overall_t = overall_treatment / len(dimensions)
overall_delta = overall_t - overall_c

if overall_delta >= 2.0:
    interpretation = "STRONG POSITIVE — skill significantly improves responses"
elif overall_delta >= 0.5:
    interpretation = "MODERATE POSITIVE — skill noticeably improves responses"
elif overall_delta > -0.5:
    interpretation = "NEUTRAL — skill has minimal measurable impact"
elif overall_delta > -2.0:
    interpretation = "MODERATE NEGATIVE — skill may be hurting responses"
else:
    interpretation = "STRONG NEGATIVE — skill is degrading response quality"

print("-" * 70)
print(f"{'OVERALL':<20} {overall_c:>10.1f} {overall_t:>10.1f} {overall_delta:>+10.1f}")
print(f"\nInterpretation: {interpretation}")

report["overall"] = {
    "control": round(overall_c, 2),
    "treatment": round(overall_t, 2),
    "delta": round(overall_delta, 2),
    "interpretation": interpretation
}

report_path = os.path.join(eval_dir, "report.json")
with open(report_path, "w") as f:
    json.dump(report, f, indent=2)
print(f"\nMachine-readable report: {report_path}")
PYEOF

echo
echo "=== Evaluation Complete ==="
echo "Results directory: $EVAL_DIR"
