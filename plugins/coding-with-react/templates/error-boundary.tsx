// Error Boundary Template
// Copy this to components/error-boundary.tsx for catching render errors.
//
// What this demonstrates:
// - Class-based ErrorBoundary (React has no hook equivalent for catching render errors)
// - getDerivedStateFromError for updating state to show fallback UI
// - componentDidCatch for logging / reporting errors
// - Render prop pattern for flexible fallback UI
// - Recovery via resetErrorBoundary (retry button)
// - Composition with React.Suspense for loading + error handling
// - Full TypeScript interfaces for props and state
//
// Why a class component?
// React's error boundary API (getDerivedStateFromError, componentDidCatch) is
// only available in class components. There is no hook equivalent. The React
// team has acknowledged this gap but has not yet shipped a hook-based API.
// Class components are still fully supported and this is their primary use case.
//
// Alternative: react-error-boundary library
// If you prefer a hook-based API, the react-error-boundary package provides
// useErrorBoundary() and a pre-built <ErrorBoundary> component:
//
//   npm install react-error-boundary
//
//   import { ErrorBoundary, useErrorBoundary } from "react-error-boundary";
//
//   <ErrorBoundary
//     fallbackRender={({ error, resetErrorBoundary }) => (
//       <ErrorFallback error={error} onReset={resetErrorBoundary} />
//     )}
//     onError={(error, info) => reportError(error, info)}
//     onReset={() => queryClient.clear()}
//   >
//     <App />
//   </ErrorBoundary>
//
//   // Inside a child component, to programmatically trigger the boundary:
//   const { showBoundary } = useErrorBoundary();
//   showBoundary(new Error("Something went wrong"));

"use client";

import { Component, Suspense, type ErrorInfo, type ReactNode } from "react";

// -- Types ------------------------------------------------------------------

/** Props for the fallback render function. */
interface FallbackProps {
  error: Error;
  resetErrorBoundary: () => void;
}

interface ErrorBoundaryProps {
  children: ReactNode;
  /** Render function for the fallback UI. Receives the error and a reset function. */
  fallback: (props: FallbackProps) => ReactNode;
  /** Called when an error is caught. Use for logging or error reporting. */
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
  /** Called when the boundary resets (user clicks retry). Use to clear caches, refetch, etc. */
  onReset?: () => void;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

// -- ErrorBoundary class ----------------------------------------------------

export class ErrorBoundary extends Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  /**
   * Called during the render phase when a descendant throws.
   * Returns a partial state update — React uses this to show the fallback UI
   * on the very next render, avoiding a flash of broken content.
   */
  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  /**
   * Called during the commit phase after the error is caught.
   * This is the place for side effects like logging or error reporting.
   * Do NOT use this to update state — use getDerivedStateFromError instead.
   */
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    this.props.onError?.(error, errorInfo);
  }

  /**
   * Reset the boundary so children are rendered again.
   * Useful for "try again" buttons — the user gets a fresh attempt.
   */
  resetErrorBoundary = () => {
    this.props.onReset?.();
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError && this.state.error) {
      return this.props.fallback({
        error: this.state.error,
        resetErrorBoundary: this.resetErrorBoundary,
      });
    }
    return this.props.children;
  }
}

// -- ErrorFallback component ------------------------------------------------

/**
 * A ready-to-use fallback UI. Pass this to the ErrorBoundary's fallback prop
 * or use it as a starting point for your own design.
 */
export function ErrorFallback({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <div
      role="alert"
      className="mx-auto max-w-md rounded-lg border border-red-200 bg-red-50 p-6 text-center"
    >
      <h2 className="text-lg font-semibold text-red-800">
        Something went wrong
      </h2>
      <p className="mt-2 text-sm text-red-600">{error.message}</p>
      <button
        onClick={resetErrorBoundary}
        className="mt-4 rounded-md bg-red-600 px-4 py-2 text-sm text-white hover:bg-red-500"
      >
        Try again
      </button>
    </div>
  );
}

// -- Composition example ----------------------------------------------------

/**
 * Combining ErrorBoundary with Suspense — a common pattern for data-fetching
 * components that may throw during render (e.g., React Server Components,
 * use() hook, or libraries like TanStack Query with suspense: true).
 *
 * The ordering matters:
 * 1. ErrorBoundary wraps Suspense so that if the suspended component *throws*,
 *    the error boundary catches it rather than showing the loading fallback forever.
 * 2. Suspense wraps the async component to show a loading state while it resolves.
 *
 * Usage:
 *
 *   <AsyncBoundary
 *     loadingFallback={<Skeleton />}
 *     errorFallback={(props) => <ErrorFallback {...props} />}
 *   >
 *     <UserProfile userId="123" />
 *   </AsyncBoundary>
 */
export function AsyncBoundary({
  children,
  loadingFallback,
  errorFallback,
  onError,
  onReset,
}: {
  children: ReactNode;
  loadingFallback: ReactNode;
  errorFallback: (props: FallbackProps) => ReactNode;
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
  onReset?: () => void;
}) {
  return (
    <ErrorBoundary fallback={errorFallback} onError={onError} onReset={onReset}>
      <Suspense fallback={loadingFallback}>{children}</Suspense>
    </ErrorBoundary>
  );
}
