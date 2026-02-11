---
description: "Analyze and migrate a React project to modern React 19 patterns"
---

# react-migrate

Analyze an existing React project and generate a migration plan to modern React 19 patterns, with file-by-file guided changes.

## Process

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/find-class-components.sh` to find class components
2. Run `${CLAUDE_PLUGIN_ROOT}/scripts/find-deprecated-apis.sh` to find deprecated APIs
3. Scan for legacy patterns: forwardRef, Context.Provider, defaultProps on functions, PropTypes
4. Check for react-helmet usage (replaceable with native metadata)
5. Identify manual memoization that React Compiler could handle
6. Generate migration report: total findings by category, priority ranking
7. Prioritize: deprecated APIs > class components > legacy patterns > optimization opportunities
8. Offer to apply changes file-by-file with user confirmation
