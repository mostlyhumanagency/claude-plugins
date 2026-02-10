# Async Patterns in TypeScript

Promises, async/await, error handling, concurrency patterns.

## Table of Contents

- [Async Fundamentals](#async-fundamentals)
- [Concurrency Patterns](#concurrency-patterns)
- [Cancellation](#cancellation)
- [Async Iterators (TS 5.6+)](#async-iterators-ts-56)
- [Stream Processing](#stream-processing)
- [Anti-Patterns](#anti-patterns)
- [Summary](#summary)

## Async Fundamentals

> **Reminder:** Use `async`/`await` over raw Promise chains. Type all returns as `Promise<T>`. Use `unknown` for parsed data, never `any`. Top-level await requires ES2022+.

### Error Handling

```typescript
// ✅ Try-catch
async function safeGetUser(id: string): Promise<Result<User>> {
  try {
    const user = await getUser(id);
    return { ok: true, value: user };
  } catch (error) {
    if (error instanceof Error) {
      return { ok: false, error };
    }
    return { ok: false, error: new Error("Unknown error") };
  }
}

// ✅ Result type pattern
type AsyncResult<T, E = Error> = Promise<Result<T, E>>;

async function fetchData(): AsyncResult<Data> {
  try {
    const response = await fetch("/api/data");
    const data: unknown = await response.json();

    if (isValidData(data)) {
      return { ok: true, value: data };
    }
    return { ok: false, error: new Error("Invalid data") };
  } catch (error) {
    if (error instanceof Error) {
      return { ok: false, error };
    }
    return { ok: false, error: new Error("Unknown error") };
  }
}
```

## Concurrency Patterns

### Sequential vs. Parallel

```typescript
// ❌ Sequential - slow
async function fetchAllSequential(ids: string[]): Promise<User[]> {
  const users: User[] = [];
  for (const id of ids) {
    users.push(await getUser(id)); // waits for each
  }
  return users;
}

// ✅ Parallel - fast
async function fetchAllParallel(ids: string[]): Promise<User[]> {
  const promises = ids.map(id => getUser(id));
  return Promise.all(promises);
}
```

### Promise Combinators

```typescript
// Promise.all - wait for all, fail on first rejection
const [user, profile, settings] = await Promise.all([
  getUser(id),
  getProfile(id),
  getSettings(id)
]);

// Promise.allSettled - wait for all, never reject
const results = await Promise.allSettled([
  getUser("1"),
  getUser("2"),
  getUser("3")
]);

results.forEach(result => {
  if (result.status === "fulfilled") {
    console.log(result.value);
  } else {
    console.error(result.reason);
  }
});

// Promise.race - first to complete wins
const result = await Promise.race([
  fetchFromPrimary(),
  fetchFromBackup()
]);

// Promise.any - first success wins (TS 5.6+)
const result = await Promise.any([
  fetchFromServer1(),
  fetchFromServer2(),
  fetchFromServer3()
]);
```

### Retry Pattern

```typescript
async function retry<T>(
  fn: () => Promise<T>,
  options: { maxAttempts: number; delay: number }
): Promise<T> {
  for (let attempt = 1; attempt <= options.maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === options.maxAttempts) throw error;
      await new Promise(resolve => setTimeout(resolve, options.delay));
    }
  }
  throw new Error("Unreachable");
}

// Usage
const data = await retry(
  () => fetchData(),
  { maxAttempts: 3, delay: 1000 }
);
```

### Timeout Pattern

```typescript
async function withTimeout<T>(
  promise: Promise<T>,
  ms: number
): Promise<T> {
  const timeout = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new Error("Timeout")), ms)
  );
  return Promise.race([promise, timeout]);
}

// Usage
const user = await withTimeout(getUser("123"), 5000);
```

## Cancellation

Use `AbortController` to cancel in-flight work (fetch, timers, and custom tasks):

```typescript
async function fetchWithCancel(url: string, timeoutMs: number): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    return await fetch(url, { signal: controller.signal });
  } finally {
    clearTimeout(timeoutId);
  }
}
```

For cooperative cancellation in your own APIs, accept `AbortSignal` and check `signal.aborted` or listen for the `abort` event:

```typescript
async function doWork(signal: AbortSignal): Promise<void> {
  if (signal.aborted) throw signal.reason;

  return new Promise((resolve, reject) => {
    const onAbort = () => reject(signal.reason);
    signal.addEventListener("abort", onAbort, { once: true });

    setTimeout(() => {
      signal.removeEventListener("abort", onAbort);
      resolve();
    }, 200);
  });
}
```

### Debounce/Throttle Async

```typescript
function debounceAsync<Args extends readonly unknown[], Result>(
  fn: (...args: Args) => Promise<Result>,
  delay: number
): (...args: Args) => Promise<Result> {
  let timeoutId: ReturnType<typeof setTimeout> | null = null;
  let pending: Array<{
    resolve: (value: Result) => void;
    reject: (reason: unknown) => void;
  }> = [];

  return (...args): Promise<Result> => {
    return new Promise((resolve, reject) => {
      pending.push({ resolve, reject });

      if (timeoutId) clearTimeout(timeoutId);

      timeoutId = setTimeout(async () => {
        const current = pending;
        pending = [];

        try {
          const result = await fn(...args);
          for (const { resolve: resolvePending } of current) {
            resolvePending(result);
          }
        } catch (error) {
          for (const { reject: rejectPending } of current) {
            rejectPending(error);
          }
        }
      }, delay);
    });
  };
}

// Usage — wrap a concrete function, return type stays narrow at call site
const debouncedSearch = debounceAsync(
  (query: string) => searchApi(query), 300
);
```

## Async Iterators (TS 5.6+)

```typescript
async function* fetchPages(
  baseUrl: string
): AsyncGenerator<User[], void, unknown> {
  let page = 1;
  while (true) {
    const response = await fetch(`${baseUrl}?page=${page}`);
    const users: User[] = await response.json();

    if (users.length === 0) break;

    yield users;
    page++;
  }
}

// Consume async iterator
for await (const users of fetchPages("/api/users")) {
  console.log(`Got ${users.length} users`);
}

// Iterator helpers (TS 5.6+)
const allUsers = await fetchPages("/api/users")
  .flatMap(users => users)
  .filter(user => user.active)
  .toArray();
```

## Stream Processing

```typescript
async function processStream<T, U>(
  items: AsyncIterable<T>,
  transform: (item: T) => Promise<U>
): AsyncGenerator<U> {
  for await (const item of items) {
    yield await transform(item);
  }
}

// Usage
async function* numbers() {
  for (let i = 0; i < 100; i++) yield i;
}

const doubled = processStream(numbers(), async n => {
  await delay(10);
  return n * 2;
});

for await (const n of doubled) {
  console.log(n);
}
```

## Quick Reference

| Pattern | Syntax | Use When |
|---|---|---|
| Result wrapper | `Promise<Result<T>>` | Async function that can fail gracefully |
| Promise.all | `await Promise.all([...])` | Running independent async ops in parallel |
| Promise.allSettled | `await Promise.allSettled([...])` | Parallel ops where some may fail |
| Promise.race | `await Promise.race([...])` | First-to-complete wins (timeout pattern) |
| AbortController | `new AbortController()` | Cancelling fetch or custom async work |
| Retry | `retry(fn, { maxAttempts, delay })` | Transient failure recovery |
| Timeout | `Promise.race([promise, timeout])` | Bounding async operation duration |
| Async generator | `async function*` | Streaming/paginated data |
| Debounce async | `debounceAsync(fn, delay)` | Rate-limiting async calls (search, API) |

## Anti-Patterns

### ❌ Unhandled Rejections

```typescript
// BAD
async function process() {
  await riskyOperation(); // If this throws, it's unhandled
}

process(); // Floating promise!

// GOOD
process().catch(error => console.error(error));

// OR
async function main() {
  try {
    await process();
  } catch (error) {
    console.error(error);
  }
}

main();
```

### ❌ Mixing Promises and Callbacks

```typescript
// BAD
function fetchUser(id: string): Promise<User> {
  return new Promise((resolve, reject) => {
    oldCallbackAPI(id, (error, user) => {
      if (error) reject(error);
      else resolve(user);
    });
  });
}

// GOOD - use util.promisify or native async APIs
import { promisify } from 'util';
const fetchUser = promisify(oldCallbackAPI);
```

### ❌ Sequential When Parallel Possible

```typescript
// BAD - 3 seconds total
async function fetchAll() {
  const user = await getUser(); // 1s
  const posts = await getPosts(); // 1s
  const comments = await getComments(); // 1s
  return { user, posts, comments };
}

// GOOD - 1 second total (parallel)
async function fetchAll() {
  const [user, posts, comments] = await Promise.all([
    getUser(),
    getPosts(),
    getComments()
  ]);
  return { user, posts, comments };
}
```

## Summary

- Use async/await for readable async code
- Handle errors with try/catch or Result types
- Parallelize independent operations with Promise.all
- Use async iterators for streaming data
- Avoid unhandled promise rejections
