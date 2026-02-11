---
name: using-react-use-api
description: Use when loading async data in client components with Suspense, reading context conditionally or inside loops, streaming data from server to client components, or resolving promises during render. Also use when seeing errors about missing Suspense boundaries or infinite re-renders from promises created in render. Covers the use() API for promises and context.
---

## Overview

`use()` is a React API that reads resources (Promises or Context) during render. Unlike hooks, it can be called conditionally and inside loops, and integrates with Suspense for async data loading.

## When to Use

**Use `use()` when:**
- Loading async data in Client Components with Suspense
- Reading context conditionally (after early returns or in loops)
- Streaming data from Server Components to Client Components

**Do NOT use when:**
- In Server Components — use `async`/`await` instead
- For promises created during render — create in parent or Server Component
- For synchronous data — use `useState`/`useReducer`

## Core Patterns

### Reading a Promise with Suspense

```tsx
import { use, Suspense } from "react";

function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise); // suspends until resolved
  return (
    <ul>
      {comments.map((c) => (
        <li key={c.id}>{c.text}</li>
      ))}
    </ul>
  );
}

function Page({ postId }: { postId: string }) {
  const commentsPromise = fetchComments(postId); // create in parent
  return (
    <Suspense fallback={<p>Loading comments...</p>}>
      <Comments commentsPromise={commentsPromise} />
    </Suspense>
  );
}
```

### Conditional Context Reading

```tsx
function HorizontalRule({ show }: { show: boolean }) {
  if (show) {
    const theme = use(ThemeContext); // conditional — impossible with useContext
    return <hr className={theme} />;
  }
  return null;
}
```

### Server-to-Client Promise Streaming

```tsx
// Server Component
import { Message } from "./message";

export default function App() {
  const messagePromise = fetchMessage();
  return (
    <Suspense fallback={<p>Loading...</p>}>
      <Message messagePromise={messagePromise} />
    </Suspense>
  );
}

// Client Component
"use client";
import { use } from "react";

export function Message({ messagePromise }: { messagePromise: Promise<string> }) {
  const content = use(messagePromise);
  return <p>{content}</p>;
}
```

### Error Handling

```tsx
import { ErrorBoundary } from "react-error-boundary";

function MessageContainer({ messagePromise }: { messagePromise: Promise<string> }) {
  return (
    <ErrorBoundary fallback={<p>Something went wrong</p>}>
      <Suspense fallback={<p>Loading...</p>}>
        <Message messagePromise={messagePromise} />
      </Suspense>
    </ErrorBoundary>
  );
}

// Or handle with Promise.catch for fallback values:
const safePromise = fetchMessage().catch(() => "No message found.");
```

## Quick Reference

| Usage | Example | Notes |
|-------|---------|-------|
| Read Promise | `const data = use(promise)` | Suspends component, needs `<Suspense>` ancestor |
| Read Context | `const value = use(MyContext)` | Like `useContext` but callable conditionally |
| Error handling | Wrap in `<ErrorBoundary>` | `try-catch` does NOT work with `use()` |
| Fallback value | `promise.catch(() => fallback)` | Alternative to Error Boundary |

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Creating promise inside the reading component | Infinite re-render loop | Create promise in parent component or Server Component |
| Using `try-catch` around `use()` | Catch doesn't fire | Use Error Boundary or `promise.catch()` |
| Passing non-serializable values from Server to Client | Runtime error | Resolved value must be serializable (no functions) |
| Using `use()` in Server Component | Unnecessary | Use `async`/`await` directly in Server Components |
| Missing `<Suspense>` ancestor | Unhandled promise error | Wrap reading component in `<Suspense>` |
