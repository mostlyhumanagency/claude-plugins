---
description: "Audit ArkType usage patterns: find common mistakes, anti-patterns, and misconfigurations"
---

# arktype-doctor

Audit ArkType usage patterns across the project to find common mistakes, anti-patterns, and misconfigurations that could cause runtime errors or degrade type safety.

## Process

1. Scan the project for ArkType imports and usage of `type()`, `scope()`, and `match()` calls
2. Check for common mistakes: `type()` calls wrapped inside `scope()` definitions, types recreated inside functions instead of at module level, missing error handling on `.assert()` calls
3. Check `tsconfig.json` for required settings (`strict: true`, `skipLibCheck: true`)
4. Check for deprecated patterns or API usage from older ArkType versions
5. Verify the ArkType version in `package.json` and flag if outdated
6. Report findings with severity (error, warning, info) and suggested fixes
7. Summarize: total issues, health score, top priorities
