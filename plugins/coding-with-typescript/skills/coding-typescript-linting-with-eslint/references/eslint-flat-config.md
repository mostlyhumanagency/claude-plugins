# ESLint Flat Config with typescript-eslint

## The Flat Config Format

ESLint v9 made flat config the default. ESLint v10 (February 2026) removed the legacy `.eslintrc.*` system entirely. All new projects must use `eslint.config.mjs` (or `.js`, `.cjs`, `.ts`, `.mts`, `.cts`).

A flat config file exports an array of configuration objects. Each object can specify `files`, `rules`, `plugins`, `languageOptions`, and other settings. Objects are applied in order; later entries override earlier ones.

## Installation

```bash
npm install --save-dev eslint @eslint/js typescript typescript-eslint
```

## Basic Setup (Recommended Tier)

```javascript
// eslint.config.mjs
// @ts-check
import eslint from '@eslint/js';
import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';

export default defineConfig(
  eslint.configs.recommended,
  tseslint.configs.recommended,
);
```

`defineConfig()` is a helper released in ESLint v9.22.0. It is functionally equivalent to `tseslint.config()` but ships with ESLint core.

## Typed Linting Setup (Recommended-Type-Checked)

Type-checked rules use TypeScript's compiler APIs for deeper analysis. They require `parserOptions.projectService`.

```javascript
// eslint.config.mjs
// @ts-check
import eslint from '@eslint/js';
import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';

export default defineConfig(
  eslint.configs.recommended,
  tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
      },
    },
  },
);
```

`projectService: true` tells the parser to use TypeScript's project service for type information. This is the recommended approach (replaces the older `project: true` option).

## Strict + Type-Checked Setup

```javascript
// eslint.config.mjs
// @ts-check
import eslint from '@eslint/js';
import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';

export default defineConfig(
  eslint.configs.recommended,
  tseslint.configs.strictTypeChecked,
  tseslint.configs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
      },
    },
  },
);
```

## The 4 Configuration Tiers

typescript-eslint organizes rules into 4 tiers, each inclusive of the ones before it:

| Tier | What It Adds | Type Info Required |
|---|---|---|
| `recommended` | Core correctness rules (drop-in safe) | No |
| `recommended-type-checked` | recommended + type-aware correctness rules | Yes |
| `strict` | recommended + opinionated bug-catching rules | No |
| `strict-type-checked` | All of the above + strict type-aware rules | Yes |

Additionally, two stylistic tiers exist independently:

| Tier | What It Adds | Type Info Required |
|---|---|---|
| `stylistic` | Consistent code style (does not affect logic) | No |
| `stylistic-type-checked` | stylistic + type-aware style rules | Yes |

**Hierarchy**: `strict-type-checked` is a superset of `recommended`, `recommended-type-checked`, and `strict`.

## Incremental Adoption Strategy

1. Start with `recommended` — safe to drop in, no type info needed
2. Add `stylistic` for consistent code style
3. Enable `recommendedTypeChecked` — adds type-aware correctness rules (requires `projectService`)
4. Graduate to `strictTypeChecked` when the team is comfortable with TypeScript
5. Add `stylisticTypeChecked` for type-aware style enforcement

## Framework-Specific Configs

### React / Next.js

```javascript
// eslint.config.mjs
import eslint from '@eslint/js';
import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';
import reactPlugin from 'eslint-plugin-react';
import reactHooksPlugin from 'eslint-plugin-react-hooks';

export default defineConfig(
  eslint.configs.recommended,
  tseslint.configs.strictTypeChecked,
  reactPlugin.configs.flat.recommended,
  reactHooksPlugin.configs['recommended-latest'],
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
      },
    },
    settings: {
      react: { version: 'detect' },
    },
  },
);
```

For Next.js, install `@next/eslint-plugin-next` and add its flat config.

## Disabling Type-Checked Rules for JS Files

If your project mixes `.js` and `.ts`, disable type-checked rules for JavaScript files:

```javascript
export default defineConfig(
  eslint.configs.recommended,
  tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: { projectService: true },
    },
  },
  {
    files: ['**/*.js', '**/*.mjs', '**/*.cjs'],
    extends: [tseslint.configs.disableTypeChecked],
  },
);
```

## Performance Notes

- Type-checked rules require TypeScript to build the project before ESLint runs
- Small projects: negligible overhead (seconds)
- Large projects: can add meaningful time; IDE plugins cache results to reduce impact
- For CI speed, consider running oxlint for non-type-checked rules and ESLint only for type-checked rules

## Common Mistakes

| Mistake | Fix |
|---|---|
| Using `.eslintrc.json` or `.eslintrc.js` | Migrate to `eslint.config.mjs` — ESLint v10 removed legacy config |
| Missing TypeScript parser | `typescript-eslint` package includes the parser; do not install `@typescript-eslint/parser` separately with the new unified package |
| Using `project: './tsconfig.json'` | Use `projectService: true` instead (faster, recommended) |
| Applying type-checked rules to `.js` files | Add `tseslint.configs.disableTypeChecked` for JS file patterns |
| Installing `@typescript-eslint/eslint-plugin` + `@typescript-eslint/parser` separately | Use the unified `typescript-eslint` package which bundles both |
| Not having `typescript` installed | typescript-eslint requires `typescript` as a peer dependency |
