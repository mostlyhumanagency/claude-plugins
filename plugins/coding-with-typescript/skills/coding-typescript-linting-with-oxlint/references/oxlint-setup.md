# oxlint Setup and Configuration

## What Is oxlint

oxlint is a Rust-based JavaScript/TypeScript linter from the OXC project, maintained by VoidZero. It reached v1.0 stable in June 2025.

Key characteristics:
- 50-100x faster than ESLint
- 660+ built-in rules covering correctness, suspicious, pedantic, perf, style, and restriction categories
- Zero configuration to start (ships with sensible `correctness` defaults)
- No plugin ecosystem (rules are compiled into the binary in Rust)
- Supports type-aware linting via tsgolint (Go-based, uses TypeScript 7 / tsgo)
- Used by Shopify, Airbnb, Mercedes-Benz

## Installation

```bash
# npm
npm install --save-dev oxlint

# pnpm
pnpm add --save-dev oxlint

# yarn
yarn add --dev oxlint
```

No additional plugins or parsers needed. oxlint understands TypeScript natively.

## Basic Usage

```bash
# Lint the current directory with default rules (correctness category)
npx oxlint .

# Lint specific directories
npx oxlint src/ tests/

# Generate a starter config
npx oxlint --init
```

## Configuration (oxlintrc.json)

oxlint looks for `.oxlintrc.json` in the working directory. The format uses JSON with comments (JSONC) and is compatible with ESLint v8's eslintrc shape.

### Minimal Config

```json
{
  "$schema": "./node_modules/oxlint/configuration_schema.json",
  "categories": {
    "correctness": "warn"
  },
  "rules": {
    "no-unused-vars": "error"
  }
}
```

### Full Config Structure

```json
{
  "$schema": "./node_modules/oxlint/configuration_schema.json",
  "plugins": ["typescript", "unicorn", "oxc"],
  "categories": {
    "correctness": "error",
    "suspicious": "warn",
    "pedantic": "off"
  },
  "rules": {
    "no-console": "error",
    "typescript/no-explicit-any": "error",
    "no-plusplus": ["error", { "allowForLoopAfterthoughts": true }]
  },
  "overrides": [
    {
      "files": ["**/*.test.ts"],
      "rules": {
        "no-console": "off"
      }
    }
  ],
  "env": {
    "es6": true
  },
  "ignorePatterns": ["dist/", "build/"]
}
```

## Categories

Categories enable or disable groups of rules with similar intent. Default: only `correctness` is enabled.

| Category | Description | Default |
|---|---|---|
| `correctness` | Code that is definitely wrong or useless | Enabled |
| `suspicious` | Code that is most likely wrong or useless | Off |
| `pedantic` | Strict rules, may have false positives | Off |
| `perf` | Code that could be more performant | Off |
| `style` | Idiomatic code style | Off |
| `restriction` | Bans specific patterns or features | Off |
| `nursery` | Rules under development, may change | Off |

Enable categories in config or via CLI:

```bash
# Enable suspicious and pedantic via CLI
npx oxlint -D correctness -D suspicious -D pedantic
```

## Plugins

oxlint implements popular ESLint plugins natively in Rust. Enable them with the `plugins` field:

```json
{
  "plugins": ["typescript", "react", "unicorn", "import", "jsx-a11y", "nextjs", "jest", "vitest", "oxc"]
}
```

These are not npm packages; they are compiled into oxlint. The `plugins` field controls which rule namespaces are available.

## CLI Flags

| Flag | Description |
|---|---|
| `-D <rule>` | Deny (error) a rule or category |
| `-W <rule>` | Warn on a rule or category |
| `-A <rule>` | Allow (disable) a rule or category |
| `-c <path>` | Custom config file path |
| `--fix` | Auto-fix supported rules |
| `--type-aware` | Enable type-aware linting (requires `oxlint-tsgolint`) |
| `--type-check` | Run type checking alongside linting |
| `--report-unused-disable-directives` | Flag unused `oxlint-disable` comments |
| `--init` | Generate starter `.oxlintrc.json` |

## Overrides

Apply different rules to different file patterns:

```json
{
  "overrides": [
    {
      "files": ["scripts/**/*.js"],
      "rules": { "no-console": "off" }
    },
    {
      "files": ["**/*.{ts,tsx}"],
      "plugins": ["typescript"],
      "rules": { "typescript/no-explicit-any": "error" }
    },
    {
      "files": ["**/test/**"],
      "plugins": ["jest"],
      "env": { "jest": true },
      "rules": { "jest/no-disabled-tests": "off" }
    }
  ]
}
```

## Extends

Inherit from shared config files:

```json
{
  "extends": ["./configs/base.json", "./configs/frontend.json"]
}
```

Paths are relative to the config file. Later entries override earlier ones.

## Editor Integration

- **VS Code**: Install the oxc extension from the marketplace. Enable type-aware linting with the `typeAware` option in extension settings.
- **Neovim / LSP**: oxlint provides a language server; configure via your LSP client.

## CI Integration

```yaml
# GitHub Actions example
- name: Lint
  run: npx oxlint --deny-warnings .
```

The `--deny-warnings` flag exits non-zero if any warnings are found, suitable for CI gates.

## How oxlint Differs from ESLint

| Aspect | ESLint | oxlint |
|---|---|---|
| Language | JavaScript (Node.js) | Rust |
| Speed | Baseline | 50-100x faster |
| Plugin ecosystem | Large (npm packages) | Built-in only (Rust-compiled) |
| Custom rules | JavaScript/TypeScript | JavaScript plugins (experimental) |
| Configuration | `eslint.config.mjs` (flat) | `.oxlintrc.json` (JSONC) |
| Type-aware rules | typescript-eslint (TS compiler) | tsgolint (tsgo / TypeScript 7) |
| Zero-config | No | Yes (correctness by default) |

## When to Use oxlint vs ESLint

**Use oxlint when**:
- Speed is critical (large codebases, CI)
- You only need built-in rules (no custom ESLint plugins)
- You want zero-config linting out of the box

**Use ESLint when**:
- You need custom ESLint plugins not available in oxlint
- You need the full typescript-eslint rule set
- Your framework has specific ESLint plugins (though oxlint covers react, next, jest, vitest natively)

**Use both together** for the best of both worlds (see below).

## Running oxlint Alongside ESLint

Use `eslint-plugin-oxlint` to disable ESLint rules that oxlint already covers, avoiding duplicate reports:

```bash
npm install --save-dev eslint-plugin-oxlint
```

```javascript
// eslint.config.mjs
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import oxlint from 'eslint-plugin-oxlint';

export default [
  eslint.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: { projectService: true },
    },
  },
  // Must be last — disables ESLint rules oxlint handles
  oxlint.configs['flat/recommended'],
];
```

**Typical dual-linter CI strategy**:
1. Run `oxlint` first (fast, catches most issues in seconds)
2. Run `eslint` second (slower, only for type-checked rules oxlint does not cover)

## Migrating from ESLint

Use `oxlint-migrate` to generate an `.oxlintrc.json` from an existing ESLint flat config:

```bash
npx oxlint-migrate eslint.config.mjs
```

This tool maps ESLint rules to their oxlint equivalents and generates a compatible config file.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Expecting npm plugin support | oxlint plugins are built-in Rust modules, not npm packages |
| Not enabling the `typescript` plugin | Add `"plugins": ["typescript"]` to use `typescript/*` rules |
| Running `--type-aware` without `oxlint-tsgolint` | Install `oxlint-tsgolint` as a dev dependency |
| Duplicate warnings when using both linters | Use `eslint-plugin-oxlint` to disable overlapping ESLint rules |
| Using `.oxlintrc.js` | Only JSON config is supported (`.oxlintrc.json`); JS/TS config support is planned for 2026 |
