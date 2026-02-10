# skill-coding-react

A Claude Code plugin for building modern React applications — actions, server components, streaming SSR, compiler, patterns, and testing.

## Skills

| Skill | Description |
|---|---|
| `coding-react` | Router — routes to the most specific React subskill |
| `using-react-actions` | useActionState, useFormStatus, useOptimistic for forms and async actions |
| `using-react-use-api` | `use()` API for reading Promises and Context with Suspense |
| `using-react-server-components` | Server Components, Client Components, Server Actions, directives |
| `using-react-compiler` | Automatic memoization at build time via React Compiler |
| `using-react-ssr-streaming` | Streaming SSR, renderToPipeableStream, prerender, Partial Pre-rendering |
| `using-react-patterns` | Ref as prop, Context provider, metadata, Activity, useEffectEvent, resource preloading |
| `testing-react` | Testing with Vitest and React Testing Library |

## Installation

### As a plugin (recommended)

```sh
/plugin marketplace add mostlyhumanagency/skill-coding-react
```

### Manual

Symlink each skill directory into `~/.claude/skills/`:

```sh
git clone <repo-url>
for skill in skills/coding-react skills/using-react-* skills/testing-react; do
  ln -s "$(pwd)/$skill" ~/.claude/skills/$(basename "$skill")
done
```
