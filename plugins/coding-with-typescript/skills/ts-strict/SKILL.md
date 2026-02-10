---
name: ts-strict
description: "This skill should be used when the user asks to 'enable strict mode', 'migrate to strict TypeScript', 'add strictNullChecks', or wants to incrementally adopt TypeScript strict flags. Applies when the user wants to understand the cost of each strict flag and plan a gradual migration."
---

# TypeScript Strict Mode Migration

## Overview

This skill guides incremental adoption of TypeScript's strict-family compiler flags. Rather than flipping `"strict": true` and facing hundreds of errors at once, this skill runs the compiler with each individual strict flag in isolation, counts the resulting errors, and recommends an adoption order from the least disruptive flag to the most. This gives the developer a data-driven migration plan they can execute flag by flag, with manageable pull requests at each step.

The `"strict": true` flag in tsconfig is an umbrella that enables multiple individual flags. Each flag addresses a different class of type-safety issue. Enabling them one at a time lets a team build confidence incrementally while keeping each change reviewable.

## When to Use

Use this skill when:

- The user asks to "enable strict mode", "migrate to strict", "turn on strictNullChecks", or similar
- The user wants to know how many errors each strict flag would introduce
- The user is starting a new TypeScript project and wants guidance on which flags to enable
- The user has `"strict": false` or no strict flag and wants to understand the gap
- The user asks "how far are we from strict mode" or "what would strict mode break"
- The user wants to adopt a single strict flag and needs to understand what it enforces

Do not use this skill for general tsconfig auditing (use ts-doctor instead) or for fixing individual type errors (use ts-check instead).

## Process

Follow these steps to analyze and plan a strict mode migration:

1. **Read the current config.** Open `tsconfig.json` and resolve any `extends` chains. Record which strict-family flags are currently enabled, either individually or via `"strict": true`.

2. **Identify the strict flag set.** The complete set of flags enabled by `"strict": true` is:
   - `alwaysStrict` -- emits `"use strict"` in every file
   - `strictNullChecks` -- `null` and `undefined` are distinct types
   - `strictFunctionTypes` -- function parameter types are checked contravariantly
   - `strictBindCallApply` -- `bind`, `call`, `apply` are strongly typed
   - `strictPropertyInitialization` -- class properties must be initialized (requires `strictNullChecks`)
   - `noImplicitAny` -- error on expressions with implied `any` type
   - `noImplicitThis` -- error on `this` expressions with implied `any` type
   - `useUnknownInCatchVariables` -- catch clause variables are `unknown` instead of `any`

3. **Determine which flags are missing.** Compare the current config against the full set. If `"strict": true` is already set, report that all flags are enabled and no migration is needed.

4. **Test each missing flag individually.** For each flag not yet enabled, run `npx tsc --noEmit --pretty false` with a temporary config that adds only that flag. Count the resulting errors. Record one or two sample error messages for context.

   When running these checks, be aware that `strictPropertyInitialization` depends on `strictNullChecks`. If `strictNullChecks` is not yet enabled, test `strictPropertyInitialization` with both flags together and note this dependency.

5. **Build the migration table.** Present a table sorted by error count ascending:

   | Flag | Error Count | Sample Error | Effort |
   |---|---|---|---|
   | `alwaysStrict` | 0 | -- | Trivial |
   | `strictBindCallApply` | 3 | TS2769: No overload matches | Low |
   | ... | ... | ... | ... |

   Rate effort as: Trivial (0-5 errors), Low (6-20), Medium (21-100), High (100+).

6. **Recommend the migration order.** Suggest enabling flags from fewest errors to most. For each flag, explain:
   - What category of bugs it catches
   - The typical fix patterns (e.g., for `strictNullChecks`: add null guards, use optional chaining, narrow with `if` checks)
   - Any flags that depend on others (`strictPropertyInitialization` requires `strictNullChecks`)

7. **Provide a timeline suggestion.** For teams, suggest one flag per sprint or per week, starting with the trivial ones to build momentum. For solo developers, they can often tackle all flags in a single session if error counts are manageable.

8. **Generate the target tsconfig.** Show what the final `tsconfig.json` should look like with `"strict": true` replacing all the individual flags.

## Quick Reference

| Scenario | Action |
|---|---|
| User says "enable strict mode" | Analyze all flags, show error counts, recommend order |
| User asks about a specific flag (e.g., "add strictNullChecks") | Test that one flag, show errors, explain fix patterns |
| `"strict": true` already set | Report all flags active, check for overrides like `"strictNullChecks": false` |
| Hundreds of errors on one flag | Suggest file-by-file migration or `// @ts-expect-error` as temporary bridge |
| `strictPropertyInitialization` tested alone | Always test with `strictNullChecks` too since it is a dependency |
| User wants to stay non-strict | Respect the choice; suggest the highest-value individual flags instead |

## Common Mistakes

- **Testing `strictPropertyInitialization` without `strictNullChecks`.** The former depends on the latter. If tested alone without `strictNullChecks`, the error count will be misleadingly low because the compiler cannot fully check property initialization without understanding null/undefined.

- **Forgetting about `extends` overrides.** A tsconfig may extend a base that sets `"strict": true` but then override individual flags to `false`. Always resolve the full effective configuration before deciding which flags are missing.

- **Recommending `// @ts-ignore` to suppress errors.** Use `// @ts-expect-error` instead, which will itself error if the underlying issue is fixed, acting as a reminder to clean up. But even this should be temporary, not a permanent migration strategy.

- **Not accounting for test files.** Test files often have looser typing. If the project uses separate tsconfigs for source and tests, run the analysis against each config separately and present both results.

- **Enabling all flags at once in a large codebase.** The entire point of this skill is incremental migration. Even if the user asks to "just enable strict", push back and show the error counts first. A 500-error pull request is unlikely to be reviewed well.
