# typescript-eslint Rules Quick Reference

## The no-unsafe-* Family (Type-Checked)

These 5 rules form the backbone of type safety enforcement. They flag any use of `any` — explicit or implicit — flowing through your code. All require type information.

| Rule | What It Catches |
|---|---|
| `no-unsafe-argument` | Passing an `any`-typed value as a function argument |
| `no-unsafe-assignment` | Assigning an `any`-typed value to a variable or property |
| `no-unsafe-call` | Calling a value typed as `any` |
| `no-unsafe-member-access` | Accessing a property on an `any`-typed value |
| `no-unsafe-return` | Returning an `any`-typed value from a function |

All 5 are included in `recommended-type-checked`. They are not configurable — you either enable or disable them. If your codebase has many `any` types, adopt incrementally with ESLint disable comments on specific lines rather than disabling the rules entirely.

## Top 15 typescript-eslint Rules

| # | Rule | Tier | Type Info | What It Does |
|---|---|---|---|---|
| 1 | `no-explicit-any` | recommended | No | Bans `any` type annotations |
| 2 | `no-unused-vars` | recommended | No | Flags unused variables (replaces ESLint core rule) |
| 3 | `no-floating-promises` | rec-type-checked | Yes | Requires promises to be awaited, returned, or voided |
| 4 | `no-misused-promises` | rec-type-checked | Yes | Catches promises in boolean/void positions |
| 5 | `no-unsafe-assignment` | rec-type-checked | Yes | Blocks assigning `any` to typed variables |
| 6 | `no-unsafe-call` | rec-type-checked | Yes | Blocks calling `any`-typed values |
| 7 | `no-unsafe-member-access` | rec-type-checked | Yes | Blocks property access on `any` |
| 8 | `no-unsafe-argument` | rec-type-checked | Yes | Blocks passing `any` as function argument |
| 9 | `no-unsafe-return` | rec-type-checked | Yes | Blocks returning `any` from functions |
| 10 | `consistent-type-imports` | stylistic | No | Enforces `import type` for type-only imports |
| 11 | `consistent-type-exports` | stylistic-type-checked | Yes | Enforces `export type` for type-only exports |
| 12 | `no-unnecessary-condition` | strict | Yes | Flags always-truthy/falsy checks |
| 13 | `no-unnecessary-type-assertion` | rec-type-checked | Yes | Removes redundant `as` casts |
| 14 | `prefer-nullish-coalescing` | stylistic-type-checked | Yes | Prefers `??` over `\|\|` for nullable values |
| 15 | `restrict-template-expressions` | rec-type-checked | Yes | Prevents non-string types in template literals |

## Rule Categories Explained

### Correctness Rules (recommended / recommended-type-checked)

These rules catch actual bugs. Safe to enable on any project:

- `no-array-constructor` — Disallows `new Array()` in favor of array literals
- `no-duplicate-enum-members` — Catches duplicate values in enums
- `no-extra-non-null-assertion` — Flags `value!!!.prop`
- `no-loss-of-precision` — Catches numeric literals that lose precision
- `no-namespace` — Discourages legacy `namespace` (use ES modules)
- `no-non-null-asserted-optional-chain` — Flags `value?.prop!`
- `no-require-imports` — Flags `require()` in favor of `import`
- `no-this-alias` — Flags `const self = this`
- `no-var-requires` — Blocks `const x = require('y')`

### Strict Rules (strict / strict-type-checked)

More opinionated, but catch real issues in mature codebases:

- `no-confusing-void-expression` — Prevents returning void in expression positions
- `no-deprecated` — Flags usage of deprecated APIs (type-checked)
- `no-mixed-enums` — Flags enums mixing string and number members
- `no-non-null-assertion` — Bans the `!` postfix operator
- `no-unnecessary-condition` — Flags always-true/false conditions (type-checked)
- `unified-signatures` — Merges overloads into unions where possible

### Stylistic Rules (stylistic / stylistic-type-checked)

Code style enforcement that does not affect correctness:

- `consistent-type-imports` — Enforces `import type { Foo }` syntax
- `consistent-type-exports` — Enforces `export type { Foo }` syntax (type-checked)
- `prefer-for-of` — Prefers `for...of` over index-based loops
- `prefer-function-type` — Uses function types instead of interfaces with call signatures
- `prefer-nullish-coalescing` — Prefers `??` over `||` (type-checked)
- `prefer-optional-chain` — Prefers `a?.b` over `a && a.b`

## Deprecated / Removed Rules

| Old Rule | Status | Replacement |
|---|---|---|
| `ban-types` | Removed in v8 | `no-restricted-types` + `no-unsafe-function-type` + `no-wrapper-object-types` |
| `no-var-requires` | Removed in v8 | `no-require-imports` |
| `camelcase` | Removed | `naming-convention` |

## Configuring Individual Rules

Override any rule in your flat config:

```javascript
export default defineConfig(
  eslint.configs.recommended,
  tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: { projectService: true },
    },
    rules: {
      // Downgrade to warning during migration
      '@typescript-eslint/no-explicit-any': 'warn',
      // Enable a stricter rule not in recommended
      '@typescript-eslint/no-unnecessary-condition': 'error',
      // Enforce type-only imports
      '@typescript-eslint/consistent-type-imports': ['error', {
        prefer: 'type-imports',
        fixStyle: 'inline-type-imports',
      }],
    },
  },
);
```
