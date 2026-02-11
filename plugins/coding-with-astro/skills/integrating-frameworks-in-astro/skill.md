---
name: integrating-frameworks-in-astro
description: Use when using React, Vue, Svelte, Solid, Preact, or Alpine.js components inside Astro — client directives (client:load, client:idle, client:visible, client:media, client:only), hydration behavior, passing props and children, mixing multiple frameworks, nesting framework components, or sharing state between islands.
---

# Integrating UI Frameworks in Astro

Astro supports rendering components from React, Vue, Svelte, Solid, Preact, Lit, and Alpine.js. By default, framework components render to static HTML on the server with zero client-side JavaScript. Add a `client:*` directive to hydrate a component and make it interactive in the browser.

## Installing Integrations

Use the `astro add` command to install framework integrations. Each integration adds the necessary build tooling and Vite plugins:

```bash
# React
npx astro add react

# Vue
npx astro add vue

# Svelte
npx astro add svelte

# Solid
npx astro add solid-js

# Preact
npx astro add preact

# Lit
npx astro add lit
```

The command updates `astro.config.mjs` automatically:

```js
// astro.config.mjs
import { defineConfig } from "astro/config";
import react from "@astrojs/react";
import vue from "@astrojs/vue";

export default defineConfig({
  integrations: [react(), vue()],
});
```

## Default Behavior: Zero JavaScript

Without a `client:*` directive, framework components render to static HTML at build time (or request time in SSR). No component JavaScript is sent to the browser:

```astro
---
// src/pages/index.astro
import ProductCard from "../components/ProductCard.jsx";
---

<!-- Renders to static HTML. No React runtime in the browser. -->
<ProductCard name="Widget" price={29.99} />
```

This is ideal for components that display content but do not require interactivity -- cards, headers, footers, formatted text blocks.

## Client Directives

Add a `client:*` directive to hydrate a component, sending its JavaScript to the browser and making it interactive.

### Directive Reference

| Directive | When JavaScript Loads | Use Case |
|---|---|---|
| `client:load` | Immediately when the page loads | High-priority interactive elements: navigation menus, modals, above-the-fold interactive content |
| `client:idle` | After the page finishes initial load, using `requestIdleCallback` | Medium-priority elements: forms, tooltips, non-critical widgets |
| `client:visible` | When the element enters the viewport, using `IntersectionObserver` | Below-the-fold content: comment sections, carousels, footer widgets |
| `client:media="(query)"` | When a CSS media query matches | Responsive-only elements: mobile sidebars, touch-only controls |
| `client:only="framework"` | Immediately, but skips server rendering entirely | Components that depend on browser APIs (window, document) and cannot SSR |

### client:load

```astro
---
import SearchBar from "../components/SearchBar.jsx";
---

<SearchBar client:load placeholder="Search products..." />
```

### client:idle

```astro
---
import NewsletterForm from "../components/NewsletterForm.vue";
---

<NewsletterForm client:idle />
```

### client:visible

```astro
---
import CommentSection from "../components/CommentSection.svelte";
---

<!-- Only loads when the user scrolls to this section -->
<CommentSection client:visible postId="abc-123" />
```

Pass options to the `IntersectionObserver` using a value:

```astro
<CommentSection client:visible={{ rootMargin: "200px" }} postId="abc-123" />
```

### client:media

```astro
---
import MobileNav from "../components/MobileNav.jsx";
---

<!-- Only hydrates on screens narrower than 768px -->
<MobileNav client:media="(max-width: 768px)" />
```

### client:only

Skips server rendering entirely. The component renders only in the browser. You must specify the framework name as the directive value:

```astro
---
import MapView from "../components/MapView.jsx";
import ChartDashboard from "../components/ChartDashboard.svelte";
---

<!-- No SSR -- renders only in the browser -->
<MapView client:only="react" apiKey="..." />
<ChartDashboard client:only="svelte" />
```

Valid values: `"react"`, `"vue"`, `"svelte"`, `"solid-js"`, `"preact"`, `"lit"`.

## Passing Props

Props passed from `.astro` files to framework components must be serializable when the component uses a `client:*` directive. Astro serializes props to send them alongside the component's JavaScript.

### Serializable Props

These types work as props on hydrated components:

- Strings, numbers, booleans
- `null` and `undefined`
- Arrays and plain objects (nested values must also be serializable)
- `JSON`-compatible values

### Non-Serializable Props (Hydrated Components)

These cannot be passed to hydrated components:

- Functions and callbacks
- Class instances
- Symbols
- Closures over local variables

```astro
---
import Counter from "../components/Counter.jsx";

// This works: primitive values
const initialCount = 5;

// This does NOT work with client directives:
// const onClick = () => console.log("clicked");
---

<!-- Primitives and plain objects are fine -->
<Counter client:load initialCount={initialCount} label="Items" />

<!-- Functions cannot be serialized for hydrated components -->
<!-- <Counter client:load onClick={onClick} /> -- ERROR -->
```

For static (non-hydrated) components, any prop type works because rendering happens entirely on the server:

```astro
---
import StaticList from "../components/StaticList.jsx";

const formatItem = (item) => item.toUpperCase();
---

<!-- No client directive, so functions as props are fine -->
<StaticList items={["a", "b", "c"]} formatter={formatItem} />
```

## Passing Children and Slots

### React (children prop)

Astro passes nested content as the `children` prop:

```astro
---
import Wrapper from "../components/Wrapper.jsx";
---

<Wrapper client:load>
  <p>This becomes props.children in React.</p>
</Wrapper>
```

The React component:

```jsx
// src/components/Wrapper.jsx
export default function Wrapper({ children }) {
  return <div className="wrapper">{children}</div>;
}
```

### Vue and Svelte (default slot)

Nested content is passed as the default slot:

```astro
---
import Card from "../components/Card.vue";
---

<Card client:load title="Feature">
  <p>This renders in the default slot.</p>
</Card>
```

Vue component:

```vue
<!-- src/components/Card.vue -->
<template>
  <div class="card">
    <h3>{{ title }}</h3>
    <slot />
  </div>
</template>

<script setup>
defineProps({ title: String });
</script>
```

### Named Slots

Astro supports named slots for Vue, Svelte, and Solid components:

```astro
---
import Layout from "../components/Layout.vue";
---

<Layout client:load>
  <h1 slot="header">Page Title</h1>
  <p>Default slot content.</p>
  <span slot="footer">Footer text</span>
</Layout>
```

Vue component with named slots:

```vue
<!-- src/components/Layout.vue -->
<template>
  <header>
    <slot name="header" />
  </header>
  <main>
    <slot />
  </main>
  <footer>
    <slot name="footer" />
  </footer>
</template>
```

### Astro Components Cannot Be Imported in Framework Files

You cannot import `.astro` components inside `.jsx`, `.vue`, or `.svelte` files. Astro components are server-only and have no framework runtime representation. Instead, pass Astro-rendered content as children or slots:

```astro
---
// This works: Astro renders its component, passes result as children
import ReactWrapper from "../components/ReactWrapper.jsx";
import AstroCard from "../components/AstroCard.astro";
---

<ReactWrapper client:load>
  <AstroCard title="Rendered by Astro, passed as children" />
</ReactWrapper>
```

## Mixing Multiple Frameworks

You can use components from different frameworks on the same `.astro` page. Each framework component is an independent island:

```astro
---
// src/pages/index.astro
import ReactCounter from "../components/ReactCounter.jsx";
import VueToggle from "../components/VueToggle.vue";
import SvelteAccordion from "../components/SvelteAccordion.svelte";
---

<h1>Multi-framework page</h1>

<section>
  <ReactCounter client:load initialCount={0} />
</section>

<section>
  <VueToggle client:idle label="Dark mode" />
</section>

<section>
  <SvelteAccordion client:visible items={accordionData} />
</section>
```

Each component ships only its own framework runtime. A page with one React component and one Vue component includes both the React and Vue runtimes, but they load independently.

## Nesting Hydrated Components

Framework components can nest other components from the same framework:

```jsx
// src/components/Dashboard.jsx
import Chart from "./Chart.jsx";
import Stats from "./Stats.jsx";

export default function Dashboard({ data }) {
  return (
    <div className="dashboard">
      <Stats total={data.total} average={data.average} />
      <Chart points={data.points} />
    </div>
  );
}
```

```astro
---
import Dashboard from "../components/Dashboard.jsx";
---

<!-- The entire React tree hydrates as one island -->
<Dashboard client:load data={dashboardData} />
```

However, you cannot nest a hydrated component from one framework inside a hydrated component from a different framework. Each island must use a single framework. Mix frameworks at the `.astro` page level only.

## Framework Bundling Optimization

When using multiple components from the same framework, Astro bundles them together into a single framework runtime chunk. For example, five React components on one page share one copy of the React runtime, not five.

To optimize further, keep `client:*` directives off components that do not need interactivity. Every hydrated component adds to the JavaScript payload, while static components add zero JavaScript.

### Measuring Impact

Hydrated components include:
- The framework runtime (React ~40KB gzipped, Vue ~30KB, Svelte ~2KB, Solid ~7KB, Preact ~4KB)
- The component code itself
- Any npm dependencies the component imports

Static components include none of the above. For content-heavy sites, prefer static rendering and add `client:*` only where interaction is required.

## Common Pitfalls

1. **Missing `client:*` means no interactivity.** A React component without a client directive renders to static HTML. Click handlers, `useState`, `useEffect`, and all client-side logic are stripped. If the component appears broken, check that you added a directive.

2. **Functions cannot be passed as props to hydrated components.** Astro serializes props for delivery to the browser. Functions are not serializable. Define event handlers inside the framework component itself, not in Astro frontmatter.

3. **`client:only` skips SSR.** The component is not server-rendered at all, which means no HTML appears for that component in the initial page source. This hurts SEO and perceived load time. Use it only for components that genuinely cannot render on the server.

4. **Astro components cannot be imported in framework files.** You cannot `import AstroCard from "./AstroCard.astro"` inside a `.jsx` or `.vue` file. Use the slot/children pattern to compose Astro content with framework components.

5. **Cross-framework nesting is not supported.** A React island cannot contain a Vue component and vice versa. Compose mixed-framework layouts at the `.astro` page level using multiple independent islands.

6. **Children of hydrated components must be simple HTML.** Complex Astro expressions or other Astro components passed as children to hydrated framework components are rendered to static HTML first. They do not become reactive framework elements.

7. **Each `client:only` component must specify its framework.** The value is required (`client:only="react"`, not just `client:only`) because Astro cannot infer the framework without server-rendering the component.
