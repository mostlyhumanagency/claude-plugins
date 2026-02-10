# claude-plugins

Claude Code plugin monorepo by [Mostly Human Agency](https://mostlyhuman.agency).

## Plugins

| Plugin | Description | Type |
|---|---|---|
| [coding-with-arktype](plugins/coding-with-arktype) | ArkType — schemas, morphs, scopes, errors, integrations | Skills + Agent |
| [coding-with-liftkit](plugins/coding-with-liftkit) | LiftKit UI — golden-ratio design, materials, components, theming | Skills + Agent |
| [coding-with-node](plugins/coding-with-node) | Node.js v24 — core runtime, async, streams, modules, testing, web APIs | Skills + Agent |
| [coding-with-react](plugins/coding-with-react) | React — actions, server components, streaming SSR, compiler, patterns, testing | Skills + Agent |
| [coding-with-typescript](plugins/coding-with-typescript) | TypeScript — core patterns, async, generics, narrowing, validation, linting, tooling | Skills + Agents + Commands |
| [learning-skill](plugins/learning-skill) | Research a technology and produce scoped Claude Code skills | Skills + Agent + Command |
| [typescript-7-lsp-hooks](plugins/typescript-7-lsp-hooks) | TypeScript diagnostics via tsgo (TS 7) LSP server | Hooks |
| [using-gmail-with-gog-cli](plugins/using-gmail-with-gog-cli) | Gmail via the gog CLI — auth setup, searching, reading messages | Skills + Agent |
| [using-google-cloud-console](plugins/using-google-cloud-console) | Google Cloud Console via Chrome — projects, APIs, OAuth | Skills + Agent |

## Installation

Install individual plugins from this monorepo:

```sh
claude plugin add mostlyhumanagency/claude-plugins --path plugins/<plugin-name>
```

## License

MIT
