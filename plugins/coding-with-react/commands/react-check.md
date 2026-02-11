---
description: "Scan React code for common anti-patterns: missing keys, stale closures, useEffect misuse, prop drilling"
---

# react-check

Scan React code for common anti-patterns and mistakes that lead to bugs, performance issues, or maintainability problems.

## Process

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-react-patterns.sh` to detect anti-patterns
2. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-bundle-imports.sh` to find barrel imports
3. Scan for prop drilling (same prop passed through 3+ component levels)
4. Check for common hook mistakes (deps arrays, conditional hooks, async effects)
5. Look for direct DOM manipulation (document.getElementById, querySelector in components)
6. Check for proper error boundary coverage on route boundaries
7. Report findings by severity and category
8. Suggest specific fixes for each finding
