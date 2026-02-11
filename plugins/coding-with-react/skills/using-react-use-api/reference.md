# use() API Reference

Complete reference for the `use()` API introduced in React 19.

## API Signature

```tsx
function use<T>(resource: Promise<T> | React.Context<T>): T;
```

`use()` accepts a Promise or Context and returns its resolved value. Unlike hooks, it can be called conditionally and inside loops.

### Rules

- Can be called inside `if` statements, loops, and after early returns
- Cannot be called inside `try-catch` blocks (use Error Boundaries instead)
- Must be called inside a component or custom hook (same as hooks)
- When reading a Promise, requires a `<Suspense>` ancestor to handle the suspended state

## Reading Promises

### Basic Pattern

```tsx
import { use, Suspense } from "react";

function UserProfile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise); // Suspends until resolved
  return <h1>{user.name}</h1>;
}

// Parent must provide Suspense boundary
function Page({ userId }: { userId: string }) {
  const userPromise = fetchUser(userId);
  return (
    <Suspense fallback={<p>Loading...</p>}>
      <UserProfile userPromise={userPromise} />
    </Suspense>
  );
}
```

### Multiple use() Calls

Multiple `use()` calls in the same component execute in sequence. Each suspends independently until its promise resolves.

```tsx
function Dashboard({
  userPromise,
  postsPromise,
}: {
  userPromise: Promise<User>;
  postsPromise: Promise<Post[]>;
}) {
  const user = use(userPromise);
  const posts = use(postsPromise);

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{posts.length} posts</p>
    </div>
  );
}

// To load in parallel, create both promises in the parent
function App({ userId }: { userId: string }) {
  const userPromise = fetchUser(userId);
  const postsPromise = fetchPosts(userId);

  return (
    <Suspense fallback={<p>Loading dashboard...</p>}>
      <Dashboard userPromise={userPromise} postsPromise={postsPromise} />
    </Suspense>
  );
}
```

### Nested Suspense Boundaries

Use nested `Suspense` to show progressive loading states.

```tsx
function Page({ userId }: { userId: string }) {
  const userPromise = fetchUser(userId);
  const postsPromise = fetchPosts(userId);

  return (
    <Suspense fallback={<p>Loading user...</p>}>
      <UserHeader userPromise={userPromise} />

      <Suspense fallback={<p>Loading posts...</p>}>
        <PostList postsPromise={postsPromise} />
      </Suspense>
    </Suspense>
  );
}
```

The user header appears first. Posts load independently with their own fallback.

## Caching Patterns for Promises

Never create a promise during render in the component that reads it. This causes infinite re-render loops.

### Create in Parent Component

```tsx
// Good -- promise created in parent
function Parent({ id }: { id: string }) {
  const dataPromise = fetchData(id);
  return (
    <Suspense fallback={<p>Loading...</p>}>
      <Child dataPromise={dataPromise} />
    </Suspense>
  );
}

function Child({ dataPromise }: { dataPromise: Promise<Data> }) {
  const data = use(dataPromise);
  return <div>{data.title}</div>;
}
```

### Cache with a Module-Level Map

```tsx
const cache = new Map<string, Promise<Data>>();

function fetchDataCached(id: string): Promise<Data> {
  if (!cache.has(id)) {
    cache.set(id, fetchData(id));
  }
  return cache.get(id)!;
}

function DataComponent({ id }: { id: string }) {
  const data = use(fetchDataCached(id)); // Same promise instance on re-render
  return <div>{data.title}</div>;
}
```

### Framework Cache (React.cache)

```tsx
import { cache } from "react";

const getUser = cache(async (id: string): Promise<User> => {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
});

// Safe to call in Server Components -- React deduplicates within a request
async function UserPage({ id }: { id: string }) {
  const user = await getUser(id);
  return <h1>{user.name}</h1>;
}
```

## Reading Context

```tsx
import { use, createContext } from "react";

const ThemeContext = createContext<"light" | "dark">("light");

function ThemedButton({ show }: { show: boolean }) {
  if (!show) return null;

  // Conditional context read -- impossible with useContext
  const theme = use(ThemeContext);
  return <button className={theme}>Click</button>;
}
```

## Integration with Frameworks

### Next.js (App Router)

Server Components can pass promises to Client Components for streaming.

```tsx
// app/page.tsx (Server Component)
import { Suspense } from "react";
import { UserCard } from "./user-card";

export default async function Page({ params }: { params: { id: string } }) {
  // Start fetching but don't await -- pass the promise
  const userPromise = fetch(`/api/users/${params.id}`).then((r) => r.json());

  return (
    <Suspense fallback={<p>Loading user...</p>}>
      <UserCard userPromise={userPromise} />
    </Suspense>
  );
}

// app/user-card.tsx (Client Component)
"use client";
import { use } from "react";

export function UserCard({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);
  return <div>{user.name}</div>;
}
```

### Remix / React Router

Loaders return deferred data that can be consumed with `use()`.

```tsx
// route module
import { defer } from "@remix-run/node";

export function loader({ params }: LoaderFunctionArgs) {
  return defer({
    user: fetchUser(params.id), // Promise, not awaited
  });
}

// component
import { useLoaderData, Await } from "@remix-run/react";
import { Suspense } from "react";

export default function UserPage() {
  const { user } = useLoaderData<typeof loader>();

  return (
    <Suspense fallback={<p>Loading...</p>}>
      <Await resolve={user}>
        {(resolvedUser) => <h1>{resolvedUser.name}</h1>}
      </Await>
    </Suspense>
  );
}
```

## TypeScript Typing

```tsx
import { use } from "react";

// Type is inferred from the Promise generic
const user = use(fetchUser()); // user: User

// Explicit typing
const data = use<CustomType>(somePromise);

// Context typing
const ThemeContext = createContext<"light" | "dark">("light");
const theme = use(ThemeContext); // theme: "light" | "dark"

// Props typing for promise-accepting components
interface Props {
  dataPromise: Promise<Data>;
}

function DataView({ dataPromise }: Props) {
  const data = use(dataPromise); // data: Data
  return <div>{data.value}</div>;
}
```

## Edge Cases

### Resolved Promise

If the promise is already resolved when `use()` reads it, the component does not suspend. It returns the value synchronously.

### Rejected Promise

If the promise rejects, the error propagates to the nearest Error Boundary. You cannot catch it with `try-catch` in the component.

### Promise Identity

React uses referential equality to track promises. If you pass a new promise object on every render, the component will re-suspend each time. Always stabilize promise identity (create in parent, cache, or use a framework data-fetching layer).

### use() Inside Loops

```tsx
function CommentList({ commentPromises }: { commentPromises: Promise<Comment>[] }) {
  const comments = commentPromises.map((p) => use(p));
  return (
    <ul>
      {comments.map((c) => (
        <li key={c.id}>{c.text}</li>
      ))}
    </ul>
  );
}
```

This works but all promises must resolve before any content renders. For progressive loading, split into separate Suspense-wrapped child components.
