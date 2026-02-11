---
name: ts-check
description: "Use when running a full project type-check, verifying TypeScript compiles without errors, analyzing multiple type errors at once, checking project health before a release, or when the user asks to check types, run tsc, or verify the project compiles. Runs tsc --noEmit and explains all errors found."
---

# TypeScript Type Checking

## Overview

This skill performs a full project type-check by running the TypeScript compiler in `--noEmit` mode, then parses, groups, and explains every error found. It transforms raw compiler output into actionable, developer-friendly diagnostics. The goal is not just to surface errors but to help the developer understand what each error means, why it occurs, and how to fix it efficiently.

Type checking is the single most important feedback loop in a TypeScript project. Running it regularly catches regressions before they reach runtime. This skill automates the process of running the compiler and interpreting its output so the developer can focus on fixing issues rather than deciphering cryptic error messages.

## When to Use

Use this skill when:

- The user asks to "check types", "run tsc", "verify TypeScript compiles", or "type-check the project"
- The user encounters multiple type errors and wants them analyzed as a batch rather than one at a time
- The user wants a summary of project health from a type-safety perspective
- The user has made broad refactoring changes and needs to verify nothing is broken
- The user mentions error codes like TS2322, TS2345, TS7006, or similar and wants an overview of all occurrences
- The user wants to understand the difference between type errors and runtime errors in their project

Do not use this skill when the user is asking about a single, specific type error in a file they are already editing. In that case, address the error directly without running a full project check.

## Process

Follow these steps in order when performing a type check:

1. **Locate the tsconfig.** Find the nearest `tsconfig.json` relative to the working directory. If the project uses project references or multiple tsconfigs (e.g., `tsconfig.app.json`, `tsconfig.test.json`), identify which one covers the files the user cares about. If unclear, use the root `tsconfig.json`.

2. **Run the compiler.** Execute `npx tsc --noEmit --pretty false` using the identified tsconfig. The `--pretty false` flag ensures machine-parseable output with one error per line. If the project uses a specific TypeScript version via `devDependencies`, the `npx` invocation will use it automatically.

3. **Handle clean output.** If the exit code is 0 and there is no error output, report success. State how many files were checked if the `--listFiles` flag was used, or simply confirm that the project type-checks cleanly.

4. **Parse errors.** Each error line follows the format: `path/to/file.ts(line,col): error TSxxxx: message text`. Extract the file path, line number, column number, error code, and message from each line. Watch for multi-line error messages that continue on subsequent lines without the `error TS` prefix.

5. **Group by file.** Organize errors by file path. Within each file, sort errors by line number. This gives the developer a file-by-file view they can work through sequentially.

6. **Explain each error.** For every error, provide:
   - The error code and message
   - A plain-language explanation of what the compiler is complaining about
   - A concrete suggestion for how to fix it, referencing the specific types or values involved
   - If the error is a common pattern (e.g., TS2322 type mismatch, TS2345 argument type mismatch), note the general pattern so the developer recognizes it in the future

7. **Summarize.** After the file-by-file breakdown, provide a summary: total error count, number of files affected, the top 3 most frequent error codes, and whether the errors suggest a systemic issue (e.g., missing null checks across the board, incorrect module resolution).

8. **Suggest next steps.** If there are many errors, suggest prioritizing by error code or by file. If errors stem from a configuration issue, recommend fixing tsconfig first. If a specific library is causing most errors, suggest updating `@types` packages or checking version compatibility.

## Quick Reference

| Scenario | Action |
|---|---|
| User says "check types" or "run tsc" | Run `npx tsc --noEmit --pretty false`, parse and explain output |
| Zero errors | Report clean type check, confirm file coverage |
| Errors found | Group by file, explain each, summarize totals and patterns |
| Hundreds of errors | Summarize by error code frequency, suggest tackling most common first |
| Multiple tsconfigs | Ask which scope (app, test, etc.) or check the root config |
| Project uses `vue-tsc` or `svelte-check` | Use the framework-specific checker instead of plain `tsc` |
| Errors reference `node_modules` | Suggest `skipLibCheck: true` if not already set, or update `@types` |

## Common Mistakes

- **Running with `--pretty true` (the default) and trying to parse output.** The pretty-printed output includes ANSI color codes and formatted multi-line messages that are difficult to parse reliably. Always use `--pretty false` for machine-readable output.

- **Ignoring extended tsconfigs.** Many projects extend a base config (e.g., `@tsconfig/node20`). Errors may come from options inherited through `extends`. Always resolve the full effective config before diagnosing configuration-related errors.

- **Conflating type errors with lint errors.** TypeScript type errors (TSxxxx codes) come from the compiler. ESLint TypeScript rules (e.g., `@typescript-eslint/no-explicit-any`) are separate. Do not mix them in the same report. This skill covers only compiler type errors.

- **Suggesting `any` as a fix.** Using `any` silences errors but defeats the purpose of type checking. Always suggest proper type annotations, type guards, or type assertions with explanation rather than falling back to `any`.

- **Not checking the TypeScript version.** Some error codes or behaviors changed between TS versions. If an error seems unusual, verify which TypeScript version the project uses (`npx tsc --version`) and note any version-specific behavior.
