# claude-skill-scholar

Research, produce, test, evaluate, and maintain Claude Code skills — 5 skills, 5 agents, 6 commands, 7 scripts, and 12 templates for the full skill lifecycle.

## Skills

| Skill | Description |
|---|---|
| `skill-scholar-router` | Router skill — routes to the correct subskill based on the user's intent |
| `researching-topics-into-skills` | Core workflow — research a technology, decompose into skill units, produce plugin-ready skills |
| `maintaining-skills` | Update existing skills when upstream documentation changes — staleness detection, surgical updates |
| `publishing-skills` | Package skills into complete plugins — plugin.json, README, agents, commands, marketplace entry |
| `reviewing-skills` | Structured quality review — structural validation, content analysis, weighted grading rubric |

## Agents

| Agent | Model | Description |
|---|---|---|
| `skill-learner` | opus | Research and skill-generation specialist — drives the full 3-phase learning workflow |
| `skill-tester` | sonnet | Smoke-test skills by generating scenarios and running Claude CLI instances |
| `skill-evaluator` | sonnet | A/B evaluation — measure skill impact by comparing Claude with vs without the skill |
| `skill-quality-reviewer` | sonnet | Deep quality review with 6 weighted criteria and A-D grading rubric |
| `skill-maintainer` | sonnet | Update existing skills when documentation sources change |

## Commands

| Command | Description |
|---|---|
| `/learn` | Research a technology and produce Claude Code skills from it |
| `/test-skill` | Test a skill by running Claude CLI instances against generated scenarios |
| `/evaluate-skill` | Evaluate a skill's impact by running A/B comparison (with vs without skill) |
| `/review-skill` | Review a skill directory against the quality checklist |
| `/update-skill` | Refresh a skill from updated documentation sources |
| `/skill-inventory` | List all skills in a plugin with stats and validation status |

## Scripts

| Script | Description |
|---|---|
| `validate-skill.sh` | Basic structural validation (7 checks) |
| `review-skill.sh` | Enhanced quality review (23+ checks) with --deep, --fix, --plugin-dir flags |
| `test-skill.sh` | Smoke-test a skill via Claude CLI against generated scenarios |
| `evaluate-skill.sh` | A/B evaluation comparing Claude with vs without a skill |
| `diff-skill.sh` | Structured diff of two skill versions (directories or git refs) |
| `count-skills.sh` | Plugin inventory with word counts, ref counts, and stats |
| `generate-readme.sh` | Auto-generate README.md from plugin contents |

## Templates

| Template | Description |
|---|---|
| `researcher-prompt.md` | Subagent prompt for researching a skill topic |
| `skill-writer-prompt.md` | Subagent prompt for writing a skill from research notes |
| `source-discovery-prompt.md` | Subagent prompt for discovering documentation sources |
| `router-template.md` | Template for router skill SKILL.md |
| `source-manifest.md` | Source tracking with freshness dates |
| `SKILL.md.template` | Fill-in-the-blanks SKILL.md skeleton |
| `agent-template.md` | Standard agent definition skeleton |
| `command-template.md` | Standard command definition skeleton |
| `test-scenario-prompt.md` | Test scenario generation for skill testing |
| `evaluation-rubric.md` | A/B evaluation rubric with 5 scoring dimensions |
| `plugin-json-template.json` | Documented plugin.json with all fields |
| `quality-review-prompt.md` | Quality review subagent dispatch prompt |

## Installation

```sh
claude plugin add mostlyhumanagency/claude-plugins --path plugins/claude-skill-scholar
```
