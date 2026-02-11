---
name: using-react-transitions
description: Use when keeping the UI responsive during expensive updates, switching tabs without freezing, filtering or searching large lists while typing stays smooth, showing loading indicators without blocking user input, deferring non-urgent re-renders, or navigating between views without jank. Covers useTransition, startTransition, useDeferredValue, and pending state patterns.
---

# Using React Transitions

## Overview

React transitions let you mark state updates as non-urgent so the UI stays responsive during expensive re-renders. `useTransition` and `startTransition` wrap state updates that can be interrupted by urgent ones (like typing), while `useDeferredValue` defers re-rendering of a value until the browser is idle. Together they form the core of React's concurrent rendering model.

## When to Use

- Switching tabs or navigation routes where you want to keep the old UI visible while loading
- Filtering or searching large lists where typing must stay responsive
- Any state update that triggers an expensive re-render you want to deprioritize
- Showing pending/loading indicators without blocking user input
- Wrapping `setState` calls that cause Suspense boundaries to suspend

**Do NOT use when:**
- The update is urgent (text input value, toggles, direct user feedback)
- The re-render is already fast -- transitions add overhead for no benefit
- You need synchronous DOM updates (focus management, scroll position)

## Core Patterns

### useTransition for Tab Switching

```tsx
import { useState, useTransition } from "react";

function TabContainer() {
  const [tab, setTab] = useState("home");
  const [isPending, startTransition] = useTransition();

  function selectTab(nextTab: string) {
    startTransition(() => {
      setTab(nextTab); // Non-urgent -- old tab stays visible until new one is ready
    });
  }

  return (
    <div>
      <nav>
        <button onClick={() => selectTab("home")}>Home</button>
        <button onClick={() => selectTab("posts")}>Posts</button>
        <button onClick={() => selectTab("contact")}>Contact</button>
      </nav>
      <div style={{ opacity: isPending ? 0.7 : 1 }}>
        {tab === "home" && <HomePage />}
        {tab === "posts" && <PostsPage />}
        {tab === "contact" && <ContactPage />}
      </div>
    </div>
  );
}
```

### useTransition with Suspense

```tsx
import { useState, useTransition, Suspense } from "react";

function SearchPage() {
  const [query, setQuery] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [isPending, startTransition] = useTransition();

  function handleSearch(value: string) {
    setQuery(value); // Urgent -- keep input responsive
    startTransition(() => {
      setSearchQuery(value); // Non-urgent -- can suspend
    });
  }

  return (
    <div>
      <input value={query} onChange={(e) => handleSearch(e.target.value)} />
      <Suspense fallback={<p>Loading results...</p>}>
        <SearchResults query={searchQuery} isPending={isPending} />
      </Suspense>
    </div>
  );
}
```

### startTransition Without the Hook

Use `startTransition` from `react` when you do not need `isPending` or when outside a component (e.g., in a router or store).

```tsx
import { startTransition } from "react";

function navigate(url: string) {
  startTransition(() => {
    router.push(url); // Mark navigation as non-urgent
  });
}
```

### useDeferredValue for Expensive Renders

```tsx
import { useState, useDeferredValue, memo } from "react";

function FilteredList() {
  const [filter, setFilter] = useState("");
  const deferredFilter = useDeferredValue(filter);
  const isStale = filter !== deferredFilter;

  return (
    <div>
      <input value={filter} onChange={(e) => setFilter(e.target.value)} />
      <div style={{ opacity: isStale ? 0.6 : 1 }}>
        <ExpensiveList filter={deferredFilter} />
      </div>
    </div>
  );
}

const ExpensiveList = memo(function ExpensiveList({ filter }: { filter: string }) {
  const items = computeExpensiveFilter(filter); // Only re-runs when deferredFilter changes
  return (
    <ul>
      {items.map((item) => (
        <li key={item.id}>{item.name}</li>
      ))}
    </ul>
  );
});
```

### useDeferredValue with Initial Value

```tsx
import { useDeferredValue } from "react";

function App({ query }: { query: string }) {
  // Returns "" on first render, then defers subsequent updates
  const deferredQuery = useDeferredValue(query, "");

  return (
    <Suspense fallback={<p>Loading...</p>}>
      <Results query={deferredQuery} />
    </Suspense>
  );
}
```

### Combining Transitions with Suspense and Error Boundaries

```tsx
import { useState, useTransition, Suspense } from "react";
import { ErrorBoundary } from "react-error-boundary";

function Dashboard() {
  const [view, setView] = useState<"overview" | "details">("overview");
  const [isPending, startTransition] = useTransition();

  return (
    <div>
      <button
        disabled={isPending}
        onClick={() => startTransition(() => setView("details"))}
      >
        {isPending ? "Loading..." : "Show Details"}
      </button>

      <ErrorBoundary fallback={<p>Failed to load</p>}>
        <Suspense fallback={<p>Loading view...</p>}>
          {view === "overview" ? <Overview /> : <Details />}
        </Suspense>
      </ErrorBoundary>
    </div>
  );
}
```

## Quick Reference

| API | Returns | Use Case |
|-----|---------|----------|
| `useTransition()` | `[isPending, startTransition]` | Component-level non-urgent updates with pending state |
| `startTransition(fn)` | `void` | Non-urgent updates outside components (routers, stores) |
| `useDeferredValue(value)` | Deferred copy of `value` | Defer expensive child re-renders |
| `useDeferredValue(value, initialValue)` | `initialValue` on first render, then deferred `value` | Defer with a placeholder for initial render |

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Wrapping urgent updates in transition | Input feels laggy, typing is delayed | Only wrap the non-urgent update; keep `onChange` synchronous |
| Expecting transition to delay `setState` | State updates immediately | Transition makes the re-render interruptible, not the update |
| Not using `memo` with `useDeferredValue` | Child still re-renders on every keystroke | Wrap child in `memo` so it skips renders when deferred value is unchanged |
| Creating a promise inside `startTransition` | Transition does not track async work | Pass the promise to a Suspense-aware setter or use `use()` |
| Checking `isPending` from wrong transition | Pending state never turns true | Each `useTransition` tracks only its own `startTransition` calls |
