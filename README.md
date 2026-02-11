# claude-plugins

Claude Code plugin monorepo by [Mostly Human Agency](https://mostlyhuman.agency).

## Plugins

| Plugin | Description | Type |
|---|---|---|
| [coding-with-arktype](plugins/coding-with-arktype) | ArkType — 6 skills, 3 agents, 3 commands covering schemas, morphs, scopes, errors, integrations, and migration | Skills + Agents + Commands |
| [coding-with-liftkit](plugins/coding-with-liftkit) | LiftKit UI — 10 skills, 4 agents, 4 commands covering golden-ratio design, materials, components, theming | Skills + Agents + Commands |
| [coding-with-node](plugins/coding-with-node) | Node.js v24 — 19 skills, 4 agents, 4 commands covering runtime, async, streams, modules, testing, crypto, security, and more | Skills + Agents + Commands |
| [coding-with-react](plugins/coding-with-react) | React 18/19 — 10 skills, 4 agents, 4 commands covering actions, server components, streaming SSR, compiler, transitions, error boundaries, patterns, testing | Skills + Agents + Commands |
| [coding-with-typescript](plugins/coding-with-typescript) | TypeScript — 25 skills, 2 agents, 5 commands covering core patterns, async, generics, narrowing, validation, linting, tooling | Skills + Agents + Commands |
| [claude-skill-scholar](plugins/claude-skill-scholar) | Research, produce, test, evaluate, and maintain Claude Code skills — 5 skills, 5 agents, 6 commands | Skills + Agents + Commands |
| [typescript-7-lsp-hooks](plugins/typescript-7-lsp-hooks) | TypeScript diagnostics via tsgo (TS 7) LSP server | Hooks |
| [coding-with-astro](plugins/coding-with-astro) | Astro 5/6 — 17 skills, 2 agents, 2 commands covering components, routing, content collections, SSR, actions, middleware, sessions, view transitions, endpoints, Astro DB | Skills + Agents + Commands |
| [using-google-gemini-apis](plugins/using-google-gemini-apis) | Google Gemini APIs — 7 skills, 2 agents, 2 commands covering Live API streaming, Veo video generation, Nano Banana image generation | Skills + Agents + Commands |
| [using-gmail-with-gog-cli](plugins/using-gmail-with-gog-cli) | Gmail via the gog CLI — 3 skills, 1 agent covering auth setup, searching, reading messages | Skills + Agent |
| [using-google-cloud-console](plugins/using-google-cloud-console) | Google Cloud Console via Chrome — 4 skills, 1 agent covering projects, APIs, OAuth | Skills + Agent |

## Installation

Install individual plugins from this monorepo:

```sh
claude plugin add mostlyhumanagency/claude-plugins --path plugins/<plugin-name>
```

## License

MIT
