---
name: using-react-patterns
description: Use when passing refs to child components, providing context to a component tree, adding page titles or meta tags from within components, preserving component state across tab switches or visibility changes, separating event logic from effect dependencies, cleaning up refs, or preloading resources. Covers ref as prop (no forwardRef), Context as provider, document metadata, Activity, useEffectEvent, and ViewTransition.
---

# Using Modern React Patterns

## Overview

Modern React (19+) introduces patterns that simplify common tasks and eliminate boilerplate. Refs are now regular props (no `forwardRef`), Context components act as their own providers, metadata tags auto-hoist to `<head>`, and new APIs like `Activity` and `useEffectEvent` solve long-standing challenges around state preservation and effect dependencies.

## When to Use

- Forwarding refs to child components without `forwardRef` wrapper
- Managing component visibility while preserving state (tabs, modals)
- Adding document metadata (`<title>`, `<meta>`, `<link>`) within components
- Separating event logic from Effect dependencies
- Optimizing resource loading with preload/preinit APIs
- Cleaning up ref callbacks without separate effects

## Core Patterns

### Ref as Prop

```tsx
// No forwardRef needed — ref is just a prop
function MyInput({ placeholder, ref }: { placeholder: string; ref?: React.Ref<HTMLInputElement> }) {
  return <input placeholder={placeholder} ref={ref} />;
}
```

### Context as Provider

```tsx
// Context IS the provider now
<ThemeContext value="dark">{children}</ThemeContext>
```

### Document Metadata

```tsx
function BlogPost({ post }: { post: Post }) {
  return (
    <article>
      <title>{post.title}</title>
      <meta name="author" content={post.author} />
      <h1>{post.title}</h1>
    </article>
  );
}
// Metadata tags auto-hoist to <head>
```

### Activity Component

```tsx
import { Activity } from "react";

<Activity mode={activeTab === "home" ? "visible" : "hidden"}>
  <HomePage />
</Activity>
// Preserves state when hidden, unmounts effects
```

### useEffectEvent

```tsx
import { useEffect, useEffectEvent } from "react";

const onConnected = useEffectEvent(() => {
  showNotification("Connected!", theme); // Reads latest theme
});

useEffect(() => {
  conn.on("connected", onConnected);
  return () => conn.disconnect();
}, [roomId]); // theme NOT in deps
```

## Quick Reference

| Pattern | Before | After |
|---------|--------|-------|
| Ref forwarding | `forwardRef((props, ref) => ...)` | `function Comp({ ref, ...props })` |
| Context provider | `<Ctx.Provider value={v}>` | `<Ctx value={v}>` |
| Document metadata | `react-helmet` library | `<title>`, `<meta>`, `<link>` in JSX |
| Keep state hidden | `{show && <Comp />}` (unmounts) | `<Activity mode="hidden">` (preserves) |
| Effect events | Add to deps or suppress lint | `useEffectEvent(() => ...)` |
| Ref cleanup | Separate `useEffect` | Return cleanup fn from ref callback |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Implicit return in ref callback (TypeScript) | Use explicit block: `ref={(n) => { instance = n; }}` |
| Still using `forwardRef` | Switch to ref as prop (forwardRef is deprecated) |
| Using `<Context.Provider>` | Use `<Context value={...}>` directly |
| Adding `useEffectEvent` to dependency array | Never add Effect Events to deps |
| Expecting `Activity mode="hidden"` to unmount | Hidden preserves state; use conditional render for full unmount |

## Learn More

See [reference.md](./reference.md) for complete examples, resource preloading APIs, stylesheet precedence, and ViewTransition details.
