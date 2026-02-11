# coding-with-react

React 18/19 — 10 skills, 4 agents, 4 commands covering actions, server components, streaming SSR, compiler, transitions, error boundaries, patterns, and testing.

## Skills

| Skill | Description |
|---|---|
| `coding-react` | Router — routes to the most specific React subskill |
| `using-react-actions` | useActionState, useFormStatus, useOptimistic for forms and async actions |
| `using-react-use-api` | `use()` API for reading Promises and Context with Suspense |
| `using-react-server-components` | Server Components, Client Components, Server Actions, directives |
| `using-react-compiler` | Automatic memoization at build time via React Compiler |
| `using-react-ssr-streaming` | Streaming SSR, renderToPipeableStream, prerender, Partial Pre-rendering |
| `using-react-patterns` | Ref as prop, Context provider, metadata, Activity, useEffectEvent, resource preloading |
| `using-react-transitions` | useTransition, startTransition, useDeferredValue for concurrent UI |
| `using-react-error-boundaries` | Error boundaries, react-error-boundary, recovery patterns, Suspense composition |
| `testing-react` | Testing with Vitest and React Testing Library |

## Agents

| Agent | Description |
|---|---|
| `react-expert` | Primary agent — deep React expertise, routes to skills and peer agents |
| `react-debugger` | Diagnose hydration mismatches, hook violations, rendering issues |
| `react-perf-profiler` | Re-render analysis, bundle size audit, lazy loading, memoization |
| `react-a11y-auditor` | WCAG compliance audit, aria attributes, keyboard navigation, focus management |

## Commands

| Command | Description |
|---|---|
| `/react-doctor` | Audit React project health: versions, deps, deprecated patterns, config |
| `/react-migrate` | Analyze and migrate to modern React 19 patterns |
| `/react-check` | Scan for anti-patterns: missing keys, stale closures, useEffect misuse |
| `/react-component` | Scaffold a new React component from templates |

## Scripts

| Script | Description |
|---|---|
| `check-react-setup.sh` | Validate React project configuration |
| `find-class-components.sh` | Find class components for conversion |
| `check-react-patterns.sh` | Detect React anti-patterns |
| `check-bundle-imports.sh` | Find barrel imports and large dependency imports |
| `find-deprecated-apis.sh` | Detect deprecated React APIs |

## Templates

| Template | Description |
|---|---|
| `component-form.tsx` | Form with Server Actions, useActionState, useFormStatus, validation |
| `hook-custom.ts` | Custom hook with TypeScript typing, cleanup, AbortController |
| `context-provider.tsx` | React 19 Context-as-provider pattern with useReducer |
| `error-boundary.tsx` | Error boundary with recovery UI, Suspense composition |
| `vitest-react.config.ts` | Vitest config for React with jsdom and Testing Library |
| `page-layout.tsx` | Root layout with metadata, Suspense, ErrorBoundary, providers |

## Installation

```sh
claude plugin add mostlyhumanagency/claude-plugins --path plugins/coding-with-react
```
