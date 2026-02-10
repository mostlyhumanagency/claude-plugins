---
description: Analyze strict flag adoption and suggest a migration order
---

# ts-strict

Analyze the project's `tsconfig.json` for strict-family flags, run `tsc --noEmit` with each flag individually, count the resulting errors, and recommend a migration order from fewest to most errors.

## Process

1. Read `tsconfig.json` and identify which strict flags are currently enabled
2. Define the strict flag set: `strictNullChecks`, `strictFunctionTypes`, `strictBindCallApply`, `strictPropertyInitialization`, `noImplicitAny`, `noImplicitThis`, `useUnknownInCatchVariables`, `alwaysStrict`
3. For each flag not already enabled, run `npx tsc --noEmit --pretty false --strict false --<flag> true` and count errors
4. Present a table: flag name, error count, sample error
5. Recommend enabling flags in order from fewest errors to most
6. For each flag, briefly explain what it enforces and common patterns to fix
