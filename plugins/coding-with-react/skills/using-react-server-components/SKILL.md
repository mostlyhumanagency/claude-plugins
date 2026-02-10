---
name: using-react-server-components
description: Use when working with React Server Components, Client Components, or Server Actions in Next.js/React apps
---

# Using React Server Components

## Overview

React Server Components (RSC) introduce a model where components render on the server by default. Server Components can fetch data directly using `async`/`await`, access databases and filesystems, and keep server-only code out of the client bundle. Client Components use the `"use client"` directive for interactivity. Server Actions use `"use server"` to create server-side functions callable from client code.

## When to Use

Use Server Components when you need to:
- Fetch data from databases or APIs
- Access server-only resources (filesystem, environment variables)
- Keep large dependencies out of the client bundle
- Perform expensive computations without blocking the client

Use Client Components when you need:
- Interactive state (`useState`, `useReducer`)
- Lifecycle effects (`useEffect`, `useLayoutEffect`)
- Event handlers (`onClick`, `onChange`)
- Browser APIs (`localStorage`, `geolocation`, `IntersectionObserver`)

Use Server Actions when you need:
- Mutations from client code (form submissions, data updates)
- Server-side validation and data processing
- Database writes with automatic revalidation

## Core Patterns

### Server Component with Async Data

```tsx
// No directive needed — Server Components are the default
import db from "./database";

async function NoteList() {
  const notes = await db.notes.getAll();
  return (
    <ul>
      {notes.map((note) => (
        <li key={note.id}>{note.title}</li>
      ))}
    </ul>
  );
}
```

### Composing Server + Client Components

```tsx
// Server Component
import { Expandable } from "./Expandable";

async function Notes() {
  const notes = await db.notes.getAll();
  return notes.map((note) => (
    <Expandable key={note.id}>
      <p>{note.content}</p>
    </Expandable>
  ));
}

// Client Component — separate file
"use client";
import { useState } from "react";

export function Expandable({ children }: { children: React.ReactNode }) {
  const [expanded, setExpanded] = useState(false);
  return (
    <div>
      <button onClick={() => setExpanded(!expanded)}>Toggle</button>
      {expanded && children}
    </div>
  );
}
```

### Server Actions

```tsx
// actions.ts
"use server";

export async function createNote(formData: FormData) {
  const title = formData.get("title") as string;
  await db.notes.create({ title });
  revalidatePath("/notes");
}

// Client Component
"use client";
import { createNote } from "./actions";

export function NewNoteForm() {
  return (
    <form action={createNote}>
      <input name="title" required />
      <button type="submit">Create</button>
    </form>
  );
}
```

## Quick Reference

| Need | Use |
|------|-----|
| Fetch data, access DB | Server Component (no directive) |
| Interactive state, events | Client Component (`"use client"`) |
| Mutate data from client | Server Action (`"use server"`) |
| Large dependencies | Server Component (keeps bundle small) |
| Browser APIs | Client Component |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `useState`/`useEffect` in Server Component | Add `"use client"` or move to Client Component child |
| Adding `"use server"` to Server Component | Remove it; Server Components need no directive |
| Importing server-only code in Client Component | Use `server-only` package to enforce boundary |
| Passing functions as props to Client Components | Pass serializable data only; use Server Actions |
| Not wrapping streamed promises in Suspense | Add `<Suspense>` around components using `use()` |

For detailed patterns including streaming and caching, see [reference.md](reference.md).
