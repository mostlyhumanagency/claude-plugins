---
name: using-react-error-boundaries
description: Use when handling errors gracefully in React apps, showing fallback UI when something crashes, adding retry or recovery buttons, preventing the whole page from breaking when one component fails, catching errors from data loading, isolating third-party widgets, or layering error handling at different levels. Covers class-based boundaries, react-error-boundary library, useErrorBoundary hook, and ErrorBoundary + Suspense composition.
---

# Using React Error Boundaries

## Overview

Error boundaries catch JavaScript errors in their child component tree, log them, and display fallback UI instead of crashing the entire app. React requires class components for built-in error boundary support, but the `react-error-boundary` library provides a modern functional API. Error boundaries work best when layered at multiple levels -- page-level for full-page fallbacks and component-level for granular recovery.

## When to Use

- Wrapping route-level components to prevent full-app crashes
- Providing retry/reset UI for recoverable errors (network failures, transient issues)
- Catching errors from Suspense-based data loading with `use()`
- Isolating third-party components that may throw
- Building granular fallback UI at different levels of the component tree

**Do NOT use when:**
- Handling errors in event handlers -- use `try-catch` instead
- Catching errors in async code outside the render path -- error boundaries only catch render errors
- You need to catch errors in Server Components -- those need server-side error handling

## Core Patterns

### Class-Based Error Boundary

```tsx
import { Component, type ReactNode, type ErrorInfo } from "react";

interface Props {
  children: ReactNode;
  fallback: ReactNode;
}

interface State {
  hasError: boolean;
}

class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(_error: Error): State {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error("Error boundary caught:", error, info.componentStack);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }
    return this.props.children;
  }
}
```

### react-error-boundary Library

The `react-error-boundary` package provides a declarative API without writing class components.

```bash
npm install react-error-boundary
```

#### Basic Usage

```tsx
import { ErrorBoundary } from "react-error-boundary";

function App() {
  return (
    <ErrorBoundary fallback={<p>Something went wrong.</p>}>
      <Dashboard />
    </ErrorBoundary>
  );
}
```

#### FallbackComponent with Error Details

```tsx
import { ErrorBoundary, type FallbackProps } from "react-error-boundary";

function ErrorFallback({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <div role="alert">
      <h2>Something went wrong</h2>
      <pre>{error.message}</pre>
      <button onClick={resetErrorBoundary}>Try again</button>
    </div>
  );
}

function App() {
  return (
    <ErrorBoundary
      FallbackComponent={ErrorFallback}
      onReset={() => {
        // Reset app state that may have caused the error
      }}
      onError={(error, info) => {
        // Log to error reporting service
        reportError(error, info.componentStack);
      }}
    >
      <Dashboard />
    </ErrorBoundary>
  );
}
```

#### useErrorBoundary Hook

Trigger error boundaries from event handlers or async code.

```tsx
import { useErrorBoundary } from "react-error-boundary";

function SaveButton({ data }: { data: FormData }) {
  const { showBoundary } = useErrorBoundary();

  async function handleSave() {
    try {
      await saveData(data);
    } catch (error) {
      showBoundary(error); // Propagates to nearest ErrorBoundary
    }
  }

  return <button onClick={handleSave}>Save</button>;
}
```

#### withErrorBoundary HOC

```tsx
import { withErrorBoundary } from "react-error-boundary";

const SafeWidget = withErrorBoundary(Widget, {
  fallback: <p>Widget failed to load.</p>,
});
```

### Error Boundary + Suspense Composition

Wrap `ErrorBoundary` around `Suspense` to handle both loading and error states.

```tsx
import { Suspense } from "react";
import { ErrorBoundary } from "react-error-boundary";

function DataSection({ dataPromise }: { dataPromise: Promise<Data> }) {
  return (
    <ErrorBoundary fallback={<p>Failed to load data.</p>}>
      <Suspense fallback={<p>Loading data...</p>}>
        <DataDisplay dataPromise={dataPromise} />
      </Suspense>
    </ErrorBoundary>
  );
}
```

### Reset with Key Prop

Reset an error boundary automatically when a key changes (e.g., route change or retry with new params).

```tsx
function UserProfile({ userId }: { userId: string }) {
  return (
    <ErrorBoundary
      key={userId}
      FallbackComponent={ErrorFallback}
    >
      <Suspense fallback={<p>Loading profile...</p>}>
        <ProfileData userId={userId} />
      </Suspense>
    </ErrorBoundary>
  );
}
```

### Granular Error Boundaries

Layer boundaries at different levels for progressive degradation.

```tsx
function App() {
  return (
    <ErrorBoundary FallbackComponent={FullPageError}>
      <Header />
      <main>
        <ErrorBoundary fallback={<p>Sidebar unavailable.</p>}>
          <Sidebar />
        </ErrorBoundary>

        <ErrorBoundary FallbackComponent={ContentError}>
          <Suspense fallback={<p>Loading content...</p>}>
            <MainContent />
          </Suspense>
        </ErrorBoundary>
      </main>
      <Footer />
    </ErrorBoundary>
  );
}
```

## Quick Reference

| API | Source | Use Case |
|-----|--------|----------|
| `getDerivedStateFromError` | React | Class method to set error state |
| `componentDidCatch` | React | Class method to log errors |
| `<ErrorBoundary>` | `react-error-boundary` | Declarative error catching with fallback UI |
| `FallbackComponent` | `react-error-boundary` | Component with `error` and `resetErrorBoundary` props |
| `useErrorBoundary()` | `react-error-boundary` | Trigger boundary from event handlers/async code |
| `withErrorBoundary()` | `react-error-boundary` | HOC wrapper for error boundary |
| `onReset` | `react-error-boundary` | Callback when boundary resets (clean up state) |
| `resetKeys` | `react-error-boundary` | Array of values -- boundary resets when any change |

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Expecting error boundaries to catch event handler errors | Error crashes the app | Use `try-catch` in handlers, or `useErrorBoundary().showBoundary()` |
| Placing only one boundary at the root | Entire app shows fallback for minor errors | Add granular boundaries around independent sections |
| Forgetting to wrap `Suspense` with `ErrorBoundary` | Rejected promise crashes instead of showing fallback | Always compose `ErrorBoundary` > `Suspense` when using `use()` |
| Not resetting boundary after transient errors | Fallback stays visible even after conditions change | Use `key` prop or `resetKeys` to auto-reset, or provide a retry button |
| Catching errors in Server Components with client boundary | Server errors not caught | Handle server errors on the server; client boundaries only catch client renders |
