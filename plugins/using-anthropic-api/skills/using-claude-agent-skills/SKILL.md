---
name: using-claude-agent-skills
description: "Use when building or using Claude Agent Skills via the API, generating PowerPoint/Excel/Word/PDF files, creating custom skills with SKILL.md, calling Skills API endpoints, configuring container.skills, or handling pause_turn for long-running operations. Also use for 'missing code execution tool' errors, skill version management, packaging domain expertise as reusable skills, or extending Claude with custom capabilities."
---

# Using Claude Agent Skills

## Overview

Agent skills are modular, filesystem-based capability packages that extend Claude with domain-specific expertise. They use progressive disclosure -- lightweight metadata loads at startup, full instructions load on-demand, and bundled resources are accessed only as needed. Skills work across the API, Claude Code, Agent SDK, and claude.ai.

## When to Use

- Generating Office documents (PPTX, XLSX, DOCX, PDF) with pre-built skills
- Packaging reusable domain expertise (company templates, analysis workflows)
- Having Claude execute bundled scripts deterministically without generating code fresh
- Progressive context loading for large reference material
- Managing custom skills via the Skills API (create, version, delete)

## When Not to Use

- One-off prompts that do not benefit from reusable instructions
- Tasks needing real-time network access (API skill containers have no internet)
- Simple text generation that does not need code execution or file output
- Use `using-claude-built-in-tools` for standalone bash, code execution, computer use, or text editor
- Use `implementing-claude-tool-use` for defining your own custom tools

## Core Patterns

### Using Pre-built Skills (Document Generation)

Specify the skill in `container.skills`, enable code execution, and Claude handles everything -- loading the skill, running code in a sandbox, and producing the file.

Beta headers required: `code-execution-2025-08-25`, `skills-2025-10-02`. Add `files-api-2025-04-14` for file downloads.

```bash
# Step 1: Generate a PowerPoint presentation
RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: code-execution-2025-08-25,skills-2025-10-02" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 4096,
    "container": {
      "skills": [{
        "type": "anthropic",
        "skill_id": "pptx",
        "version": "latest"
      }]
    },
    "messages": [{
      "role": "user",
      "content": "Create a 5-slide presentation about renewable energy trends"
    }],
    "tools": [{
      "type": "code_execution_20250825",
      "name": "code_execution"
    }]
  }')

# Step 2: Download the generated file
FILE_ID=$(echo "$RESPONSE" | jq -r '
  .content[]
  | select(.type=="bash_code_execution_tool_result")
  | .content
  | select(.type=="bash_code_execution_result")
  | .content[]
  | select(.file_id)
  | .file_id')

curl -s "https://api.anthropic.com/v1/files/$FILE_ID/content" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: files-api-2025-04-14" \
  --output presentation.pptx
```

Available pre-built skills: `pptx`, `xlsx`, `docx`, `pdf`. All use `type: "anthropic"`. Combine up to 8 skills in a single request. Pin to a specific version (`"version": "20251013"`) for production stability.

### Creating Custom Skills

Package domain-specific expertise so Claude can reuse it across conversations without re-prompting.

```bash
# Step 1: Create the skill via Skills API
SKILL_RESPONSE=$(curl -s -X POST "https://api.anthropic.com/v1/skills" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02" \
  -F "display_title=Financial Analysis" \
  -F "files[]=@my_skill/SKILL.md;filename=my_skill/SKILL.md" \
  -F "files[]=@my_skill/analyze.py;filename=my_skill/analyze.py")

SKILL_ID=$(echo "$SKILL_RESPONSE" | jq -r '.id')

# Step 2: Use the custom skill in a message
curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: code-execution-2025-08-25,skills-2025-10-02" \
  -H "content-type: application/json" \
  -d "{
    \"model\": \"claude-sonnet-4-5-20250929\",
    \"max_tokens\": 4096,
    \"container\": {
      \"skills\": [{
        \"type\": \"custom\",
        \"skill_id\": \"$SKILL_ID\",
        \"version\": \"latest\"
      }]
    },
    \"messages\": [{
      \"role\": \"user\",
      \"content\": \"Run the financial analysis on our Q4 data\"
    }],
    \"tools\": [{
      \"type\": \"code_execution_20250825\",
      \"name\": \"code_execution\"
    }]
  }"
```

### SKILL.md Structure

Every skill requires a `SKILL.md` file with YAML frontmatter:

```yaml
---
name: financial-analysis
description: Analyze financial data using DCF models and generate reports. Use when the user mentions financial analysis, valuation, or DCF.
---

# Financial Analysis Skill

## Quick Start
Run `python /skills/my_skill/analyze.py <input_file>` to process financial data.

## Workflow
1. Load the input CSV or Excel file
2. Run DCF valuation using analyze.py
3. Generate a summary report

For detailed API reference, see [REFERENCE.md](REFERENCE.md).
```

Name must be lowercase with hyphens only. Do not use "anthropic" or "claude" in the name. Maximum 8 MB total upload size.

### Handling pause_turn

Skills that take multiple execution rounds return `stop_reason: "pause_turn"`. Loop and continue the conversation, passing the container ID.

```bash
RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: code-execution-2025-08-25,skills-2025-10-02" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 4096,
    "container": {
      "skills": [{"type": "anthropic", "skill_id": "xlsx", "version": "latest"}]
    },
    "messages": [{"role": "user", "content": "Process this large dataset"}],
    "tools": [{"type": "code_execution_20250825", "name": "code_execution"}]
  }')

STOP_REASON=$(echo "$RESPONSE" | jq -r '.stop_reason')
CONTAINER_ID=$(echo "$RESPONSE" | jq -r '.container.id')

while [ "$STOP_REASON" = "pause_turn" ]; do
  # Feed assistant content back and continue with same container
  RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "anthropic-beta: code-execution-2025-08-25,skills-2025-10-02" \
    -H "content-type: application/json" \
    -d "{
      \"model\": \"claude-sonnet-4-5-20250929\",
      \"max_tokens\": 4096,
      \"container\": {
        \"id\": \"$CONTAINER_ID\",
        \"skills\": [{\"type\": \"anthropic\", \"skill_id\": \"xlsx\", \"version\": \"latest\"}]
      },
      \"messages\": [... full conversation history ...],
      \"tools\": [{\"type\": \"code_execution_20250825\", \"name\": \"code_execution\"}]
    }")
  STOP_REASON=$(echo "$RESPONSE" | jq -r '.stop_reason')
done
```

### Skills API Endpoints

Manage skills programmatically with CRUD operations:

```bash
# List all skills
curl -s "https://api.anthropic.com/v1/skills" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02"

# List pre-built skills only
curl -s "https://api.anthropic.com/v1/skills?source=anthropic" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02"

# Get skill details
curl -s "https://api.anthropic.com/v1/skills/$SKILL_ID" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02"

# Create new version
curl -s -X POST "https://api.anthropic.com/v1/skills/$SKILL_ID/versions" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02" \
  -F "files[]=@updated/SKILL.md;filename=my_skill/SKILL.md"

# Delete version (must delete all versions before deleting a skill)
curl -s -X DELETE "https://api.anthropic.com/v1/skills/$SKILL_ID/versions/$VERSION" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02"

# Delete skill
curl -s -X DELETE "https://api.anthropic.com/v1/skills/$SKILL_ID" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02"
```

## Quick Reference

| Feature | Endpoint / Config | Notes |
|---|---|---|
| List skills | `GET /v1/skills` | Filter: `?source=anthropic` or `?source=custom` |
| Create skill | `POST /v1/skills` | Multipart upload; must include SKILL.md. Max 8 MB |
| Get skill | `GET /v1/skills/{skill_id}` | Returns metadata + latest version |
| Delete skill | `DELETE /v1/skills/{skill_id}` | Must delete all versions first |
| Create version | `POST /v1/skills/{skill_id}/versions` | Auto-generated epoch timestamp |
| Delete version | `DELETE /v1/skills/{skill_id}/versions/{version}` | |
| Use in Messages | `container.skills[]` in `POST /v1/messages` | Up to 8 skills per request |
| Pre-built skills | `pptx`, `xlsx`, `docx`, `pdf` | `type: "anthropic"` |
| Custom skills | `skill_01Abc...` | `type: "custom"`, workspace-scoped |
| Required betas | All requests | `code-execution-2025-08-25`, `skills-2025-10-02` |
| Download files | `GET /v1/files/{file_id}/content` | Beta: `files-api-2025-04-14` |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Missing code execution tool | 400 error or skill not triggered | Always include `{"type": "code_execution_20250825", "name": "code_execution"}` in `tools` |
| Missing beta headers | 400 or features unavailable | Include `code-execution-2025-08-25` and `skills-2025-10-02`. Add `files-api-2025-04-14` for downloads |
| Not handling `pause_turn` | Incomplete results | Loop on `stop_reason === "pause_turn"`, feed assistant content back |
| Including unused skills | Slower responses, wasted tokens | Only include skills relevant to the task |
| Changing skills list between cached requests | Prompt cache misses | Keep `container.skills` consistent for prompt caching |
| Deleting skill before versions | 400 error | Delete all versions first |
| SKILL.md name with uppercase or reserved words | Upload rejected | Lowercase, hyphens only, no "anthropic" or "claude" |
| Expecting network in skill containers | Scripts fail | No network access; bundle all resources locally |

## References

- [Agent skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [Agent skills quickstart](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/quickstart)
- [Skills guide](https://platform.claude.com/docs/en/build-with-claude/skills-guide)
