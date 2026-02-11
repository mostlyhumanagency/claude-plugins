---
description: "Audit React project health: package versions, dependencies, deprecated patterns, and configuration"
---

# react-doctor

Audit the health of a React project by checking package versions, dependencies, deprecated pattern usage, and configuration issues.

## Process

1. Read package.json and check react/react-dom versions for compatibility and currency
2. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-react-setup.sh` to validate project configuration
3. Run `${CLAUDE_PLUGIN_ROOT}/scripts/find-deprecated-apis.sh` to find deprecated API usage
4. Check for required peer dependencies (react-dom version matching react version)
5. Validate tsconfig.json for React (jsx setting, moduleResolution)
6. Check for outdated patterns (class components, legacy context, string refs)
7. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-react-patterns.sh` to find anti-patterns
8. Report findings with severity (error, warning, info) and suggested fixes
9. Summarize: total issues, health score, top priorities
