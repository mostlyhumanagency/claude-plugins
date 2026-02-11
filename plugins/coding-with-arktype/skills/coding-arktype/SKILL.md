---
name: coding-arktype
description: "Use when validating data, defining schemas, parsing inputs, or enforcing types at runtime with ArkType — covers type definitions, morphs/transforms, scopes, error handling, and integration with tRPC, Drizzle, React Hook Form. Routes to the specific subskill."
---

# Using ArkType

ArkType is TypeScript's 1:1 validator — define types using TS-like syntax, validate at runtime. 20x faster than Zod.

## Subskills

| Skill | Use when... |
|---|---|
| `coding-arktype-schemas` | Defining types, objects, arrays, tuples, constraints, keywords |
| `coding-arktype-morphs` | Transforming data: pipes, morphs, `.to()`, `.narrow()`, parse keywords |
| `coding-arktype-scopes` | Creating scopes, modules, cyclic types, generics, submodules |
| `coding-arktype-errors` | Handling validation errors, traversal API, custom error messages, configuration |
| `coding-arktype-integrations` | Using ArkType with tRPC, Drizzle, React Hook Form, Hono, match API, JSON Schema |

## Setup

```bash
pnpm install arktype
```

**Requires:** TypeScript >= 5.1, `"type": "module"` in package.json, `strict` or `strictNullChecks` in tsconfig.

**Recommended tsconfig:** `skipLibCheck: true`, `exactOptionalPropertyTypes: true`

**VSCode:** Enable `"editor.quickSuggestions.strings": "on"` for in-string autocomplete. Install ArkDark extension for syntax highlighting.
