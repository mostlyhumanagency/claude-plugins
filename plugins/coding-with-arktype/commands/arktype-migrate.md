---
description: "Analyze Zod/Yup/Joi schemas in project and suggest ArkType equivalents"
argument-hint: <library>
---

# arktype-migrate

Analyze existing validation schemas from Zod, Yup, Joi, or io-ts in the project and produce equivalent ArkType definitions with a step-by-step migration plan. Optionally pass a library name to target; otherwise auto-detects.

## Process

1. If `$ARGUMENTS` specifies a library, use it; otherwise auto-detect by checking `package.json` dependencies for zod, yup, joi, io-ts
2. Scan the project for schema definitions from the detected library
3. For each schema found, produce the ArkType equivalent with before/after code
4. Flag schemas that need special attention (complex transforms, custom validators, runtime-only features)
5. Estimate migration complexity (simple, moderate, complex) per file
6. Produce a migration plan ordered by dependency (shared schemas first, then consumers)
7. Summarize: total schemas found, estimated effort, recommended approach
