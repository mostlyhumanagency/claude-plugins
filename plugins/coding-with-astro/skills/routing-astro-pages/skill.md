---
name: routing-astro-pages
description: Use when working with Astro file-based routing — static routes, dynamic routes with brackets, rest parameters, getStaticPaths, pagination with paginate(), redirects, rewrites, route priority, custom 404/500 pages, or excluding pages with underscore prefix.
---

# Astro Routing

Astro uses file-based routing. Any `.astro`, `.md`, `.mdx`, `.html`, or `.js/.ts` file in `src/pages/` automatically becomes a route on your site.

## Static Routes

Files and directories in `src/pages/` map directly to URL paths:

```
src/pages/index.astro        -> /
src/pages/about.astro        -> /about
src/pages/about/index.astro  -> /about
src/pages/posts/1.md         -> /posts/1
src/pages/blog/post-one.mdx  -> /blog/post-one
```

There is no separate route configuration file. The filesystem is the router.

## Dynamic Routes (Static / SSG)

Use bracket syntax in filenames to create dynamic route segments. In static (SSG) mode, all matched paths must be enumerated at build time using `getStaticPaths()`.

### Single Parameter

```astro
---
// src/pages/dogs/[dog].astro
export function getStaticPaths() {
  return [
    { params: { dog: "clifford" } },
    { params: { dog: "rover" } },
    { params: { dog: "spot" } },
  ];
}

const { dog } = Astro.params;
---
<h1>Good dog, {dog}!</h1>
```

This generates `/dogs/clifford`, `/dogs/rover`, and `/dogs/spot`.

### Multiple Parameters

Combine multiple params in a single filename segment:

```astro
---
// src/pages/[lang]-[version]/info.astro
export function getStaticPaths() {
  return [
    { params: { lang: "en", version: "v1" } },
    { params: { lang: "fr", version: "v2" } },
  ];
}

const { lang, version } = Astro.params;
---
<h1>{lang} docs ({version})</h1>
```

This generates `/en-v1/info` and `/fr-v2/info`.

### Passing Data with Props

Use `props` in the return value to pass data to the page without encoding it in the URL:

```astro
---
// src/pages/posts/[slug].astro
export function getStaticPaths() {
  const posts = await fetch("https://api.example.com/posts").then((r) => r.json());
  return posts.map((post) => ({
    params: { slug: post.slug },
    props: { title: post.title, body: post.body },
  }));
}

const { title, body } = Astro.props;
---
<article>
  <h1>{title}</h1>
  <div set:html={body} />
</article>
```

## Rest Parameters

Use `[...param]` syntax to match multiple path segments. This captures the remaining URL path as a single string.

```astro
---
// src/pages/sequences/[...path].astro
export function getStaticPaths() {
  return [
    { params: { path: "one/two/three" } },
    { params: { path: "four" } },
    { params: { path: undefined } },  // matches /sequences
  ];
}

const { path } = Astro.params;
---
<p>Path: {path}</p>
```

Setting `path` to `undefined` matches the base route `/sequences` without a trailing segment.

### Catch-All 404 with Rest Parameters

```astro
---
// src/pages/[...slug].astro
export function getStaticPaths() {
  return [];
}
---
<h1>Page not found</h1>
```

## Dynamic Routes (SSR / On-Demand)

In server-rendered mode, dynamic routes do not need `getStaticPaths()`. Parameters are resolved from the request URL at runtime.

```astro
---
// src/pages/products/[id].astro
export const prerender = false;

const { id } = Astro.params;
const product = await db.products.findOne({ id });

if (!product) {
  return Astro.redirect("/404");
}
---
<h1>{product.name}</h1>
<p>{product.description}</p>
```

Rest parameters also work in SSR mode:

```astro
---
// src/pages/api/[...segments].astro
export const prerender = false;

const { segments } = Astro.params;
const parts = segments ? segments.split("/") : [];
---
```

## Pagination

Astro provides a built-in `paginate()` function available in `getStaticPaths()`.

### Basic Pagination

```astro
---
// src/pages/astronauts/[page].astro
import { getCollection } from "astro:content";

export async function getStaticPaths({ paginate }) {
  const allAstronauts = await getCollection("astronauts");
  return paginate(allAstronauts, { pageSize: 10 });
}

const { page } = Astro.props;
---
<h1>Astronauts (Page {page.currentPage})</h1>
<ul>
  {page.data.map((astronaut) => (
    <li>{astronaut.data.name}</li>
  ))}
</ul>

{page.url.prev && <a href={page.url.prev}>Previous</a>}
{page.url.next && <a href={page.url.next}>Next</a>}

<p>Page {page.currentPage} of {page.lastPage} ({page.total} total items)</p>
```

This generates `/astronauts/1`, `/astronauts/2`, and so on.

### Page Object Properties

| Property | Type | Description |
|---|---|---|
| `page.data` | `Array` | Slice of items for the current page |
| `page.start` | `number` | Index of first item on this page |
| `page.end` | `number` | Index of last item on this page |
| `page.size` | `number` | Items per page |
| `page.total` | `number` | Total number of items across all pages |
| `page.currentPage` | `number` | Current page number (1-indexed) |
| `page.lastPage` | `number` | Total number of pages |
| `page.url.current` | `string` | URL of the current page |
| `page.url.prev` | `string \| undefined` | URL of the previous page |
| `page.url.next` | `string \| undefined` | URL of the next page |
| `page.url.first` | `string` | URL of the first page |
| `page.url.last` | `string` | URL of the last page |

### Nested Pagination

Combine dynamic params with pagination using `flatMap`:

```astro
---
// src/pages/tags/[tag]/[page].astro
import { getCollection } from "astro:content";

export async function getStaticPaths({ paginate }) {
  const allPosts = await getCollection("blog");
  const uniqueTags = [...new Set(allPosts.flatMap((post) => post.data.tags))];

  return uniqueTags.flatMap((tag) => {
    const filtered = allPosts.filter((post) => post.data.tags.includes(tag));
    return paginate(filtered, {
      params: { tag },
      pageSize: 5,
    });
  });
}

const { page } = Astro.props;
const { tag } = Astro.params;
---
<h1>Posts tagged "{tag}"</h1>
```

This generates routes like `/tags/astro/1`, `/tags/astro/2`, `/tags/tutorial/1`.

## Redirects

### Configuration-Based Redirects

Define redirects in `astro.config.mjs`:

```js
// astro.config.mjs
import { defineConfig } from "astro/config";

export default defineConfig({
  redirects: {
    "/old-page": "/new-page",
    "/blog/[...slug]": "/articles/[...slug]",
    "/temporary": {
      status: 302,
      destination: "/new-temporary",
    },
  },
});
```

By default, config redirects use status 301 (permanent). Specify an object with `status` and `destination` for temporary redirects.

### Runtime Redirects

Use `Astro.redirect()` in page frontmatter or endpoints:

```astro
---
// src/pages/dashboard.astro
const session = Astro.cookies.get("session");

if (!session) {
  return Astro.redirect("/login");
}

// Redirect with custom status code
// return Astro.redirect("/login", 302);
---
<h1>Dashboard</h1>
```

In an endpoint:

```ts
// src/pages/api/logout.ts
import type { APIRoute } from "astro";

export const POST: APIRoute = async ({ redirect, cookies }) => {
  cookies.delete("session", { path: "/" });
  return redirect("/login", 302);
};
```

## Rewrites

Rewrites serve content from a different route without changing the browser URL.

### Page-Level Rewrite

```astro
---
// src/pages/index.astro
const locale = Astro.cookies.get("locale")?.value || "en";

if (locale !== "en") {
  return Astro.rewrite(`/${locale}/home`);
}
---
<h1>Welcome</h1>
```

### Middleware Rewrite

```ts
// src/middleware.ts
import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware((context, next) => {
  if (context.url.pathname === "/old-path") {
    return context.rewrite("/new-path");
  }
  return next();
});
```

Rewrites accept a string path or a `Request` object for more control:

```ts
return context.rewrite(new Request("/api/data", {
  headers: { "x-custom": "value" },
}));
```

## Route Priority

When multiple routes could match the same URL, Astro resolves them using these rules in order from highest to lowest priority:

1. **Static routes** -- routes without path parameters (`/about`) win over dynamic routes (`/[slug]`)
2. **Named parameters** -- dynamic routes with named params (`/posts/[id]`) win over rest parameters (`/posts/[...slug]`)
3. **Pre-rendered routes** -- pre-rendered (static) routes take priority over server-rendered routes
4. **Endpoints over pages** -- API endpoints (`.ts`, `.js`) take priority over page routes (`.astro`, `.md`)
5. **File-based routes over config redirects** -- routes defined as files win over redirect entries in config
6. **Alphabetical order** -- when all else is equal, routes are sorted alphabetically

## Excluding Pages

Prefix a file or directory name with an underscore to exclude it from routing:

```
src/pages/_draft-post.astro     -> not routed
src/pages/_utils/helper.astro   -> not routed
src/pages/about.astro           -> /about (routed normally)
```

Use this for utility files, partial templates, or work-in-progress pages that should not be publicly accessible.

## Custom Error Pages

### 404 Page

Create `src/pages/404.astro` to define a custom "not found" page:

```astro
---
// src/pages/404.astro
---
<html>
  <head><title>Not Found</title></head>
  <body>
    <h1>404 -- Page Not Found</h1>
    <p>The page you are looking for does not exist.</p>
    <a href="/">Return home</a>
  </body>
</html>
```

In SSG mode, Astro generates `404.html` which most hosting platforms serve automatically. In SSR mode, the 404 page renders on the server for unmatched routes.

### 500 Page

Create `src/pages/500.astro` for server errors (SSR only):

```astro
---
// src/pages/500.astro
export const prerender = false;
---
<html>
  <head><title>Server Error</title></head>
  <body>
    <h1>500 -- Server Error</h1>
    <p>Something went wrong. Please try again later.</p>
    <a href="/">Return home</a>
  </body>
</html>
```

The 500 page is only available in server-rendered mode. In static mode, your hosting platform handles server errors.

## Common Pitfalls

- **getStaticPaths must be exhaustive.** In SSG mode, every possible path must be returned. Missing paths produce a build error, not a 404.
- **Pagination URLs start at 1.** `paginate()` generates `/1`, `/2`, etc. -- not `/page/1`. Structure the directory accordingly.
- **Rest params with `undefined` match the base path.** Returning `{ params: { path: undefined } }` from `[...path].astro` matches the directory root.
- **`Astro.redirect()` must be called at page level.** It must be in the frontmatter of a page or returned from an endpoint. It does not work inside child components.
- **Decode URL parameters.** Params with special characters arrive URL-encoded. Use `decodeURI()` or `decodeURIComponent()` when comparing or displaying them.
- **Trailing slashes depend on configuration.** Set `trailingSlash` in `astro.config.mjs` to `"always"`, `"never"`, or `"ignore"` to control behavior.
- **File extensions are stripped.** `about.astro` becomes `/about`, not `/about.astro`. Markdown files follow the same pattern.
