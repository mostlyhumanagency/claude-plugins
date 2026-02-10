---
description: Run TypeScript type checking and explain any errors found
---

# ts-check

Run `tsc --noEmit` against the project to type-check without emitting output. Parse the compiler output, group errors by file, and explain each error with a suggested fix.

## Process

1. Locate the nearest `tsconfig.json` from the working directory
2. Run `npx tsc --noEmit --pretty false` to get machine-parseable output
3. If the exit code is 0, report that type checking passed with no errors
4. If there are errors, parse each line in the format `file(line,col): error TSxxxx: message`
5. Group errors by file path
6. For each error, explain what the error code means and suggest a concrete fix
7. Summarize: total error count, files affected, and the most common error codes
