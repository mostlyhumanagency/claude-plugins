---
name: using-astro-view-transitions
description: Use when adding page transitions in Astro — ClientRouter component, transition:name for element matching, transition:animate with fade/slide/none, transition:persist for state preservation, lifecycle events (astro:before-preparation through astro:page-load), navigate() for programmatic routing, fallback behavior, or custom animations.
---

# Astro View Transitions

Astro provides client-side page transitions using the View Transitions API. When enabled, Astro intercepts link clicks, fetches the new page, and animates the transition between old and new content without a full page reload.

## Enabling View Transitions

Import the `ClientRouter` component from `astro:transitions` and add it to the `<head>` of your page or layout:

```astro
---
// src/layouts/BaseLayout.astro
import { ClientRouter } from "astro:transitions";

interface Props {
  title: string;
}

const { title } = Astro.props;
---

<html>
  <head>
    <meta charset="utf-8" />
    <title>{title}</title>
    <ClientRouter />
  </head>
  <body>
    <slot />
  </body>
</html>
```

Once `<ClientRouter />` is present, all same-origin link navigations on the page become client-side transitions. Add it to a shared layout so every page in the site uses transitions.

## Transition Directives

### transition:name

Assign a unique name to an element so Astro can match it between pages and animate the transition between the old and new versions:

```astro
---
// src/pages/posts/[slug].astro
const { slug } = Astro.params;
const post = await getPost(slug);
---

<article>
  <img
    src={post.coverImage}
    alt={post.title}
    transition:name={`post-image-${slug}`}
  />
  <h1 transition:name={`post-title-${slug}`}>{post.title}</h1>
  <p>{post.body}</p>
</article>
```

On the listing page, use the same `transition:name` values so elements morph between views:

```astro
---
// src/pages/posts/index.astro
const posts = await getAllPosts();
---

<ul>
  {posts.map((post) => (
    <li>
      <a href={`/posts/${post.slug}`}>
        <img
          src={post.coverImage}
          alt={post.title}
          transition:name={`post-image-${post.slug}`}
        />
        <h2 transition:name={`post-title-${post.slug}`}>{post.title}</h2>
      </a>
    </li>
  ))}
</ul>
```

Each `transition:name` must be unique on a given page. Duplicate names on the same page cause a warning and the transition falls back to a crossfade.

### transition:animate

Control the animation style for a specific element. Accepts a built-in animation name or a custom animation object:

```astro
<header transition:animate="slide">
  <nav>
    <a href="/">Home</a>
    <a href="/about">About</a>
  </nav>
</header>

<main transition:animate="fade">
  <slot />
</main>

<aside transition:animate="none">
  <p>This sidebar does not animate during transitions.</p>
</aside>
```

### Built-in Animations

| Animation | Behavior |
|---|---|
| `fade` | Crossfade between old and new elements. This is the default for elements without a `transition:name`. |
| `initial` | Uses the browser's default View Transition animation (crossfade). This is the default for elements with a `transition:name`. |
| `slide` | Old content slides out to the left, new content slides in from the right. On back navigation, the directions reverse. |
| `none` | Disables all animations. The old element is immediately replaced by the new one. |

### transition:persist

Keep an element and its state across page navigations instead of replacing it. The DOM node, event listeners, and component state survive the transition:

```astro
---
// src/layouts/BaseLayout.astro
import { ClientRouter } from "astro:transitions";
import AudioPlayer from "../components/AudioPlayer.astro";
---

<html>
  <head>
    <ClientRouter />
  </head>
  <body>
    <slot />
    <AudioPlayer transition:persist />
  </body>
</html>
```

The audio player retains playback state as the user navigates between pages. The persisted element must appear in both the old and new page. Astro matches them by `transition:name` (auto-generated from `transition:persist` if not set explicitly) or by a shared `transition:persist="player-id"` value.

### transition:persist-props

By default, a persisted framework component re-renders with new props from the incoming page. Set `transition:persist-props` to prevent this and keep the component's existing props:

```astro
<VideoPlayer
  client:load
  src={currentVideo}
  transition:persist
  transition:persist-props
/>
```

With `transition:persist-props`, the `VideoPlayer` keeps playing the original `src` even if the new page supplies a different value.

## Custom Animations

Define custom animations using the `TransitionDirectionalAnimations` interface. Provide separate `forwards` and `backwards` objects, each with `old` and `new` arrays of keyframes:

```astro
---
const zoomIn = {
  forwards: {
    old: [
      { opacity: 1, transform: "scale(1)" },
      { opacity: 0, transform: "scale(0.8)" },
    ],
    new: [
      { opacity: 0, transform: "scale(1.2)" },
      { opacity: 1, transform: "scale(1)" },
    ],
  },
  backwards: {
    old: [
      { opacity: 1, transform: "scale(1)" },
      { opacity: 0, transform: "scale(1.2)" },
    ],
    new: [
      { opacity: 0, transform: "scale(0.8)" },
      { opacity: 1, transform: "scale(1)" },
    ],
  },
};
---

<main transition:animate={zoomIn}>
  <slot />
</main>
```

Each keyframe array follows the Web Animations API `Keyframe` format. You can also pass options alongside keyframes:

```astro
---
const slowFade = {
  forwards: {
    old: {
      keyframes: [{ opacity: 1 }, { opacity: 0 }],
      options: { duration: 600, easing: "ease-in-out" },
    },
    new: {
      keyframes: [{ opacity: 0 }, { opacity: 1 }],
      options: { duration: 600, easing: "ease-in-out" },
    },
  },
  backwards: {
    old: {
      keyframes: [{ opacity: 1 }, { opacity: 0 }],
      options: { duration: 600, easing: "ease-in-out" },
    },
    new: {
      keyframes: [{ opacity: 0 }, { opacity: 1 }],
      options: { duration: 600, easing: "ease-in-out" },
    },
  },
};
---

<div transition:animate={slowFade}>
  <slot />
</div>
```

## Router Control

### Preventing Client-Side Navigation

Add `data-astro-reload` to a link to force a full page reload instead of a client-side transition:

```astro
<a href="/external-app" data-astro-reload>Open external app</a>
```

### Programmatic Navigation with navigate()

Use the `navigate()` function to trigger client-side transitions from scripts:

```astro
<script>
  import { navigate } from "astro:transitions/client";

  document.querySelector("#search-form").addEventListener("submit", (e) => {
    e.preventDefault();
    const query = new FormData(e.target).get("q");
    navigate(`/search?q=${encodeURIComponent(query)}`);
  });
</script>
```

`navigate()` accepts an optional second argument with options:

```ts
import { navigate } from "astro:transitions/client";

// Replace the current history entry instead of pushing
navigate("/new-page", { history: "replace" });

// Pass form data for POST transitions
navigate("/submit", {
  formData: new FormData(formElement),
});
```

### History Control

Use `data-astro-history` to control how a navigation affects browser history:

```astro
<!-- Replace instead of push -->
<a href="/tab-2" data-astro-history="replace">Tab 2</a>
```

## Form Transitions

Forms automatically use client-side transitions when the `ClientRouter` is active. Form submissions are intercepted, the response page is fetched, and a transition plays:

```astro
<form method="POST" action="/api/submit">
  <input type="text" name="email" required />
  <button type="submit">Subscribe</button>
</form>
```

To opt a form out of client-side transitions, add `data-astro-reload`:

```astro
<form method="POST" action="/api/upload" data-astro-reload>
  <input type="file" name="document" />
  <button type="submit">Upload</button>
</form>
```

## Lifecycle Events

View transition events fire in this order during every client-side navigation:

### 1. astro:before-preparation

Fires after a link click (or `navigate()` call), before the new page is fetched. Use it to add loading indicators or modify the navigation:

```astro
<script>
  document.addEventListener("astro:before-preparation", (event) => {
    const loader = document.querySelector("#loading-bar");
    loader.classList.add("active");

    // Access navigation details
    console.log("Navigating from:", event.from);
    console.log("Navigating to:", event.to);
  });
</script>
```

### 2. astro:after-preparation

Fires after the new page content has been fetched and parsed, but before the DOM swap:

```astro
<script>
  document.addEventListener("astro:after-preparation", (event) => {
    document.querySelector("#loading-bar").classList.remove("active");
  });
</script>
```

### 3. astro:before-swap

Fires just before the old document is replaced with the new one. The `event.newDocument` property holds the parsed new page as a `Document` object. Modify it before the swap occurs:

```astro
<script>
  document.addEventListener("astro:before-swap", (event) => {
    // Preserve a DOM element across the swap
    const theme = document.documentElement.getAttribute("data-theme");
    event.newDocument.documentElement.setAttribute("data-theme", theme);
  });
</script>
```

You can also override the swap function entirely:

```astro
<script>
  document.addEventListener("astro:before-swap", (event) => {
    event.swap = () => {
      // Custom swap logic
      document.body.innerHTML = event.newDocument.body.innerHTML;
      document.title = event.newDocument.title;
    };
  });
</script>
```

### 4. astro:after-swap

Fires immediately after the DOM has been swapped. The new page content is now in the document. Use this to restore state or re-initialize non-persisted elements:

```astro
<script>
  document.addEventListener("astro:after-swap", () => {
    // Re-apply scroll position logic
    window.scrollTo(0, 0);

    // Re-initialize third-party libraries on new content
    initializeSyntaxHighlighting();
  });
</script>
```

### 5. astro:page-load

Fires after the transition is fully complete, including after all animations have finished. This event also fires on initial page load (without transitions), making it a reliable place for page initialization:

```astro
<script>
  document.addEventListener("astro:page-load", () => {
    // This runs on every page, including the first load
    document.querySelectorAll("[data-tooltip]").forEach((el) => {
      initTooltip(el);
    });
  });
</script>
```

## Script Behavior

By default, scripts in the `<head>` and `<body>` are not re-executed during client-side transitions (they run only on the initial page load). To force a script to re-run on every navigation, add `data-astro-rerun`:

```astro
<script data-astro-rerun>
  // This runs on every page transition, not just initial load
  console.log("Page changed:", window.location.pathname);
  initializePageAnalytics();
</script>
```

Module scripts (`<script type="module">`) that already appeared on the previous page are not re-executed. New module scripts from the incoming page are executed normally.

## Fallback Options

For browsers that do not support the native View Transitions API, Astro provides fallback behavior. Configure it via the `fallback` prop on `<ClientRouter />`:

```astro
<ClientRouter fallback="swap" />
```

| Fallback | Behavior |
|---|---|
| `"animate"` | (Default) Astro simulates view transitions using CSS animations before updating the DOM. |
| `"swap"` | Astro swaps the DOM without any animation. |
| `"none"` | No client-side transitions. Full page reloads in unsupported browsers. |

## Accessibility

### Route Announcement

Astro automatically announces page titles to screen readers during client-side transitions. If no `<title>` element is found in the new page, Astro falls back to the first `<h1>` element.

### prefers-reduced-motion

Astro respects the `prefers-reduced-motion` media query. When a user has reduced motion enabled, all transition animations are automatically disabled -- the DOM swap still happens, but no animation plays. This applies to both built-in and custom animations.

## swapFunctions Utilities

Astro exports helper functions for building custom swap logic:

```ts
import {
  swapBodyElement,
  swapHeadElements,
  swapRootAttributes,
  saveFocus,
  restoreFocus,
} from "astro:transitions/client";

document.addEventListener("astro:before-swap", (event) => {
  event.swap = () => {
    // Manually control the swap process
    swapRootAttributes(event.newDocument);
    swapHeadElements(event.newDocument);
    const savedFocus = saveFocus();
    swapBodyElement(event.newDocument.body, document.body);
    restoreFocus(savedFocus);
  };
});
```

| Function | Purpose |
|---|---|
| `swapRootAttributes` | Copies attributes from the new `<html>` element to the current one |
| `swapHeadElements` | Diffs the `<head>` elements, adding new ones and removing stale ones |
| `swapBodyElement` | Replaces the old `<body>` with the new one while handling `transition:persist` elements |
| `saveFocus` | Records which element has focus before the swap |
| `restoreFocus` | Restores focus to the equivalent element after the swap |

## Common Pitfalls

1. **`transition:name` must be unique per page.** Two elements with the same `transition:name` on a single page cause the transition to fall back to a crossfade for those elements.

2. **Persisted elements must exist on both pages.** If an element with `transition:persist` is present on one page but not the other, it is removed during the swap. Place persisted elements in shared layouts.

3. **Scripts do not re-run by default.** Inline scripts and module scripts are only executed on their first load. Use `data-astro-rerun` or `astro:page-load` event listeners for code that must run on every navigation.

4. **Event listeners on body or document persist.** Since the body is swapped but event listeners on `document` are not removed, be careful to avoid adding duplicate listeners. Use `astro:page-load` with a guard or add listeners once and handle new content dynamically.

5. **Third-party scripts may break.** Libraries that manipulate the DOM on `DOMContentLoaded` or `load` events may not re-initialize after a client-side transition. Wrap their initialization in an `astro:page-load` listener.

6. **Animations do not play on initial page load.** View transitions only animate when navigating between pages client-side. The first page load renders normally without transitions.

7. **Back/forward navigation reverses animation direction.** The `backwards` keyframes in custom animations play when the user navigates back. If you define only `forwards`, the animation may look wrong on back navigation.
