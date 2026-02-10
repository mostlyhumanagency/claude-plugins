# coding-with-arktype

Claude Code plugin for ArkType validation — 6 skills, 3 agents, 3 commands, 2 scripts, and 5 templates covering schemas, morphs, scopes, errors, integrations, and migration.

## Skills

| Skill | Description |
|---|---|
| `coding-arktype` | Router — overview and routing to subskills |
| `coding-arktype-schemas` | Defining types, objects, unions, constraints, keywords |
| `coding-arktype-morphs` | Pipes, transforms, `.to()`, `.narrow()`, parse keywords |
| `coding-arktype-scopes` | Scopes, modules, recursive types, generics |
| `coding-arktype-errors` | Error handling, custom messages, traversal API, ArkErrors reference |
| `coding-arktype-integrations` | tRPC, Drizzle, RHF, Hono, Standard Schema, match, declare, ArkEnv |

## Agents

| Agent | Model | Description |
|---|---|---|
| `arktype-expert` | opus | Full-featured ArkType expert with access to all skills |
| `arktype-error-debugger` | sonnet | Diagnose validation errors, type errors, and inference issues |
| `arktype-migration-assistant` | sonnet | Migrate from Zod, Yup, Joi, or io-ts to ArkType |

## Commands

| Command | Description |
|---|---|
| `/arktype-doctor` | Audit ArkType usage patterns: find common mistakes, anti-patterns, misconfigurations |
| `/arktype-migrate` | Analyze Zod/Yup/Joi schemas in project and suggest ArkType equivalents |
| `/arktype-check` | Validate ArkType type definitions compile correctly and check for inference issues |

## Scripts

| Script | Description |
|---|---|
| `find-arktype-usage.sh` | Scan project for ArkType API usage and report stats |
| `check-arktype-patterns.sh` | Detect common ArkType anti-patterns |

## Templates

| Template | Description |
|---|---|
| `arktype-validators.ts` | Common validator patterns — strings, numbers, objects, arrays, morphs, brands |
| `arktype-scope.ts` | Scope definition with shared types, cyclic types, private aliases |
| `arktype-express-validation.ts` | Express middleware for ArkType request validation |
| `arktype-hono-validation.ts` | Hono integration with @hono/arktype-validator |
| `arktype-fastify-validation.ts` | Fastify plugin for ArkType request validation |

## Installation

```sh
claude plugin add mostlyhumanagency/claude-plugins --path plugins/coding-with-arktype
```
