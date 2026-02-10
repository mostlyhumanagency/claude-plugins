# TypeScript in Node (v24+, Experimental)

## Running TypeScript Directly

Node.js v24+ can run `.ts` files by stripping type annotations at load time. No transpilation to JavaScript — types are simply removed.

```bash
node --experimental-strip-types app.ts
```

This is not a full TypeScript compiler. It removes type syntax but does not:
- Type-check your code (use `tsc --noEmit` for that).
- Transform TypeScript-specific runtime features (enums, namespaces).
- Generate declaration files.

## What Works

Type-only syntax that is removed at load time:

| Feature | Status |
|---|---|
| Type annotations (`x: string`) | Works |
| Interfaces | Works |
| Type aliases | Works |
| Generics | Works |
| `as const` | Works |
| `as` type assertions | Works |
| Optional properties (`x?: number`) | Works |
| Union/intersection types | Works |
| Utility types (`Partial<T>`, etc.) | Works |
| `satisfies` operator | Works |
| `import type` / `export type` | Works |

## What Does NOT Work

Features that require runtime code transformation:

| Feature | Issue | Alternative |
|---|---|---|
| `enum` | Generates runtime code | Use const object + type |
| `const enum` | Requires inlining values | Use const object |
| `namespace` | Generates runtime code | Use ES modules |
| Parameter decorators | Requires transformation | Use a build step |
| `declare` fields in classes with `useDefineForClassFields` | May behave differently | Use explicit initialization |

### Replacing Enums

```ts
// Instead of:
// enum Status { Active, Inactive, Pending }

// Use a const object:
const Status = {
  Active: 0,
  Inactive: 1,
  Pending: 2,
} as const;

type Status = typeof Status[keyof typeof Status];

// Usage is identical:
function handle(s: Status) {
  if (s === Status.Active) { /* ... */ }
}
```

### Replacing String Enums

```ts
// Instead of:
// enum Color { Red = 'red', Green = 'green', Blue = 'blue' }

const Color = {
  Red: 'red',
  Green: 'green',
  Blue: 'blue',
} as const;

type Color = typeof Color[keyof typeof Color];
```

## File Extensions

| Extension | Module Type | Notes |
|---|---|---|
| `.ts` | Follows `package.json` `"type"` | Same as `.js` resolution |
| `.mts` | Always ESM | Explicit ESM TypeScript |
| `.cts` | Always CommonJS | Explicit CJS TypeScript |

## Import Specifiers

When importing between TypeScript files with strip-types:

```ts
// Use .ts extension in imports
import { helper } from './utils.ts';

// For .mts files
import { handler } from './handler.mts';
```

## tsconfig.json for Node

Recommended settings for Node.js v24+ with strip-types:

```json
{
  "compilerOptions": {
    "target": "es2022",
    "module": "node20",
    "moduleResolution": "node20",
    "strict": true,
    "noEmit": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "forceConsistentCasingInImports": true,
    "verbatimModuleSyntax": true
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules"]
}
```

Key settings explained:
- `"module": "node20"` — matches Node.js module resolution behavior.
- `"moduleResolution": "node20"` — resolves imports the way Node does.
- `"target": "es2022"` — Node v24 supports ES2022+ features natively.
- `"noEmit": true` — type-check only; Node handles execution.
- `"verbatimModuleSyntax": true` — enforces `import type` for type-only imports.

## Comparison with Other Runners

| Runner | How It Works | Enum Support | Type Checking | Speed |
|---|---|---|---|---|
| Node strip-types | Removes types at load | No | No | Fast |
| tsx | esbuild transform | Yes | No | Fast |
| ts-node | TypeScript compiler | Yes | Optional | Slower |
| tsc + node | Compile then run | Yes | Yes | Slowest |

**When to use which:**
- **Node strip-types** — simple scripts, prototyping, no enums needed.
- **tsx** — need enum support without a build step.
- **ts-node** — need full TypeScript features with optional type checking.
- **tsc + node** — production builds, CI/CD, need .d.ts output.

## Quick Reference

| Task | Command / Setting |
|---|---|
| Run .ts file | `node --experimental-strip-types file.ts` |
| Type-check only | `tsc --noEmit` |
| ESM TypeScript | Use `.mts` extension |
| CJS TypeScript | Use `.cts` extension |
| Module setting | `"module": "node20"` |
| Resolution setting | `"moduleResolution": "node20"` |
| Replace enum | `const X = { ... } as const` + type |

## Common Mistakes

**Using enums** — Enums require code generation, which strip-types cannot do. Use const objects with `as const`.

**Expecting type checking** — Strip-types only removes types; it does not validate them. Run `tsc --noEmit` separately for type checking.

**Wrong tsconfig module settings** — Using `"module": "commonjs"` or `"moduleResolution": "node"` causes mismatches with Node's actual behavior. Use `"node20"` for both.

**Omitting file extensions in imports** — When using strip-types with ESM, imports need file extensions, including `.ts`.

**Using namespace** — Namespaces generate runtime code and are not supported by strip-types. Use ES module exports instead.

## Do / Don't

- Do use `--experimental-strip-types` for development and scripts.
- Do use `tsc --noEmit` for type checking in CI.
- Do use const objects instead of enums.
- Do set `"module": "node20"` in tsconfig.json.
- Do include file extensions in ESM imports.
- Don't use enums, namespaces, or parameter decorators with strip-types.
- Don't rely on strip-types for production builds.
- Don't skip type checking — run `tsc --noEmit` separately.
- Don't use `"module": "commonjs"` in tsconfig for ESM Node projects.

## Examples

### Simple script

```ts
// hello.ts
interface Config {
  name: string;
  port: number;
}

const config: Config = {
  name: 'my-app',
  port: 3000,
};

console.log(`Starting ${config.name} on port ${config.port}`);
```

```bash
node --experimental-strip-types hello.ts
# Starting my-app on port 3000
```

### HTTP server in TypeScript

```ts
// server.ts
import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';

interface Route {
  path: string;
  handler: (req: IncomingMessage, res: ServerResponse) => void;
}

const routes: Route[] = [
  {
    path: '/',
    handler: (_req, res) => {
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end('Hello from TypeScript');
    },
  },
];

const server = createServer((req, res) => {
  const route = routes.find(r => r.path === req.url);
  if (route) {
    route.handler(req, res);
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

server.listen(3000, () => console.log('Listening on :3000'));
```

```bash
node --experimental-strip-types server.ts
```

## Verification

- Check Node version: `node -v` (must be v24+).
- Verify strip-types: `node --experimental-strip-types -e "const x: number = 1; console.log(x)"`.
- Type-check separately: `npx tsc --noEmit`.
