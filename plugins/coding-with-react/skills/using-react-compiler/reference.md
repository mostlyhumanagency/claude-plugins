# React Compiler Reference

Detailed reference for configuring, debugging, and troubleshooting React Compiler.

## Setup by Bundler

### Vite

```bash
npm install -D babel-plugin-react-compiler@latest
```

```js
// vite.config.js
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [
          ["babel-plugin-react-compiler", {
            // Optional: target specific React version
            // target: "18", // defaults to "19"
          }],
        ],
      },
    }),
  ],
});
```

### Next.js

```bash
npm install -D babel-plugin-react-compiler@latest
```

```js
// next.config.js
module.exports = {
  experimental: {
    reactCompiler: true,
  },
};
```

With options:

```js
module.exports = {
  experimental: {
    reactCompiler: {
      compilationMode: "annotation", // Only compile opted-in components
    },
  },
};
```

### Webpack (Manual Babel Setup)

```bash
npm install -D babel-plugin-react-compiler@latest @babel/core babel-loader
```

```js
// webpack.config.js
module.exports = {
  module: {
    rules: [
      {
        test: /\.(js|jsx|ts|tsx)$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
          options: {
            plugins: [
              ["babel-plugin-react-compiler", {}],
              // Other Babel plugins AFTER the compiler
            ],
            presets: [
              "@babel/preset-react",
              "@babel/preset-typescript",
            ],
          },
        },
      },
    ],
  },
};
```

The compiler plugin must be the first plugin in the Babel pipeline.

### Remix

```bash
npm install -D babel-plugin-react-compiler@latest
```

Remix uses Vite, so configure via `vite.config.ts`:

```ts
// vite.config.ts
import { vitePlugin as remix } from "@remix-run/dev";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [
    remix({
      future: { /* ... */ },
      babel: {
        plugins: [["babel-plugin-react-compiler", {}]],
      },
    }),
  ],
});
```

## Compiler Options

```js
["babel-plugin-react-compiler", {
  // Target React version (default: "19")
  target: "19", // "17" | "18" | "19"

  // Compilation mode
  compilationMode: "all", // "all" | "annotation"

  // Patterns to skip (regex on component/hook name)
  // Matched components/hooks won't be compiled
  sources: (filename) => {
    // Return true to compile this file, false to skip
    return !filename.includes("legacy/");
  },
}]
```

## Debugging Compiler Output

### REACT_COMPILER_DEBUG

Set environment variables to inspect what the compiler generates.

```bash
# Show compiled output in the console
REACT_COMPILER_DEBUG=1 npm run build

# Verbose logging
REACT_COMPILER_DEBUG=verbose npm run build
```

### React DevTools

React DevTools (v5.0+) has built-in support for inspecting compiled components. Look for the "Memo" badge to verify the compiler is working.

Compiled components show a `Compiled` badge in the component tree. If a component lacks this badge, the compiler either skipped it or encountered a bailout.

### Identifying Bailouts

The compiler silently skips components that violate the Rules of React. To find these:

1. Install the ESLint plugin:

```bash
npm install -D eslint-plugin-react-compiler@latest
```

2. Add to ESLint config:

```js
// eslint.config.js
import reactCompiler from "eslint-plugin-react-compiler";

export default [
  {
    plugins: {
      "react-compiler": reactCompiler,
    },
    rules: {
      "react-compiler/react-compiler": "error",
    },
  },
];
```

3. Violations reported by the ESLint plugin correspond to components the compiler will skip or produce incorrect output for.

## What the Compiler Optimizes

The compiler automatically memoizes:

| What | How |
|------|-----|
| Component return values | Wraps JSX in memoization checks |
| Expensive computations | Caches results based on input dependencies |
| Callback functions | Stabilizes function identity across renders |
| Object/array literals in JSX | Prevents unnecessary child re-renders |
| Hook dependencies | Tracks fine-grained dependencies automatically |

### Example: Before and After Compilation

Source code:

```jsx
function ProductCard({ product, onBuy }) {
  const price = formatPrice(product.price);
  const handleClick = () => onBuy(product.id);

  return (
    <div>
      <h2>{product.name}</h2>
      <p>{price}</p>
      <button onClick={handleClick}>Buy</button>
    </div>
  );
}
```

The compiler output (conceptually) wraps values in cache checks:

```jsx
function ProductCard({ product, onBuy }) {
  const $ = useMemoCache(4);
  let price;
  if ($[0] !== product.price) {
    price = formatPrice(product.price);
    $[0] = product.price;
    $[1] = price;
  } else {
    price = $[1];
  }
  // ... similar caching for handleClick and JSX
}
```

## What the Compiler Does NOT Optimize

- **Side effects during render** -- mutating external state, calling `console.log` in render (may change behavior)
- **Non-React functions** -- utility functions that are not components or hooks
- **Dynamic property access patterns** -- `obj[dynamicKey]` may prevent optimization
- **Code that violates Rules of React** -- mutation of props, state, or refs during render causes bailout
- **Third-party hooks with internal mutations** -- compiler assumes hooks follow Rules of React

## Performance Comparison Patterns

### Measuring Improvement

```tsx
import { Profiler } from "react";

function onRender(
  id: string,
  phase: "mount" | "update",
  actualDuration: number,
) {
  console.log(`${id} ${phase}: ${actualDuration.toFixed(1)}ms`);
}

function App() {
  return (
    <Profiler id="App" onRender={onRender}>
      <Dashboard />
    </Profiler>
  );
}
```

### A/B Comparison

Use `"use no memo"` to compare compiled vs uncompiled performance:

```tsx
// Compiled version (default)
function FastComponent() {
  // Compiler optimizes this
}

// Uncompiled version for comparison
function SlowComponent() {
  "use no memo";
  // Same code, no compiler optimization
}
```

## Troubleshooting

### Component Not Being Compiled

**Symptom**: No `Compiled` badge in DevTools.

1. Check ESLint plugin output for violations
2. Verify the file is included by the `sources` filter
3. Ensure `compilationMode` is not `"annotation"` (or add `"use memo"` directive)
4. Check that `babel-plugin-react-compiler` is first in the plugin list

### Incorrect Behavior After Compilation

**Symptom**: UI behaves differently with compiler enabled.

1. Add `"use no memo"` to the affected component to confirm the compiler is the cause
2. Run the ESLint plugin -- violations indicate rules-of-react issues
3. Look for mutations during render (common: sorting arrays in place, modifying objects)
4. Check for side effects in render (logging, analytics calls)

Fix: Refactor to avoid mutation. Use spread/slice/toSorted instead of in-place operations.

### Build Errors

**Symptom**: Compilation fails with internal compiler errors.

1. Update to the latest `babel-plugin-react-compiler` version
2. Add `"use no memo"` to the problematic component as a workaround
3. Report the issue at https://github.com/facebook/react/issues with a minimal reproduction

### Hydration Mismatches

**Symptom**: Hydration errors after enabling compiler on SSR apps.

1. Ensure client and server use the same compiler version
2. Check for non-deterministic render logic (Date.now(), Math.random())
3. Verify that memoized components produce the same output regardless of render order
