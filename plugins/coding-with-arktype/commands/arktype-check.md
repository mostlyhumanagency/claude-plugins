---
description: "Validate ArkType type definitions compile correctly and check for inference issues"
---

# arktype-check

Validate that all ArkType type definitions in the project compile correctly and check for common inference issues that degrade developer experience or cause build failures.

## Process

1. Find all files containing ArkType `type()`, `scope()`, or `match()` definitions
2. Run `tsc --noEmit` to check for TypeScript errors in those files
3. For any errors found, read the failing code and explain the root cause
4. Check for common inference issues: overly complex types causing "type instantiation is excessively deep", missing generics constraints
5. Suggest concrete fixes for each issue found
6. Summarize: files checked, errors found, fixes suggested
