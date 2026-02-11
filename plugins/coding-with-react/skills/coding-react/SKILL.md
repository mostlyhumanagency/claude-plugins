---
name: coding-react
description: Use when building, reviewing, debugging, or architecting React components and applications. Covers creating pages, building forms, handling user interactions, managing state, fetching and displaying data, adding loading and error states, optimizing performance, writing tests, and structuring component hierarchies. Routes to the specific subskill for Server Components, actions/forms, SSR streaming, transitions, error boundaries, patterns, compiler optimizations, testing, and the use() API.
---

# React

## Overview

React is a library for building user interfaces with components, hooks, and a declarative rendering model.

## Subskills

| Skill | Use When |
|---|---|
| using-react-actions | Handling forms, mutations, pending states with `useActionState`, `useFormStatus`, `useOptimistic` |
| using-react-use-api | Reading promises or context in render with `use()`, Suspense-based data loading |
| using-react-server-components | Building with Server Components, `"use client"` / `"use server"` directives, Server Actions |
| using-react-compiler | Setting up React Compiler for auto-memoization, removing manual `useMemo`/`useCallback`/`memo` |
| using-react-ssr-streaming | Server-side rendering, Suspense streaming, `prerender`, hydration, partial pre-rendering |
| using-react-patterns | Ref as prop, ref cleanup, `<Context>` provider, metadata tags, `Activity`, `useEffectEvent`, `ViewTransition` |
| using-react-transitions | Concurrent UI with `useTransition`, `startTransition`, `useDeferredValue`, pending states |
| using-react-error-boundaries | Error boundaries, `react-error-boundary` library, recovery patterns, error + Suspense composition |
| testing-react | Testing components with Vitest + React Testing Library, testing actions and forms |

If unsure, start with using-react-patterns for general React development.
