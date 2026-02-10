---
name: coding-arktype
description: Use when a user wants an overview of ArkType skills or when unsure which ArkType subskill applies. Routes to the most specific ArkType skill.
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
