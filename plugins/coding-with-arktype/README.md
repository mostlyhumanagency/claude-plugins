# skill-coding-arktype

A Claude Code plugin for validating data with ArkType — schemas, morphs, scopes, errors, and integrations.

## Skills

| Skill | Description |
|---|---|
| `coding-arktype` | Router — overview and routing to subskills |
| `coding-arktype-schemas` | Defining types, objects, unions, constraints, keywords |
| `coding-arktype-morphs` | Pipes, transforms, `.to()`, `.narrow()`, parse keywords |
| `coding-arktype-scopes` | Scopes, modules, recursive types, generics |
| `coding-arktype-errors` | Error handling, custom messages, traversal API |
| `coding-arktype-integrations` | tRPC, Drizzle, RHF, Hono, Standard Schema |

## Installation

### As a plugin (recommended)

```sh
/plugin marketplace add mostlyhumanagency/coding-arktype
```

### Manual

Symlink each skill directory into `~/.claude/skills/`:

```sh
git clone <repo-url>
for skill in skills/coding-arktype*; do
  ln -s "$(pwd)/$skill" ~/.claude/skills/$(basename "$skill")
done
```
