---
description: Audit tsconfig.json against best practices for your framework
---

# ts-doctor

Read the project's `tsconfig.json`, detect the framework in use (Next.js, Vite, Node, etc.), and audit the configuration against recommended settings for that framework. Flag misconfigurations and suggest fixes.

## Process

1. Read `tsconfig.json` (and any extended configs via `extends`)
2. Detect the framework by inspecting `package.json` dependencies (next, vite, @angular/core, etc.)
3. Compare each compiler option against the recommended settings for the detected framework
4. Check for common misconfigurations:
   - `module` / `moduleResolution` mismatch
   - Missing `skipLibCheck` in large projects
   - `outDir` pointing inside `src`
   - `include`/`exclude` patterns that miss or over-include files
   - `paths` aliases without corresponding bundler/runtime config
   - Deprecated or no-op options for the current TS version
5. Report each finding with severity (error, warning, info), the current value, and the recommended value
6. Provide a corrected `tsconfig.json` snippet if changes are needed
