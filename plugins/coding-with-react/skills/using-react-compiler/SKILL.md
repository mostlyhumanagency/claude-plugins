---
name: using-react-compiler
description: Use when optimizing React app performance, removing manual useMemo/useCallback/memo calls, setting up automatic memoization, fixing unnecessary re-renders at build time, or adopting React Compiler incrementally. Also use when seeing "use memo" or "use no memo" directives, or configuring babel-plugin-react-compiler in Vite or Next.js.
---

## Overview

React Compiler is a build-time optimization tool that automatically memoizes React applications without manual `useMemo`, `useCallback`, or `React.memo`. It analyzes your components and hooks, inserting fine-grained memoization where beneficial. The compiler eliminates cascading re-renders and memoizes expensive calculations automatically, requiring only that your code follows the Rules of React.

## When to Use

**Use React Compiler when:**
- Building new React 19 projects where you want automatic optimization
- Adopting incremental performance improvements in existing apps
- Eliminating manual memoization boilerplate and dependency tracking bugs
- Preventing common issues like arrow functions breaking memoization

**Skip React Compiler when:**
- Your code violates Rules of React (mutates props/state during render, side effects in render)
- Working with untested third-party libraries
- You need precise control over which values are memoized (keep `useMemo`/`useCallback` for these cases)

## Setup

### Vite

```bash
npm install -D babel-plugin-react-compiler@latest
```

```js
// vite.config.js
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: ['babel-plugin-react-compiler'],
      },
    }),
  ],
});
```

### Next.js

```bash
npm install -D babel-plugin-react-compiler@latest
```

See [Next.js docs](https://nextjs.org/docs/app/api-reference/next-config-js/reactCompiler) for configuration.

### ESLint Plugin

```bash
npm install -D eslint-plugin-react-compiler@latest
```

Add to your ESLint config to catch Rules of React violations.

## Core Patterns

### Before: Manual Memoization

```jsx
const ExpensiveComponent = memo(function ({ data, onClick }) {
  const processed = useMemo(() => process(data), [data]);
  const handleClick = useCallback((item) => onClick(item.id), [onClick]);

  return <div>{processed.map(item => <Item onClick={handleClick} />)}</div>;
});
```

### After: Compiler Handles It

```jsx
function ExpensiveComponent({ data, onClick }) {
  const processed = process(data);
  const handleClick = (item) => onClick(item.id);

  return <div>{processed.map(item => <Item onClick={handleClick} />)}</div>;
}
```

### Incremental Adoption

Use `compilationMode: "annotation"` to opt-in specific components:

```jsx
function MyComponent() {
  "use memo"; // Compiler optimizes this component
  // ...
}
```

Or opt-out specific components:

```jsx
function LegacyComponent() {
  "use no memo"; // Compiler skips this
  // ...
}
```

## Quick Reference

| Feature | Details |
|---------|---------|
| Package | `babel-plugin-react-compiler` |
| ESLint | `eslint-plugin-react-compiler` |
| React Versions | 17, 18, 19 (best with 19) |
| Opt-in directive | `"use memo"` |
| Opt-out directive | `"use no memo"` |
| Compilation mode | `compilationMode: "annotation"` for incremental adoption |

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Mutating props/state during render | Compiler output breaks or behaves unexpectedly | Follow Rules of React—never mutate during render |
| Keeping `useMemo`/`useCallback` everywhere | Redundant memoization, harder to maintain | Remove manual memoization; let compiler handle it |
| Missing ESLint plugin | Silent violations of Rules of React | Install `eslint-plugin-react-compiler` |
| Expecting compiler to fix broken code | Same bugs, different behavior | Compiler assumes correct code; fix violations first |
| Not running compiler first in Babel pipeline | Compilation failures or incorrect output | Ensure `babel-plugin-react-compiler` runs before other plugins |
