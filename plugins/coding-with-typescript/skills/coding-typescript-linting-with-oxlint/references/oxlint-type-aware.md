# oxlint Type-Aware Linting

## Overview

Type-aware linting in oxlint uses tsgolint, a Go-based type-aware linting engine powered by TypeScript 7 (tsgo). tsgolint is integrated directly into the oxlint CLI and provides rules that analyze TypeScript's type system — detecting unhandled promises, unsafe assignments, and more.

As of early 2026, type-aware linting is in alpha with 43 supported rules. It is 10-40x faster than ESLint + typescript-eslint for type-aware rules.

## Architecture

The system splits responsibilities between two components:

| Component | Language | Responsibility |
|---|---|---|
| oxlint | Rust | File traversal, ignore logic, config, non-type-aware rules, reporting |
| tsgolint | Go | TypeScript program building, type resolution, type-aware rule execution |

tsgolint is based on typescript-go (Microsoft's Go rewrite of the TypeScript compiler, shipping as TypeScript v7.0). It shims internal APIs from typescript-go to provide type information to lint rules.

## Installation

```bash
# Install both oxlint and the type-aware addon
npm install --save-dev oxlint oxlint-tsgolint@latest
```

Both packages are required. `oxlint-tsgolint` provides the tsgolint binary that oxlint calls when type-aware mode is enabled.

## Running Type-Aware Linting

```bash
# Basic type-aware linting
npx oxlint --type-aware

# Type-aware + type checking (replaces tsc --noEmit)
npx oxlint --type-aware --type-check

# With debug output for performance analysis
OXC_LOG=debug npx oxlint --type-aware
```

The `--type-aware` flag is opt-in. Without it, only non-type-aware rules run. The `--type-check` flag combines linting with type checking, consolidating two CI steps into one.

## Configuration

Configure type-aware rules in `.oxlintrc.json`:

```json
{
  "plugins": ["typescript"],
  "rules": {
    "typescript/no-floating-promises": "error",
    "typescript/no-unsafe-assignment": "warn",
    "typescript/no-unsafe-call": "error",
    "typescript/no-unsafe-member-access": "error",
    "typescript/no-unsafe-return": "error",
    "typescript/no-unsafe-argument": "error",
    "typescript/no-misused-promises": "error"
  }
}
```

Rule options match their typescript-eslint equivalents:

```json
{
  "rules": {
    "typescript/no-floating-promises": ["error", { "ignoreVoid": true }]
  }
}
```

## Supported Type-Aware Rule Categories

As of early 2026 (alpha), tsgolint supports 43 type-aware rules across these areas:

| Category | Example Rules | Description |
|---|---|---|
| Unsafe `any` detection | `no-unsafe-assignment`, `no-unsafe-call`, `no-unsafe-member-access`, `no-unsafe-return`, `no-unsafe-argument` | Flags `any` flowing through code |
| Promise handling | `no-floating-promises`, `no-misused-promises` | Catches unhandled and misused promises |
| Type assertions | `no-unnecessary-type-assertion` | Removes redundant `as` casts |
| Conditions | `no-unnecessary-condition` | Flags always-truthy/falsy checks |
| Template literals | `restrict-template-expressions` | Prevents non-string types in templates |
| Deprecated APIs | `no-deprecated` | Flags usage of deprecated symbols |
| Return types | `require-await` | Flags async functions without await |

Rule coverage is expanding. Check the tsgolint repository for the current list: https://github.com/oxc-project/tsgolint

## Inline Disable Comments

```typescript
// oxlint-disable-next-line typescript/no-floating-promises
doSomethingAsync();

/* oxlint-disable typescript/no-unsafe-assignment */
const data = untypedFunction();
/* oxlint-enable typescript/no-unsafe-assignment */
```

Report unused disable directives:

```bash
npx oxlint --type-aware --report-unused-disable-directives
```

## Monorepo Setup

For monorepos, ensure dependent packages are built before linting so type definitions are available:

```bash
pnpm install
pnpm -r build
npx oxlint --type-aware
```

If the root `tsconfig.json` includes too many files, scope it down:

```json
{
  "files": [],
  "references": [
    { "path": "./packages/core" },
    { "path": "./packages/app" }
  ]
}
```

## Performance

| Setup | Relative Speed |
|---|---|
| ESLint + typescript-eslint (type-checked) | 1x (baseline) |
| oxlint + tsgolint (type-aware) | 10-40x faster |

Performance tips:
- Narrow `include` patterns in `tsconfig.json` to avoid processing unnecessary files
- Add `exclude` for `dist/`, `build/`, `coverage/` directories
- Use `OXC_LOG=debug` to identify bottlenecks in file assignment and type resolution

## TypeScript Version Requirements

- Requires TypeScript 7.0+ (tsgo)
- Legacy `tsconfig` options like `baseUrl` may not be supported
- Invalid TypeScript options are reported when using `--type-check`

If your project uses an older TypeScript version, type-aware linting may not work. Consider using ESLint + typescript-eslint for type-checked rules in that case.

## Alpha Limitations (Early 2026)

- Rule coverage is incomplete (43 of 100+ typescript-eslint type-checked rules)
- Very large codebases may encounter high memory usage
- Some edge cases in type resolution may differ from tsc
- JS/TS config file support (`.oxlintrc.ts`) is not yet available

## CI Integration Example

```yaml
# GitHub Actions: dual-linter strategy
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm ci

      # Fast pass: oxlint for non-type-aware rules
      - name: oxlint (fast)
        run: npx oxlint --deny-warnings .

      # Type-aware pass: oxlint + tsgolint
      - name: oxlint type-aware
        run: npx oxlint --type-aware --deny-warnings .

      # Optionally: ESLint for rules oxlint doesn't cover yet
      - name: ESLint (type-checked extras)
        run: npx eslint .
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Forgetting `--type-aware` flag | Type-aware rules do not run by default; pass `--type-aware` explicitly |
| Missing `oxlint-tsgolint` package | Install `oxlint-tsgolint` as a dev dependency alongside `oxlint` |
| Using TypeScript < 7.0 | tsgolint requires tsgo (TypeScript 7); use ESLint for older TS versions |
| Root tsconfig includes too many files | Narrow `include` patterns or use project references with empty root `files` |
| Expecting full typescript-eslint parity | Only 43 type-aware rules are supported in alpha; check tsgolint repo for coverage |
