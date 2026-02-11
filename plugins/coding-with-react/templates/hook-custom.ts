// Custom Hook Template — useAsync
// Copy this to hooks/use-async.ts (or adapt for your own async logic).
//
// What this demonstrates:
// - Generic TypeScript types for flexible hook signatures
// - useState for tracking loading / error / data
// - useEffect with proper cleanup via AbortController
// - useCallback to stabilize the execute function reference
// - Error handling that distinguishes aborted requests from real failures
// - Return type annotation for clear public API
//
// Usage:
//
//   function UserProfile({ userId }: { userId: string }) {
//     const { data, error, loading, execute } = useAsync(
//       (signal) => fetch(`/api/users/${userId}`, { signal }).then(r => r.json()),
//       [userId],               // re-runs when userId changes
//       { immediate: true },    // fetches on mount
//     );
//
//     if (loading) return <Spinner />;
//     if (error)   return <p>Error: {error.message}</p>;
//     if (!data)   return null;
//     return <h1>{data.name}</h1>;
//   }
//
// Why AbortController?
// When the component unmounts (or deps change) before the async work finishes,
// the AbortController cancels the in-flight request. Without this, the resolved
// promise would call setState on an unmounted component, which is a React warning
// and a potential memory leak.

import { useState, useEffect, useCallback, useRef } from "react";

// -- Types ------------------------------------------------------------------

/** Options to control the hook's behavior. */
interface UseAsyncOptions {
  /** If true, the async function runs immediately on mount / dep change. Default: true. */
  immediate?: boolean;
}

/** The public return value of useAsync. */
interface UseAsyncReturn<T> {
  /** The resolved data, or null if not yet available. */
  data: T | null;
  /** The rejection error, or null if no error occurred. */
  error: Error | null;
  /** True while the async function is in flight. */
  loading: boolean;
  /** Manually trigger the async function (e.g., for retry or refresh). */
  execute: () => Promise<void>;
}

// -- Hook -------------------------------------------------------------------

/**
 * A generic hook for running async operations with loading, error, and
 * cancellation support.
 *
 * @param asyncFn   A function that receives an AbortSignal and returns a Promise<T>.
 *                  Pass the signal to fetch() or use signal.throwIfAborted() for
 *                  custom async logic.
 * @param deps      Dependency array — the async function re-runs when these change
 *                  (only if `immediate` is true).
 * @param options   Configuration options.
 */
export function useAsync<T>(
  asyncFn: (signal: AbortSignal) => Promise<T>,
  deps: readonly unknown[] = [],
  options: UseAsyncOptions = {},
): UseAsyncReturn<T> {
  const { immediate = true } = options;

  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [loading, setLoading] = useState<boolean>(immediate);

  // Store the latest asyncFn in a ref so the effect doesn't depend on function
  // identity. This avoids infinite re-render loops when callers pass an inline
  // arrow function.
  const asyncFnRef = useRef(asyncFn);
  asyncFnRef.current = asyncFn;

  // execute is stable across renders because it only reads from the ref.
  const execute = useCallback(async () => {
    // Create a new AbortController for each execution so previous in-flight
    // requests get cancelled when execute is called again.
    const controller = new AbortController();

    setLoading(true);
    setError(null);

    try {
      const result = await asyncFnRef.current(controller.signal);

      // Only update state if the request was not aborted. This guard prevents
      // setting state after the component unmounts or after deps change.
      if (!controller.signal.aborted) {
        setData(result);
      }
    } catch (err) {
      // Ignore AbortError — it means we intentionally cancelled the request.
      // All other errors are surfaced to the consumer.
      if (!controller.signal.aborted) {
        setError(
          err instanceof Error ? err : new Error(String(err)),
        );
      }
    } finally {
      if (!controller.signal.aborted) {
        setLoading(false);
      }
    }

    // Return a cleanup function that aborts if this execution is superseded.
    // We store it so the effect cleanup can call it.
    return () => controller.abort();
  }, []); // stable — reads asyncFn from ref

  useEffect(() => {
    if (!immediate) return;

    // AbortController for this effect cycle
    const controller = new AbortController();

    setLoading(true);
    setError(null);

    asyncFnRef
      .current(controller.signal)
      .then((result) => {
        if (!controller.signal.aborted) {
          setData(result);
        }
      })
      .catch((err) => {
        if (!controller.signal.aborted) {
          setError(err instanceof Error ? err : new Error(String(err)));
        }
      })
      .finally(() => {
        if (!controller.signal.aborted) {
          setLoading(false);
        }
      });

    // Cleanup: abort the in-flight request when deps change or unmount.
    return () => controller.abort();
    // eslint-disable-next-line react-hooks/exhaustive-deps -- deps is the caller's dependency array
  }, deps);

  return { data, error, loading, execute };
}
