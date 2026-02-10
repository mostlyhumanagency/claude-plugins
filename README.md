# claude-plugins

Claude Code plugin marketplace by [Mostly Human Agency](https://mostlyhuman.agency).

## Plugins

| Plugin | Description | Type |
|---|---|---|
| [coding-typescript](https://github.com/mostlyhumanagency/claude-plugin-coding-typescript) | TypeScript — core patterns, async, generics, narrowing, validation, tooling | Skills |
| [coding-react](https://github.com/mostlyhumanagency/claude-plugin-coding-react) | React — actions, server components, streaming SSR, compiler, patterns, testing | Skills |
| [coding-node](https://github.com/mostlyhumanagency/claude-plugin-coding-node) | Node.js v24 — core runtime, async, streams, modules, testing, web APIs | Skills |
| [coding-arktype](https://github.com/mostlyhumanagency/claude-plugin-coding-arktype) | ArkType — schemas, morphs, scopes, errors, integrations | Skills |
| [learning-topic](https://github.com/mostlyhumanagency/claude-plugin-learning-topic) | Research a technology and produce scoped Claude Code skills from it | Skills |
| [using-gmail](https://github.com/mostlyhumanagency/claude-plugin-using-gmail) | Gmail via the gog CLI — auth setup, searching, reading messages | Skills |
| [using-google-cloud-console](https://github.com/mostlyhumanagency/claude-plugin-using-google-cloud-console) | Google Cloud Console via Chrome — projects, APIs, OAuth | Skills |
| [typescript-7-lsp](https://github.com/mostlyhumanagency/claude-plugin-typescript-7-lsp) | TypeScript diagnostics via tsgo LSP server | Hooks |

## Usage

Add the marketplace, then install individual plugins:

```sh
/plugin marketplace add mostlyhumanagency/claude-plugins
/plugin install coding-typescript@mostlyhumanagency
```

## License

MIT
