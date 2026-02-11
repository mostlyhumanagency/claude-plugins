---
name: building-astro-endpoints
description: Use when creating API routes in Astro — static file endpoints with GET and getStaticPaths, server endpoints with POST/PUT/DELETE/PATCH, request body parsing, Response objects, redirects, binary responses, or the APIRoute type.
---

# Building Astro Endpoints

Astro endpoints are `.ts` or `.js` files in `src/pages/` that export HTTP method handler functions instead of rendering HTML. They produce raw responses -- JSON, XML, binary files, or any other content type.

## Static Endpoints

Static endpoints run at build time and generate files on disk. They must export a `GET` function and can optionally export `getStaticPaths` for dynamic routes.

### Basic Static Endpoint

The file extension before `.ts` determines the output format:

```ts
// src/pages/data.json.ts
import type { APIRoute } from "astro";

export const GET: APIRoute = async () => {
  const products = [
    { id: 1, name: "Widget", price: 29.99 },
    { id: 2, name: "Gadget", price: 49.99 },
    { id: 3, name: "Doohickey", price: 9.99 },
  ];

  return new Response(JSON.stringify(products), {
    status: 200,
    headers: {
      "Content-Type": "application/json",
    },
  });
};
```

This generates `/data.json` in the build output.

### RSS Feed Example

```ts
// src/pages/rss.xml.ts
import type { APIRoute } from "astro";
import { getCollection } from "astro:content";

export const GET: APIRoute = async ({ site }) => {
  const posts = await getCollection("blog");
  const sortedPosts = posts.sort(
    (a, b) => b.data.pubDate.getTime() - a.data.pubDate.getTime()
  );

  const rssItems = sortedPosts
    .map(
      (post) => `
    <item>
      <title>${post.data.title}</title>
      <link>${site}posts/${post.slug}</link>
      <pubDate>${post.data.pubDate.toUTCString()}</pubDate>
      <description>${post.data.description}</description>
    </item>`
    )
    .join("");

  const rss = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>My Blog</title>
    <link>${site}</link>
    <description>Latest posts from my blog</description>
    ${rssItems}
  </channel>
</rss>`;

  return new Response(rss, {
    headers: {
      "Content-Type": "application/xml",
    },
  });
};
```

### Dynamic Static Endpoints with getStaticPaths

For dynamic routes, export `getStaticPaths` to enumerate all paths at build time:

```ts
// src/pages/products/[id].json.ts
import type { APIRoute } from "astro";

export function getStaticPaths() {
  return [
    { params: { id: "1" }, props: { name: "Widget", price: 29.99 } },
    { params: { id: "2" }, props: { name: "Gadget", price: 49.99 } },
    { params: { id: "3" }, props: { name: "Doohickey", price: 9.99 } },
  ];
}

export const GET: APIRoute = async ({ params, props }) => {
  return new Response(
    JSON.stringify({
      id: params.id,
      name: props.name,
      price: props.price,
    }),
    {
      headers: { "Content-Type": "application/json" },
    }
  );
};
```

This generates `/products/1.json`, `/products/2.json`, and `/products/3.json`.

## Server Endpoints

Server endpoints handle requests at runtime rather than build time. They support all HTTP methods and have full access to the incoming `Request` object. Opt into server rendering with `prerender = false`:

```ts
// src/pages/api/users.ts
import type { APIRoute } from "astro";

export const prerender = false;

export const GET: APIRoute = async ({ url }) => {
  const page = parseInt(url.searchParams.get("page") || "1");
  const limit = parseInt(url.searchParams.get("limit") || "10");

  const users = await db.users.findMany({
    skip: (page - 1) * limit,
    take: limit,
  });

  return new Response(JSON.stringify({ users, page, limit }), {
    headers: { "Content-Type": "application/json" },
  });
};
```

## HTTP Methods

Export named functions for each HTTP method you want to handle. Astro calls the matching export based on the request method:

```ts
// src/pages/api/posts.ts
import type { APIRoute } from "astro";

export const prerender = false;

export const GET: APIRoute = async ({ url }) => {
  const posts = await db.posts.findMany();
  return new Response(JSON.stringify(posts), {
    headers: { "Content-Type": "application/json" },
  });
};

export const POST: APIRoute = async ({ request }) => {
  const body = await request.json();
  const post = await db.posts.create({
    data: { title: body.title, content: body.content },
  });

  return new Response(JSON.stringify(post), {
    status: 201,
    headers: { "Content-Type": "application/json" },
  });
};

export const DELETE: APIRoute = async ({ url }) => {
  const id = url.searchParams.get("id");

  if (!id) {
    return new Response(JSON.stringify({ error: "Missing id parameter" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  await db.posts.delete({ where: { id } });
  return new Response(null, { status: 204 });
};
```

### ALL Method

Export `ALL` to handle any HTTP method with a single function. This runs when no specific method export matches:

```ts
// src/pages/api/proxy.ts
import type { APIRoute } from "astro";

export const prerender = false;

export const ALL: APIRoute = async ({ request }) => {
  const targetUrl = new URL(request.url).searchParams.get("url");

  if (!targetUrl) {
    return new Response("Missing url parameter", { status: 400 });
  }

  const response = await fetch(targetUrl, {
    method: request.method,
    headers: request.headers,
    body: request.method !== "GET" ? await request.text() : undefined,
  });

  return new Response(response.body, {
    status: response.status,
    headers: response.headers,
  });
};
```

### PUT and PATCH

```ts
// src/pages/api/posts/[id].ts
import type { APIRoute } from "astro";

export const prerender = false;

export const PUT: APIRoute = async ({ params, request }) => {
  const body = await request.json();
  const post = await db.posts.update({
    where: { id: params.id },
    data: { title: body.title, content: body.content },
  });

  return new Response(JSON.stringify(post), {
    headers: { "Content-Type": "application/json" },
  });
};

export const PATCH: APIRoute = async ({ params, request }) => {
  const body = await request.json();
  const post = await db.posts.update({
    where: { id: params.id },
    data: body,
  });

  return new Response(JSON.stringify(post), {
    headers: { "Content-Type": "application/json" },
  });
};
```

## Request Body Parsing

### JSON Body

```ts
export const POST: APIRoute = async ({ request }) => {
  const data = await request.json();
  // data is the parsed JSON object
  return new Response(JSON.stringify({ received: data }));
};
```

### Form Data

```ts
export const POST: APIRoute = async ({ request }) => {
  const formData = await request.formData();
  const name = formData.get("name") as string;
  const email = formData.get("email") as string;
  const file = formData.get("avatar") as File | null;

  if (file) {
    const bytes = await file.arrayBuffer();
    // Process the uploaded file
  }

  return new Response(JSON.stringify({ name, email }), {
    headers: { "Content-Type": "application/json" },
  });
};
```

### Text Body

```ts
export const POST: APIRoute = async ({ request }) => {
  const text = await request.text();
  return new Response(`Received: ${text}`);
};
```

### URL-Encoded Body

```ts
export const POST: APIRoute = async ({ request }) => {
  const text = await request.text();
  const params = new URLSearchParams(text);
  const username = params.get("username");
  const password = params.get("password");

  return new Response(JSON.stringify({ username }), {
    headers: { "Content-Type": "application/json" },
  });
};
```

## Binary Responses

Return binary data such as images, PDFs, or file downloads:

```ts
// src/pages/api/og-image.ts
import type { APIRoute } from "astro";

export const prerender = false;

export const GET: APIRoute = async ({ url }) => {
  const title = url.searchParams.get("title") || "Default Title";
  const imageBuffer = await generateOgImage(title);

  return new Response(imageBuffer, {
    headers: {
      "Content-Type": "image/png",
      "Cache-Control": "public, max-age=86400",
    },
  });
};
```

### File Download

```ts
// src/pages/api/export.ts
import type { APIRoute } from "astro";
import { readFile } from "node:fs/promises";

export const prerender = false;

export const GET: APIRoute = async ({ url }) => {
  const reportId = url.searchParams.get("id");
  const csvContent = await generateReport(reportId);

  return new Response(csvContent, {
    headers: {
      "Content-Type": "text/csv",
      "Content-Disposition": `attachment; filename="report-${reportId}.csv"`,
    },
  });
};
```

### ArrayBuffer Response

```ts
// src/pages/api/pdf/[id].ts
import type { APIRoute } from "astro";

export const prerender = false;

export const GET: APIRoute = async ({ params }) => {
  const pdfBuffer = await generatePdf(params.id);

  return new Response(pdfBuffer, {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Length": pdfBuffer.byteLength.toString(),
    },
  });
};
```

## Redirects

Use `context.redirect()` to redirect from an endpoint:

```ts
// src/pages/api/auth/callback.ts
import type { APIRoute } from "astro";

export const prerender = false;

export const GET: APIRoute = async ({ url, cookies, redirect }) => {
  const code = url.searchParams.get("code");

  if (!code) {
    return redirect("/login?error=missing_code", 302);
  }

  const token = await exchangeCodeForToken(code);
  cookies.set("auth_token", token, {
    path: "/",
    httpOnly: true,
    secure: true,
    maxAge: 60 * 60 * 24 * 7,
  });

  return redirect("/dashboard", 302);
};
```

You can also construct a redirect `Response` manually:

```ts
return new Response(null, {
  status: 301,
  headers: {
    Location: "/new-location",
  },
});
```

## Static vs Server Comparison

| Feature | Static Endpoint | Server Endpoint |
|---|---|---|
| When it runs | Build time | Request time |
| Output | Files on disk | Dynamic responses |
| HTTP methods | `GET` only | `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `ALL` |
| Request access | No incoming request | Full `Request` object |
| `getStaticPaths` | Required for dynamic routes | Not needed |
| `prerender` | `true` (default) | Must set `false` |
| Use case | Static files (JSON, XML, RSS) | APIs, form handlers, auth |

## The APIRoute Type

All endpoint handler functions use the `APIRoute` type from `astro`. It provides full type safety for the context parameter:

```ts
import type { APIRoute } from "astro";

export const GET: APIRoute = async (context) => {
  // context includes:
  // - context.params: route parameters
  // - context.request: the incoming Request
  // - context.url: parsed URL object
  // - context.cookies: cookie API
  // - context.redirect(path, status?): redirect helper
  // - context.site: the site URL from config
  // - context.props: props from getStaticPaths
  // - context.locals: shared data from middleware
  // - context.session: session API (if configured)

  return new Response("OK");
};
```

Destructure the context for cleaner code:

```ts
export const POST: APIRoute = async ({
  request,
  params,
  cookies,
  redirect,
  locals,
}) => {
  if (!locals.user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
    });
  }

  const body = await request.json();
  const result = await processData(body);

  return new Response(JSON.stringify(result), {
    headers: { "Content-Type": "application/json" },
  });
};
```

## Common Pitfalls

1. **Static endpoints only support GET.** Exporting `POST`, `PUT`, or `DELETE` from a prerendered endpoint is ignored at build time. Set `export const prerender = false` for server endpoints.

2. **File extension determines output type.** `data.json.ts` produces `data.json`. If you name a file `api.ts` without a content extension, it does not produce a file at all in static mode. Use `.json.ts`, `.xml.ts`, or similar for static endpoints.

3. **Always return a Response.** Every handler must return a `Response` object. Returning `undefined`, a plain object, or a string causes a runtime error. Use `new Response(JSON.stringify(data))` for JSON.

4. **Request body can only be read once.** Calling `request.json()` consumes the body stream. A second call to `request.json()` or `request.text()` on the same request throws an error. Store the result in a variable.

5. **Dynamic server endpoints do not use getStaticPaths.** When `prerender` is `false`, parameters come from the URL at runtime. Exporting `getStaticPaths` in a server endpoint has no effect.

6. **Set Content-Type headers explicitly.** Astro does not infer content types from response bodies. Always set `Content-Type` in the headers to ensure clients parse the response correctly.

7. **Method not found returns 405.** If a request arrives for a method you have not exported (for example, a `PUT` request to an endpoint that only exports `GET` and `POST`), Astro returns a `405 Method Not Allowed` response automatically.
