# React Server Components Reference

Complete guide to directives, patterns, and decision-making for React Server Components.

## Directive Reference

### Server Components (Default)

**Directive:** None required

**Characteristics:**
- Default component type in RSC-enabled frameworks
- Render on the server (at build time or per-request)
- Code never ships to the client bundle
- Can use `async`/`await` directly in the component
- Can access server-only resources (databases, filesystems, environment variables)
- Cannot use client-side hooks (`useState`, `useEffect`, etc.)
- Cannot use browser APIs or event handlers

### Client Components

**Directive:** `"use client"`

**Characteristics:**
- Must be declared at the top of the file
- Render on the client (with optional SSR)
- Can use React hooks (`useState`, `useEffect`, etc.)
- Can use event handlers and browser APIs
- Code ships to the client bundle
- Can render Server Components passed as children (via props)
- Cannot directly import Server Components

### Server Actions

**Directive:** `"use server"`

**Characteristics:**
- Creates server-side functions callable from client code
- Can be inline in Server Components or in separate files
- Always run on the server, never on the client
- Can perform mutations, database writes, and revalidation
- Can be passed as props to Client Components
- Automatically serializable

**Inline example:**
```tsx
async function Note({ id }: { id: string }) {
  async function deleteNote() {
    "use server";
    await db.notes.delete(id);
    revalidatePath("/notes");
  }

  return (
    <form action={deleteNote}>
      <button type="submit">Delete</button>
    </form>
  );
}
```

## Advanced Patterns

### Streaming Promises from Server to Client

Start data fetching on the server but resolve it on the client for progressive rendering.

```tsx
// Server Component
import { Suspense } from "react";
import { Comments } from "./Comments";

async function NotePage({ id }: { id: string }) {
  const note = await db.notes.get(id);           // await critical data
  const commentsPromise = db.comments.get(id);    // start but don't await

  return (
    <article>
      <h1>{note.title}</h1>
      <Suspense fallback={<p>Loading comments...</p>}>
        <Comments commentsPromise={commentsPromise} />
      </Suspense>
    </article>
  );
}

// Client Component
"use client";
import { use } from "react";

export function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise);
  return comments.map((comment) => (
    <div key={comment.id}>{comment.text}</div>
  ));
}
```

### Cache Signal for Cleanup

Use `cacheSignal()` to automatically abort cached fetch requests when no longer needed.

```tsx
import { cache, cacheSignal } from "react";

const fetchUser = cache(async (userId: string) => {
  const response = await fetch(`/api/users/${userId}`, {
    signal: cacheSignal(),
  });
  return response.json();
});
```

## Component Composition Rules

### What You Can Do

1. **Server Component imports Client Component**
   ```tsx
   import { Button } from "./Button"; // Client Component
   async function Page() {
     const data = await fetchData();
     return <Button label={data.label} />;
   }
   ```

2. **Server Component passes Server Component to Client Component as children**
   ```tsx
   import { Layout } from "./Layout"; // Client Component
   async function Page() {
     return (
       <Layout>
         <UserInfo user={user} /> {/* Server Component */}
       </Layout>
     );
   }
   ```

3. **Client Component uses Server Action**
   ```tsx
   "use client";
   import { createPost } from "./actions";
   export function Form() {
     return <form action={createPost}>...</form>;
   }
   ```

### What You Cannot Do

1. **Client Component imports Server Component** — pass as children instead
2. **Server Component passes non-serializable props to Client Component** — use Server Actions for functions
3. **Using browser APIs in Server Component** — move to Client Component

## Serialization Rules

Props passed from Server to Client Components must be serializable:

**Allowed:** strings, numbers, booleans, null, undefined, arrays, plain objects, Promises, Server Actions, Date objects, React elements

**Not Allowed:** functions (except Server Actions), class instances, Symbols, WeakMap, WeakSet

## Boundary Enforcement

```tsx
// lib/database.ts — errors if imported in Client Component
import "server-only";

// lib/analytics.ts — errors if imported in Server Component
import "client-only";
```

## Context Limitations

Context created in Server Components is not accessible to Client Components. Share server data via props:

```tsx
// Server Component
async function Layout({ children }) {
  const user = await fetchUser();
  return <ClientProvider user={user}>{children}</ClientProvider>;
}

// Client Component
"use client";
const UserContext = createContext(null);
export function ClientProvider({ user, children }) {
  return <UserContext value={user}>{children}</UserContext>;
}
```

## Caching

```tsx
import { cache } from "react";

// React cache — deduplicates within a single render pass
const getUser = cache(async (id: string) => {
  return await db.users.find(id);
});

// Next.js cache — persists across requests
import { unstable_cache } from "next/cache";
const getCachedUser = unstable_cache(
  async (id: string) => db.users.find(id),
  ["user"],
  { revalidate: 3600 }
);
```
