---
name: building-astro-components
description: Use when creating or modifying Astro components — frontmatter scripts, template expressions, props with TypeScript interfaces, slots, named slots, fallback content, fragments, class:list binding, define:vars, CSS scoping, or server:defer islands.
---

# Building Astro Components

Astro components (`.astro` files) are HTML-only templating components that render entirely on the server with zero client-side JavaScript by default. They use a superset of HTML with JSX-like expression syntax and a frontmatter code fence for server-side logic.

## Component Structure

Every `.astro` file has two sections: an optional frontmatter script between `---` fences and the component template below it.

```astro
---
// Frontmatter: runs on the server at build time (or request time in SSR)
import BaseLayout from "../layouts/BaseLayout.astro";
import Card from "./Card.astro";

const title = "My Page";
const items = await fetch("https://api.example.com/items").then((r) => r.json());
---

<BaseLayout title={title}>
  <h1>{title}</h1>
  <ul>
    {items.map((item) => (
      <li>
        <Card name={item.name} url={item.url} />
      </li>
    ))}
  </ul>
</BaseLayout>
```

The frontmatter runs on the server only. It supports top-level `await`, imports, data fetching, and full TypeScript. The template section is standard HTML enhanced with JSX-like curly-brace expressions.

## Props with TypeScript

Define a `Props` interface in the frontmatter and destructure from `Astro.props`. Astro automatically infers prop types when other `.astro` files reference this component.

```astro
---
interface Props {
  title: string;
  description?: string;
  count: number;
}

const { title, description = "Default description", count } = Astro.props;
---

<article>
  <h2>{title}</h2>
  <p>{description}</p>
  <span>Count: {count}</span>
</article>
```

For complex or reusable types, export the interface from a separate `.ts` file and import it:

```astro
---
import type { CardProps } from "../types";

interface Props extends CardProps {
  featured?: boolean;
}

const { title, url, featured = false } = Astro.props;
---
```

## Passing `class` to Child Components

The word `class` is reserved in JavaScript. Destructure it with a rename:

```astro
---
interface Props {
  class?: string;
}

const { class: className, ...rest } = Astro.props;
---

<div class={className} {...rest}>
  <slot />
</div>
```

Usage from a parent:

```astro
<Wrapper class="mt-4 p-6">
  <p>Content inside the wrapper.</p>
</Wrapper>
```

## Template Expressions

### Conditional Rendering

```astro
---
const isLoggedIn = true;
const role = "admin";
---

{isLoggedIn && <p>Welcome back.</p>}

{role === "admin" ? (
  <AdminPanel />
) : (
  <p>Access denied.</p>
)}
```

### Iterating with map

```astro
---
const links = [
  { label: "Home", href: "/" },
  { label: "About", href: "/about" },
  { label: "Blog", href: "/blog" },
];
---

<nav>
  <ul>
    {links.map((link) => (
      <li>
        <a href={link.href}>{link.label}</a>
      </li>
    ))}
  </ul>
</nav>
```

### Dynamic HTML with set:html

Use the `set:html` directive to inject raw HTML strings. Exercise caution -- this bypasses escaping and can introduce XSS vulnerabilities if the source is not trusted.

```astro
---
const rawHtml = "<strong>Bold text</strong> from a CMS";
---

<div set:html={rawHtml} />
```

## Slots

### Default Slot

```astro
---
// Card.astro
interface Props {
  title: string;
}
const { title } = Astro.props;
---

<div class="card">
  <h3>{title}</h3>
  <slot />
</div>
```

Usage:

```astro
<Card title="Feature">
  <p>This content fills the default slot.</p>
</Card>
```

### Named Slots

```astro
---
// PageLayout.astro
---

<header>
  <slot name="header" />
</header>
<main>
  <slot />
</main>
<footer>
  <slot name="footer" />
</footer>
```

Usage:

```astro
<PageLayout>
  <h1 slot="header">Page Title</h1>
  <p>Main content goes in the default slot.</p>
  <p slot="footer">Copyright 2026</p>
</PageLayout>
```

### Fallback Content

When no content is provided for a slot, the fallback renders instead:

```astro
<aside>
  <slot name="sidebar">
    <p>Default sidebar content when nothing is passed.</p>
  </slot>
</aside>
```

### Multiple Elements in a Named Slot with Fragment

To pass multiple elements into a single named slot, wrap them in `<Fragment>`:

```astro
---
import BaseLayout from "../layouts/BaseLayout.astro";
---

<BaseLayout>
  <Fragment slot="head">
    <link rel="stylesheet" href="/extra.css" />
    <meta name="description" content="Page description" />
  </Fragment>
  <h1>Page content</h1>
</BaseLayout>
```

### Transferring Slots Between Layouts

When a layout wraps another layout, forward named slots by combining `name` and `slot` on the same `<slot>` element:

```astro
---
// ChildLayout.astro
import ParentLayout from "./ParentLayout.astro";
---

<ParentLayout>
  <slot name="head" slot="head" />
  <slot />
</ParentLayout>
```

This passes any content placed in `ChildLayout`'s `head` slot through to `ParentLayout`'s `head` slot.

## class:list Directive

The `class:list` directive accepts an array of class values. It supports strings, objects (where truthy values include the key), arrays, and `Set` instances.

```astro
---
interface Props {
  variant?: "primary" | "secondary";
  isDisabled?: boolean;
}

const { variant = "primary", isDisabled = false } = Astro.props;
---

<button
  class:list={[
    "btn",
    `btn-${variant}`,
    { "btn-disabled": isDisabled, "btn-active": !isDisabled },
  ]}
  disabled={isDisabled}
>
  <slot />
</button>
```

Falsy values are automatically filtered out. `undefined` and `null` class entries are ignored.

## CSS Variables with define:vars

Pass frontmatter values into scoped `<style>` blocks as CSS custom properties using the `define:vars` directive:

```astro
---
interface Props {
  accentColor?: string;
  fontSize?: string;
}

const { accentColor = "#3b82f6", fontSize = "1rem" } = Astro.props;
---

<div class="card">
  <slot />
</div>

<style define:vars={{ accentColor, fontSize }}>
  .card {
    border: 2px solid var(--accentColor);
    font-size: var(--fontSize);
    padding: 1.5rem;
    border-radius: 0.5rem;
  }
</style>
```

The variables are injected as inline styles on the component's root element and available as `var(--name)` in the scoped CSS.

## Scoped Styles

Styles in `<style>` tags are automatically scoped to the component using generated `data-astro-cid-*` attributes. They do not leak to child components or the rest of the page.

```astro
<h2>Styled heading</h2>
<p>Styled paragraph</p>

<style>
  h2 {
    color: navy;
  }
  p {
    line-height: 1.6;
  }
</style>
```

### Global Styles

Use `is:global` to opt out of scoping entirely:

```astro
<style is:global>
  body {
    font-family: system-ui, sans-serif;
  }
</style>
```

### Mixed Scoped and Global

Use the `:global()` selector within a scoped style block to target specific global selectors while keeping the rest scoped:

```astro
<style>
  .wrapper {
    padding: 1rem;
  }
  .wrapper :global(h2) {
    color: darkred;
  }
</style>
```

This scopes `.wrapper` to the component but applies the `h2` rule to any `h2` inside `.wrapper`, including those rendered by child components.

## Server Islands (server:defer)

Server islands defer a component's rendering until its content is available, allowing the rest of the page to ship immediately. The deferred component renders via a separate server request after the initial page load.

```astro
---
// Page.astro
import Avatar from "../components/Avatar.astro";
import GenericAvatar from "../components/GenericAvatar.astro";
---

<nav>
  <a href="/">Home</a>
  <Avatar server:defer>
    <GenericAvatar slot="fallback" />
  </Avatar>
</nav>
```

The `slot="fallback"` content renders inline with the initial HTML. Once the deferred component resolves on the server, its output replaces the fallback on the client.

### Server Island Constraints

- All props passed to a `server:defer` component must be serializable (strings, numbers, booleans, plain objects, arrays). Functions, class instances, and symbols are not supported.
- Props are encrypted and encoded in the URL of the GET request that fetches the deferred component. If the encoded props exceed 2048 bytes, Astro automatically switches from GET to POST.
- Server islands require an SSR adapter (the page cannot be fully static).

```astro
---
// UserGreeting.astro -- used with server:defer
interface Props {
  userId: string;
  displayName: string;
}

const { userId, displayName } = Astro.props;
const stats = await fetch(`https://api.example.com/users/${userId}/stats`).then((r) => r.json());
---

<div class="greeting">
  <p>Hello, {displayName}. You have {stats.unread} unread messages.</p>
</div>
```

## HTML Components

Files with a `.html` extension in `src/components/` work as components but have no frontmatter, no dynamic expressions, no TypeScript, and no imports. They are useful for static HTML fragments that need no processing:

```html
<!-- Notice.html -->
<div class="notice">
  <p>This site uses cookies.</p>
</div>
```

Usage:

```astro
---
import Notice from "../components/Notice.html";
---

<Notice />
```

HTML components cannot accept props and do not support slots.

## Common Pitfalls

1. **Frontmatter is server-only.** Code in the `---` fences never reaches the browser. Do not reference `window`, `document`, `localStorage`, or any browser API in the frontmatter. Use a `<script>` tag or a framework component with a `client:*` directive for client-side interactivity.

2. **`class` is a reserved word.** Always destructure it as `class: className` when accepting it as a prop. Using `const { class } = Astro.props` is a syntax error.

3. **Slots do not accept expressions directly.** Content placed in a named slot must be an HTML element or `<Fragment>`, not a bare expression like `{someVariable}`.

4. **`set:html` bypasses escaping.** Only use it with trusted content. Never pipe user input directly into `set:html` without sanitization.

5. **Server island prop size.** Props on `server:defer` components are serialized into the request URL. Keep prop payloads small. If you exceed 2048 bytes the request method changes from GET to POST, which may affect caching.

6. **Scoped styles do not reach child components.** A `<style>` block in a parent component does not style elements rendered by child `.astro` components. Use `:global()` selectors or pass class props to children.

7. **One `<style>` tag per component.** While multiple `<style>` tags work, they all scope to the same component. Consolidate styles for clarity.
