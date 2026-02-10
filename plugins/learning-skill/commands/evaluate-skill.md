---
description: "Evaluate a skill's impact by running A/B comparison (with vs without skill)"
argument-hint: <skill-path>
agent: skill-evaluator
context: fork
---

# Evaluate a Skill

Evaluate the impact of the skill at **$ARGUMENTS** by running an A/B comparison (with vs without the skill).

## Default Configuration

- Trials: 3
- Test model: haiku
- Judge model: sonnet
- Budget cap: $2.00 per invocation

## Process

1. Validate the skill exists and contains a valid SKILL.md
2. Parse SKILL.md to extract triggers, patterns, and common mistakes the skill addresses
3. Generate evaluation prompts that target the skill's domain and would benefit from its guidance
4. Run Claude WITH the skill on each prompt, capturing the response
5. Run Claude WITHOUT the skill on the same prompts, capturing the response
6. Use a judge model to score both responses on 5 dimensions:
   - **Correctness**: Are the facts and patterns accurate?
   - **Completeness**: Does the response cover the key aspects?
   - **Best Practices**: Does it follow recommended patterns?
   - **Mistake Avoidance**: Does it avoid the common pitfalls the skill warns about?
   - **Specificity**: Does it give concrete, actionable guidance vs generic advice?
7. Aggregate scores across all trials and present a comparison report

## Output

Present:
- Per-dimension scores (with skill vs without skill)
- Overall delta (positive = skill helps, negative = skill hurts)
- Interpretation: Excellent (delta >= 2.0), Good (>= 1.0), Marginal (>= 0.3), Neutral (> -0.3), Negative (<= -0.3)
- Judge notes summarizing key differences observed
