---
name: styling-astro-components
description: "Use when adding CSS to Astro components, setting up Tailwind CSS, using Sass/SCSS, or applying scoped and global styles. Use for tasks like 'add styles to a component', 'set up Tailwind in Astro', 'use SCSS in Astro', 'pass CSS variables from frontmatter', or 'fix styles not applying'. Also covers is:global directive, class:list utility, define:vars, PostCSS configuration, CSS modules in framework components, importing external stylesheets, and debugging style scoping conflicts."
---

# Styling Astro Components

Astro components support scoped CSS out of the box. Add a `<style>` tag inside any `.astro` component and its styles are automatically scoped to that component.

## Scoped Styles

Styles in a `<style>` tag are scoped by default. Astro adds a unique `data-astro-cid-*` attribute to every element in the component and rewrites selectors to match.

```astro
---
// src/components/Card.astro
const { title } = Astro.props;
---

<div class="card">
  <h2>{title}</h2>
  <slot />
</div>

<style>
  .card {
    padding: 1.5rem;
    border: 1px solid #e2e8f0;
    border-radius: 0.5rem;
  }

  h2 {
    margin-top: 0;
    font-size: 1.25rem;
  }
</style>
```

The compiled output transforms `.card` into something like `.card[data-astro-cid-abc123]`, preventing style leakage to other components.

### Scoping Rules

- Scoped styles do NOT cascade into child components. Each component is isolated.
- If you need to style elements inside a child component, use `:global()` or `is:global`.
- HTML elements rendered by the same component are scoped automatically.

## Global Styles

### The `is:global` Attribute

Add `is:global` to a `<style>` tag to emit styles without scoping.

```astro
---
// src/layouts/BaseLayout.astro
---

<html>
  <head><slot name="head" /></head>
  <body><slot /></body>
</html>

<style is:global>
  *,
  *::before,
  *::after {
    box-sizing: border-box;
  }

  body {
    margin: 0;
    font-family: system-ui, -apple-system, sans-serif;
    line-height: 1.6;
    color: #1a202c;
  }

  a {
    color: #2563eb;
    text-decoration: none;
  }

  a:hover {
    text-decoration: underline;
  }
</style>
```

### The `:global()` Selector

Use `:global()` within a scoped `<style>` block to target specific selectors globally while keeping the rest scoped.

```astro
---
// src/components/Markdown.astro
---

<div class="prose">
  <slot />
</div>

<style>
  .prose {
    max-width: 65ch;
  }

  /* Target elements rendered by child components or injected HTML */
  .prose :global(h1) {
    font-size: 2rem;
    margin-bottom: 1rem;
  }

  .prose :global(pre) {
    background: #1e293b;
    color: #e2e8f0;
    padding: 1rem;
    border-radius: 0.375rem;
    overflow-x: auto;
  }

  .prose :global(code) {
    font-size: 0.875em;
  }
</style>
```

The `.prose` selector remains scoped; the inner selectors like `h1` and `pre` apply globally within that scoped container.

### Combining Scoped and Global

```astro
<style>
  /* Scoped to this component */
  .wrapper {
    padding: 2rem;
  }

  /* Global: targets child component internals */
  .wrapper :global(.child-class) {
    margin-top: 1rem;
  }

  /* Global: targets a deeply nested element */
  :global(.theme-dark) .wrapper {
    background: #0f172a;
  }
</style>
```

## class:list Directive

Astro provides a `class:list` directive that accepts an array of values and resolves them into a class string. Powered by `clsx` internally.

```astro
---
// src/components/Button.astro
interface Props {
  variant?: "primary" | "secondary" | "danger";
  size?: "sm" | "md" | "lg";
  disabled?: boolean;
  class?: string;
}

const { variant = "primary", size = "md", disabled = false, class: className } = Astro.props;
---

<button
  class:list={[
    "btn",
    `btn-${variant}`,
    `btn-${size}`,
    { "btn-disabled": disabled },
    className,
  ]}
  disabled={disabled}
>
  <slot />
</button>

<style>
  .btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border: none;
    border-radius: 0.375rem;
    font-weight: 600;
    cursor: pointer;
    transition: background-color 0.15s;
  }

  .btn-primary {
    background: #2563eb;
    color: white;
  }

  .btn-secondary {
    background: #e2e8f0;
    color: #1e293b;
  }

  .btn-danger {
    background: #dc2626;
    color: white;
  }

  .btn-sm { padding: 0.375rem 0.75rem; font-size: 0.875rem; }
  .btn-md { padding: 0.5rem 1rem; font-size: 1rem; }
  .btn-lg { padding: 0.75rem 1.5rem; font-size: 1.125rem; }

  .btn-disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
</style>
```

### class:list Accepted Value Types

```astro
<div class:list={[
  "always-applied",                    // string -- always included
  condition && "conditional",          // string|false -- included when truthy
  { "object-syntax": booleanVar },     // object -- key included when value is truthy
  ["nested", "array"],                 // array -- flattened
  new Set(["set-value"]),              // Set -- expanded
]}>
```

## define:vars for CSS Variables

Pass JavaScript variables from the frontmatter into scoped CSS using `define:vars`.

```astro
---
// src/components/ProgressBar.astro
interface Props {
  value: number;
  max?: number;
  color?: string;
  height?: string;
}

const { value, max = 100, color = "#2563eb", height = "0.5rem" } = Astro.props;
const percentage = Math.min(100, Math.max(0, (value / max) * 100));
---

<div class="progress">
  <div class="progress-bar" role="progressbar" aria-valuenow={value} aria-valuemin={0} aria-valuemax={max}>
  </div>
</div>

<style define:vars={{ percentage: `${percentage}%`, color, height }}>
  .progress {
    width: 100%;
    height: var(--height);
    background: #e2e8f0;
    border-radius: 9999px;
    overflow: hidden;
  }

  .progress-bar {
    width: var(--percentage);
    height: 100%;
    background: var(--color);
    transition: width 0.3s ease;
  }
</style>
```

Variables are set as inline styles on the component's root element using `--` custom properties. They work in both scoped and `is:global` style tags.

### define:vars with Multiple Variables

```astro
---
const theme = {
  primary: "#2563eb",
  secondary: "#64748b",
  radius: "0.5rem",
  spacing: "1rem",
};
---

<div class="themed-card">
  <slot />
</div>

<style define:vars={{
  primary: theme.primary,
  secondary: theme.secondary,
  radius: theme.radius,
  spacing: theme.spacing,
}}>
  .themed-card {
    background: white;
    border: 2px solid var(--primary);
    border-radius: var(--radius);
    padding: var(--spacing);
    color: var(--secondary);
  }
</style>
```

## Passing className to Child Components

Astro components cannot pass scoped styles to children. Accept a `class` prop and apply it manually.

```astro
---
// src/components/Badge.astro
interface Props {
  class?: string;
}

const { class: className } = Astro.props;
---

<span class:list={["badge", className]}>
  <slot />
</span>

<style>
  .badge {
    display: inline-block;
    padding: 0.125rem 0.5rem;
    font-size: 0.75rem;
    font-weight: 600;
    border-radius: 9999px;
    background: #dbeafe;
    color: #1e40af;
  }
</style>
```

Usage:

```astro
---
import Badge from "../components/Badge.astro";
---

<Badge class="custom-override">New</Badge>

<style>
  /* This won't work because scoped styles don't cascade into Badge */
  /* Use :global() to target it */
  :global(.custom-override) {
    background: #fef3c7;
    color: #92400e;
  }
</style>
```

## Inline Styles

Astro supports inline styles via the `style` attribute. Both string and object syntax are accepted.

### String Syntax

```astro
<div style="background-color: #f1f5f9; padding: 1rem; border-radius: 0.5rem;">
  Content
</div>
```

### Object Syntax

```astro
---
const dynamicStyles = {
  backgroundColor: "#f1f5f9",
  padding: "1rem",
  borderRadius: "0.5rem",
  fontSize: `${1.25}rem`,
};
---

<div style={dynamicStyles}>
  Content with dynamic styles
</div>
```

Use camelCase property names when using object syntax.

## External Stylesheets

### Import in Frontmatter

Import a CSS file in the frontmatter. Astro processes, optimizes, and bundles it automatically.

```astro
---
// src/layouts/BaseLayout.astro
import "../styles/global.css";
import "../styles/typography.css";
---

<html>
  <body><slot /></body>
</html>
```

This works for both `.css` files and preprocessor files (`.scss`, `.less`, etc.) when the appropriate package is installed.

### Link Tag

Use a standard `<link>` tag for stylesheets in the `public/` directory (not processed by Astro).

```astro
<head>
  <link rel="stylesheet" href="/styles/reset.css" />
</head>
```

Files referenced via `<link>` are served as-is from the `public/` directory without bundling or processing.

### npm Package Stylesheets

Import CSS from npm packages directly.

```astro
---
import "open-props/style";
import "normalize.css";
---
```

## CSS Preprocessors

Astro supports Sass, Stylus, and Less natively. Install the preprocessor package and use the `lang` attribute on the `<style>` tag.

### Sass / SCSS

```bash
npm install sass
```

```astro
---
// src/components/Navigation.astro
---

<nav class="nav">
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="/about">About</a></li>
    <li><a href="/blog">Blog</a></li>
  </ul>
</nav>

<style lang="scss">
  $nav-bg: #1e293b;
  $nav-link-color: #e2e8f0;
  $nav-link-hover: #60a5fa;

  .nav {
    background: $nav-bg;
    padding: 0.75rem 1.5rem;

    ul {
      display: flex;
      gap: 1.5rem;
      list-style: none;
      margin: 0;
      padding: 0;
    }

    a {
      color: $nav-link-color;
      text-decoration: none;
      font-weight: 500;
      transition: color 0.15s;

      &:hover {
        color: $nav-link-hover;
      }
    }
  }
</style>
```

Use `lang="sass"` for indented Sass syntax or `lang="scss"` for SCSS (braces) syntax.

### Less

```bash
npm install less
```

```astro
<style lang="less">
  @primary: #2563eb;
  @radius: 0.375rem;

  .card {
    border: 1px solid lighten(@primary, 40%);
    border-radius: @radius;
    padding: 1rem;

    &:hover {
      border-color: @primary;
    }
  }
</style>
```

### Stylus

```bash
npm install stylus
```

```astro
<style lang="styl">
  primary = #2563eb

  .card
    border 1px solid lighten(primary, 40%)
    border-radius 0.375rem
    padding 1rem

    &:hover
      border-color primary
</style>
```

### Importing Preprocessor Partials

Import shared variables, mixins, and utilities from external files.

```astro
<style lang="scss">
  @use "../styles/variables" as *;
  @use "../styles/mixins" as *;

  .hero {
    @include responsive-padding;
    background: $color-primary;
  }
</style>
```

## Tailwind CSS 4 Integration

### Setup

```bash
npx astro add tailwind
```

This installs `@tailwindcss/vite` and configures it in `astro.config.mjs` automatically.

The generated configuration:

```js
// astro.config.mjs
import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  vite: {
    plugins: [tailwindcss()],
  },
});
```

### Import Tailwind

Create a base CSS file and import it in your layout.

```css
/* src/styles/global.css */
@import "tailwindcss";
```

```astro
---
// src/layouts/BaseLayout.astro
import "../styles/global.css";
---

<html>
  <head><slot name="head" /></head>
  <body><slot /></body>
</html>
```

### Using Tailwind Classes

```astro
---
// src/components/Card.astro
const { title, description } = Astro.props;
---

<div class="rounded-lg border border-gray-200 p-6 shadow-sm hover:shadow-md transition-shadow">
  <h2 class="text-xl font-semibold text-gray-900 mb-2">{title}</h2>
  <p class="text-gray-600 leading-relaxed">{description}</p>
</div>
```

### Tailwind with class:list

```astro
---
interface Props {
  variant: "info" | "warning" | "error";
}

const { variant } = Astro.props;

const variantClasses = {
  info: "bg-blue-50 border-blue-200 text-blue-800",
  warning: "bg-yellow-50 border-yellow-200 text-yellow-800",
  error: "bg-red-50 border-red-200 text-red-800",
};
---

<div class:list={["rounded-lg border p-4", variantClasses[variant]]}>
  <slot />
</div>
```

### Tailwind with Scoped Styles

Tailwind utility classes and Astro scoped styles can coexist.

```astro
<div class="flex items-center gap-4 custom-wrapper">
  <slot />
</div>

<style>
  .custom-wrapper {
    /* Scoped styles work alongside Tailwind utilities */
    container-type: inline-size;
  }
</style>
```

### Tailwind 4 Theme Configuration

Tailwind 4 uses CSS-based configuration instead of `tailwind.config.js`.

```css
/* src/styles/global.css */
@import "tailwindcss";

@theme {
  --color-brand: #2563eb;
  --color-brand-light: #dbeafe;
  --font-family-display: "Inter", sans-serif;
  --breakpoint-3xl: 1920px;
}
```

## PostCSS Configuration

Astro includes PostCSS by default. Configure it with a `postcss.config.mjs` file in the project root.

```js
// postcss.config.mjs
export default {
  plugins: {
    autoprefixer: {},
    "postcss-nesting": {},
  },
};
```

```bash
npm install autoprefixer postcss-nesting
```

PostCSS processes all CSS, including scoped styles in Astro components.

## Framework-Specific Styles

### CSS Modules in React / Preact

```css
/* src/components/Counter.module.css */
.counter {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.count {
  font-size: 1.5rem;
  font-weight: 700;
  min-width: 3ch;
  text-align: center;
}

.button {
  padding: 0.5rem 1rem;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
  background: white;
  cursor: pointer;
}

.button:hover {
  background: #f3f4f6;
}
```

```tsx
// src/components/Counter.tsx
import { useState } from "react";
import styles from "./Counter.module.css";

export default function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div className={styles.counter}>
      <button className={styles.button} onClick={() => setCount(count - 1)}>-</button>
      <span className={styles.count}>{count}</span>
      <button className={styles.button} onClick={() => setCount(count + 1)}>+</button>
    </div>
  );
}
```

### Scoped Styles in Vue

```vue
<!-- src/components/Toggle.vue -->
<template>
  <button :class="['toggle', { active: isOn }]" @click="isOn = !isOn">
    {{ isOn ? "On" : "Off" }}
  </button>
</template>

<script setup>
import { ref } from "vue";
const isOn = ref(false);
</script>

<style scoped>
.toggle {
  padding: 0.5rem 1.5rem;
  border: 2px solid #d1d5db;
  border-radius: 9999px;
  background: white;
  cursor: pointer;
  transition: all 0.2s;
}

.toggle.active {
  background: #2563eb;
  border-color: #2563eb;
  color: white;
}
</style>
```

### Scoped Styles in Svelte

```svelte
<!-- src/components/Alert.svelte -->
<script>
  export let type = "info";
  export let message = "";
</script>

<div class="alert alert-{type}">
  {message}
</div>

<style>
  .alert {
    padding: 1rem;
    border-radius: 0.375rem;
    font-weight: 500;
  }

  .alert-info {
    background: #dbeafe;
    color: #1e40af;
  }

  .alert-error {
    background: #fee2e2;
    color: #991b1b;
  }
</style>
```

## Cascading Order

Styles in Astro follow a specific precedence order (lowest to highest priority):

1. **`<link>` tags** -- Lowest priority. Stylesheets loaded via `<link>` in the `<head>`.
2. **Imported styles** -- Styles imported in the frontmatter (`import "./styles.css"`).
3. **Scoped styles** -- Highest priority. Styles in `<style>` tags within the component.

```astro
---
// Imported styles (medium priority)
import "../styles/base.css";
---

<html>
  <head>
    <!-- Link tag styles (lowest priority) -->
    <link rel="stylesheet" href="/styles/vendor.css" />
  </head>
  <body>
    <h1 class="title">Hello</h1>
  </body>
</html>

<!-- Scoped styles (highest priority) -->
<style>
  .title {
    color: #1e293b;
  }
</style>
```

This means scoped styles always win when specificity is equal. The cascading order applies regardless of the physical order in the file.

## Production Optimization

### Inline Stylesheets Configuration

Control whether stylesheets are inlined into `<style>` tags or kept as separate `<link>` files.

```js
// astro.config.mjs
import { defineConfig } from "astro/config";

export default defineConfig({
  build: {
    // "auto" (default) -- inline if below assetsInlineLimit, otherwise link
    // "always" -- inline all stylesheets into <style> tags
    // "never" -- always emit <link> tags
    inlineStylesheets: "auto",
  },
});
```

### Assets Inline Limit

Control the threshold for inlining stylesheets (in bytes) via the Vite config.

```js
// astro.config.mjs
import { defineConfig } from "astro/config";

export default defineConfig({
  vite: {
    build: {
      // Default is 4096 (4 KB). Stylesheets smaller than this are inlined.
      assetsInlineLimit: 8192,
    },
  },
});
```

## Raw CSS Import

Import a CSS file as a raw string using the `?raw` query suffix. The CSS is not processed or injected into the page.

```astro
---
import rawCSS from "../styles/email-template.css?raw";
---

<!-- Useful for email templates or injecting into iframes -->
<div set:html={`<style>${rawCSS}</style><div class="email-body">...</div>`} />
```

## URL CSS Import

Import a CSS file and get back its resolved URL using the `?url` query suffix. The CSS is not automatically injected.

```astro
---
const cssURL = (await import("../styles/print.css?url")).default;
---

<link rel="stylesheet" href={cssURL} media="print" />
```

This is useful for conditionally loaded stylesheets, print styles, or deferred loading.
