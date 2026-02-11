---
name: using-astro-content-collections
description: "Use when managing blog posts, documentation, or structured content in Astro with content collections. Use for tasks like 'add a blog', 'set up content collections', 'define a Zod schema for posts', 'load markdown files into a collection', 'build a custom loader for a CMS', or 'generate pages from collection data'. Covers content.config.ts setup, glob and file loaders, custom remote loaders, getCollection/getEntry queries, rendering entries to HTML, and collection type errors."
---

# Astro Content Collections

Content collections provide a type-safe, schema-validated way to manage structured content in Astro. Collections support local files (Markdown, MDX, JSON, YAML), single data files, and remote data from any API. Astro validates every entry against a Zod schema and generates TypeScript types automatically.

## Configuration File

Define all collections in `src/content.config.ts` (`.js` and `.mjs` extensions also work). This file must export a `collections` object containing every defined collection.

```typescript
// src/content.config.ts
import { defineCollection, z } from 'astro:content';
import { glob, file } from 'astro/loaders';

const blog = defineCollection({
  loader: glob({ pattern: "**/*.md", base: "./src/data/blog" }),
  schema: z.object({
    title: z.string(),
    pubDate: z.coerce.date(),
  }),
});

const authors = defineCollection({
  loader: file("src/data/authors.json"),
  schema: z.object({
    id: z.string(),
    name: z.string(),
    email: z.string().email(),
  }),
});

export const collections = { blog, authors };
```

## TypeScript Configuration

Content collections require `strictNullChecks: true` in `tsconfig.json`. Without it, schema inference and query return types will not work correctly.

```json
{
  "extends": "astro/tsconfigs/base",
  "compilerOptions": {
    "strictNullChecks": true,
    "allowJs": true
  }
}
```

## defineCollection

The `defineCollection` function accepts an object with two properties:

- **`loader`** -- data source (built-in loader, inline function, or loader object)
- **`schema`** -- optional Zod schema for validation and type generation

```typescript
import { defineCollection, z } from 'astro:content';

const myCollection = defineCollection({
  loader: /* ... */,
  schema: z.object({ /* ... */ }),
});
```

The `schema` property also accepts a function receiving a `SchemaContext`, which provides helpers like `image()` for local image validation:

```typescript
const gallery = defineCollection({
  loader: glob({ pattern: "**/*.md", base: "./src/data/gallery" }),
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      cover: image(),
      description: z.string().optional(),
    }),
});
```

## Zod Schemas

Import `z` from `astro:content` (re-exported from `astro/zod`). Use standard Zod methods for validation.

```typescript
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  loader: glob({ pattern: "**/*.md", base: "./src/data/blog" }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    draft: z.boolean().default(false),
    tags: z.array(z.string()),
    category: z.enum(["tutorial", "guide", "reference"]),
    rating: z.number().min(1).max(5).optional(),
  }),
});
```

Key Zod patterns for collections:

- `z.coerce.date()` -- parses date strings from frontmatter into `Date` objects
- `z.boolean().default(false)` -- provides a default when the field is omitted
- `z.array(z.string())` -- validates arrays of a given type
- `z.enum([...])` -- restricts to specific allowed values
- `z.string().url()` -- validates URL strings
- `z.object({}).passthrough()` -- allows additional unknown fields

Schema validation errors surface at build time with clear messages identifying the collection, entry, and failing field.

## Built-in Loaders

### glob() Loader

Creates entries from directories of files. Supports Markdown, MDX, Markdoc, JSON, YAML, and TOML. Each entry's `id` is auto-generated from the filename (kebab-cased, without extension).

```typescript
import { glob } from 'astro/loaders';

const blog = defineCollection({
  loader: glob({
    pattern: "**/*.{md,mdx}",
    base: "./src/data/blog",
  }),
  schema: z.object({
    title: z.string(),
    pubDate: z.coerce.date(),
  }),
});
```

**Options:**

- `pattern` (string | string[]) -- glob patterns relative to `base`, using micromatch syntax
- `base` (string | URL) -- root directory to resolve patterns against
- `generateId` (function) -- custom function to produce entry IDs from file paths

Custom ID generation:

```typescript
const blog = defineCollection({
  loader: glob({
    pattern: "**/*.md",
    base: "./src/data/blog",
    generateId: ({ entry, data }) => {
      // Use slug from frontmatter if available, otherwise use filename
      return data.slug || entry.replace(/\.md$/, "");
    },
  }),
  schema: z.object({
    title: z.string(),
    slug: z.string().optional(),
  }),
});
```

### file() Loader

Creates multiple entries from a single JSON or YAML file. Each entry must have a unique `id` field.

```typescript
import { file } from 'astro/loaders';

const dogs = defineCollection({
  loader: file("src/data/dogs.json"),
  schema: z.object({
    id: z.string(),
    breed: z.string(),
    temperament: z.string(),
  }),
});
```

The JSON file should contain an array of objects:

```json
[
  { "id": "golden", "breed": "Golden Retriever", "temperament": "Friendly" },
  { "id": "husky", "breed": "Siberian Husky", "temperament": "Energetic" }
]
```

Or a key-value object where keys become IDs:

```json
{
  "golden": { "breed": "Golden Retriever", "temperament": "Friendly" },
  "husky": { "breed": "Siberian Husky", "temperament": "Energetic" }
}
```

### Custom Parser for CSV

The `file()` loader accepts a `parser` function for unsupported file formats like CSV:

```typescript
import { file } from 'astro/loaders';
import { parse as parseCsv } from 'csv-parse/sync';

const products = defineCollection({
  loader: file("src/data/products.csv", {
    parser: (text) => parseCsv(text, { columns: true, skip_empty_lines: true }),
  }),
  schema: z.object({
    id: z.string(),
    name: z.string(),
    price: z.coerce.number(),
    category: z.string(),
  }),
});
```

The `parser` function receives the raw file content as a string and must return an array of objects, each with an `id` field.

## Inline Custom Loaders

For loading remote data, define a loader as an async function that returns an array of objects (each with an `id` field) or a key-value record.

```typescript
const countries = defineCollection({
  loader: async () => {
    const response = await fetch("https://restcountries.com/v3.1/all");
    const data = await response.json();
    return data.map((country: any) => ({
      id: country.cca3,
      name: country.name.common,
      population: country.population,
      region: country.region,
    }));
  },
  schema: z.object({
    name: z.string(),
    population: z.number(),
    region: z.string(),
  }),
});
```

For more control (incremental updates, metadata persistence, change detection), use the object loader API with a `load()` method that receives a `LoaderContext`:

```typescript
import type { Loader } from 'astro/loaders';

function cmsLoader(options: { apiUrl: string }): Loader {
  return {
    name: "cms-loader",
    load: async (context) => {
      const { store, meta, parseData, logger } = context;

      // Check for cached last-modified timestamp
      const lastSync = meta.get("lastSync");
      const url = lastSync
        ? `${options.apiUrl}?since=${lastSync}`
        : options.apiUrl;

      const response = await fetch(url);
      const posts = await response.json();

      for (const post of posts) {
        const data = await parseData({
          id: post.slug,
          data: {
            title: post.title,
            content: post.body,
            pubDate: post.published_at,
          },
        });
        store.set({ id: post.slug, data });
      }

      meta.set("lastSync", new Date().toISOString());
      logger.info(`Synced ${posts.length} posts`);
    },
  };
}
```

## Collection References

Link entries across collections using the `reference()` helper. This validates that the referenced entry exists at build time.

```typescript
import { defineCollection, z, reference } from 'astro:content';

const authors = defineCollection({
  loader: file("src/data/authors.json"),
  schema: z.object({
    id: z.string(),
    name: z.string(),
    bio: z.string(),
  }),
});

const blog = defineCollection({
  loader: glob({ pattern: "**/*.md", base: "./src/data/blog" }),
  schema: z.object({
    title: z.string(),
    author: reference("authors"),
    relatedPosts: z.array(reference("blog")).default([]),
  }),
});

export const collections = { authors, blog };
```

In the Markdown frontmatter, reference entries by their `id`:

```yaml
---
title: Getting Started with Astro
author: jane-doe
relatedPosts:
  - advanced-routing
  - using-markdown
---
```

References are transformed into objects with `collection` and `id` properties. Resolve them using `getEntry()` or `getEntries()`:

```astro
---
import { getEntry, getEntries } from 'astro:content';

const post = await getEntry('blog', 'getting-started');
const author = await getEntry(post.data.author);
const related = await getEntries(post.data.relatedPosts);
---

<p>By {author.data.name}</p>
<ul>
  {related.map((r) => <li>{r.data.title}</li>)}
</ul>
```

## Querying Collections

Import query functions from `astro:content`.

### getCollection()

Retrieves all entries from a collection. Returns an array of typed `CollectionEntry` objects.

```typescript
import { getCollection } from 'astro:content';

const allPosts = await getCollection('blog');
```

Each entry object has:

- `id` (string) -- unique identifier
- `collection` (string) -- collection name
- `data` -- validated frontmatter/data matching the schema
- `body` (string | undefined) -- raw file content (for renderable entries)

### getEntry()

Retrieves a single entry by collection name and ID. Returns `undefined` if not found.

```typescript
import { getEntry } from 'astro:content';

// By collection name and ID
const post = await getEntry('blog', 'hello-world');

// By reference object (from collection references)
const author = await getEntry(post.data.author);
```

### getEntries()

Retrieves multiple entries from reference arrays. Useful for resolving `reference()` fields.

```typescript
import { getEntries } from 'astro:content';

const relatedPosts = await getEntries(post.data.relatedPosts);
```

## Filtering

Pass a filter function as the second argument to `getCollection()`. The function receives each entry and returns a boolean.

```typescript
import { getCollection } from 'astro:content';

// Filter out drafts
const publishedPosts = await getCollection('blog', ({ data }) => {
  return data.draft !== true;
});

// Filter drafts only in production
const posts = await getCollection('blog', ({ data }) => {
  return import.meta.env.PROD ? data.draft !== true : true;
});

// Filter by ID prefix (nested directories)
const englishDocs = await getCollection('docs', ({ id }) => {
  return id.startsWith('en/');
});

// Combine multiple filters
const recentTutorials = await getCollection('blog', ({ data }) => {
  return (
    data.category === 'tutorial' &&
    data.draft !== true &&
    data.pubDate > new Date('2025-01-01')
  );
});
```

## Sorting

Collections return entries in non-deterministic order. Always sort explicitly when order matters.

```typescript
// Sort by date, newest first
const posts = (await getCollection('blog')).sort(
  (a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
);

// Sort alphabetically by title
const posts = (await getCollection('blog')).sort(
  (a, b) => a.data.title.localeCompare(b.data.title)
);

// Sort by multiple fields
const posts = (await getCollection('blog')).sort((a, b) => {
  if (a.data.category !== b.data.category) {
    return a.data.category.localeCompare(b.data.category);
  }
  return b.data.pubDate.valueOf() - a.data.pubDate.valueOf();
});
```

Pitfall: Do not rely on filesystem order or insertion order. The order of entries returned by `getCollection()` is not guaranteed to be consistent between builds. Always apply an explicit sort.

## Rendering with render()

The `render()` function compiles a Markdown or MDX entry into a renderable `<Content />` component and extracts heading data.

```astro
---
import { getEntry, render } from 'astro:content';

const entry = await getEntry('blog', 'my-post');
if (!entry) return Astro.redirect('/404');

const { Content, headings, remarkPluginFrontmatter } = await render(entry);
---

<article>
  <h1>{entry.data.title}</h1>
  <time datetime={entry.data.pubDate.toISOString()}>
    {entry.data.pubDate.toLocaleDateString()}
  </time>
  <Content />
</article>
```

**Return values from `render()`:**

- `Content` -- an Astro component that renders the compiled HTML; use it in the template as `<Content />`
- `headings` -- array of `{ depth: number, slug: string, text: string }` objects for all headings in the document
- `remarkPluginFrontmatter` -- any frontmatter modifications made by remark/rehype plugins

Building a table of contents from headings:

```astro
---
import { getEntry, render } from 'astro:content';

const entry = await getEntry('blog', 'my-post');
const { Content, headings } = await render(entry);
const toc = headings.filter((h) => h.depth <= 3);
---

<nav>
  <h2>Table of Contents</h2>
  <ul>
    {toc.map((heading) => (
      <li style={`margin-left: ${(heading.depth - 1) * 1}rem`}>
        <a href={`#${heading.slug}`}>{heading.text}</a>
      </li>
    ))}
  </ul>
</nav>
<Content />
```

Passing custom components to MDX content:

```astro
---
import { getEntry, render } from 'astro:content';
import Callout from '../components/Callout.astro';
import CodeBlock from '../components/CodeBlock.astro';

const entry = await getEntry('blog', 'mdx-post');
const { Content } = await render(entry);
---

<Content components={{ Callout, CodeBlock }} />
```

Pitfall: `render()` is imported from `astro:content`, not called as a method on the entry. Do not write `entry.render()` -- use `render(entry)` instead.

## Generating Static Routes with getStaticPaths

For static site generation (Astro's default output mode), use `getStaticPaths()` to create a page for each collection entry.

Create a dynamic route file such as `src/pages/blog/[id].astro`:

```astro
---
import { getCollection, render } from 'astro:content';
import BlogLayout from '../../layouts/BlogLayout.astro';

export async function getStaticPaths() {
  const posts = await getCollection('blog');
  return posts.map((post) => ({
    params: { id: post.id },
    props: { post },
  }));
}

const { post } = Astro.props;
const { Content } = await render(post);
---

<BlogLayout title={post.data.title}>
  <h1>{post.data.title}</h1>
  <time datetime={post.data.pubDate.toISOString()}>
    {post.data.pubDate.toLocaleDateString()}
  </time>
  <Content />
</BlogLayout>
```

For entries with nested IDs containing slashes (e.g., `en/getting-started`), use a rest parameter route like `src/pages/docs/[...id].astro`:

```astro
---
import { getCollection, render } from 'astro:content';

export async function getStaticPaths() {
  const docs = await getCollection('docs');
  return docs.map((doc) => ({
    params: { id: doc.id },
    props: { doc },
  }));
}

const { doc } = Astro.props;
const { Content } = await render(doc);
---

<Content />
```

Filtering drafts and sorting within `getStaticPaths()`:

```astro
---
export async function getStaticPaths() {
  const posts = await getCollection('blog', ({ data }) => {
    return import.meta.env.PROD ? data.draft !== true : true;
  });

  const sorted = posts.sort(
    (a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
  );

  return sorted.map((post, index) => ({
    params: { id: post.id },
    props: {
      post,
      prevPost: sorted[index + 1] ?? null,
      nextPost: sorted[index - 1] ?? null,
    },
  }));
}
---
```

## SSR Usage

In server-rendered pages (on-demand rendering), you do not use `getStaticPaths()`. Instead, read the route parameter directly from `Astro.params` and query the entry.

```astro
---
// src/pages/blog/[id].astro
// This page must have `export const prerender = false;` or be covered
// by a server output config.
import { getEntry, render } from 'astro:content';

const { id } = Astro.params;

if (id === undefined) {
  return Astro.redirect("/404");
}

const post = await getEntry("blog", id);

if (post === undefined) {
  return Astro.redirect("/404");
}

const { Content } = await render(post);
---

<article>
  <h1>{post.data.title}</h1>
  <Content />
</article>
```

Always handle the case where `getEntry()` returns `undefined` in SSR, since the user can navigate to any URL.

## Custom IDs via slug

Override the auto-generated entry ID by adding a `slug` field to frontmatter. The `slug` value becomes the entry's `id`. Slashes are allowed in slug values for nested paths.

```markdown
---
title: My Blog Post
slug: my-custom-url/nested
---

Content here.
```

This entry will have `id: "my-custom-url/nested"` instead of the filename-derived ID.

Note: When using `slug` in frontmatter, make sure the `slug` field is included in your Zod schema as an optional string, or use `generateId` in the glob loader for programmatic control over IDs.

## JSON Schema Generation for Editor Support

Astro auto-generates JSON schemas for your collections in the `.astro/collections/` directory. These schemas provide editor IntelliSense for frontmatter and data files.

### JSON Files

Add a `$schema` property to reference the generated schema:

```json
{
  "$schema": "../../../.astro/collections/authors.schema.json",
  "name": "Jane Doe",
  "bio": "Technical writer and web developer."
}
```

### VS Code Configuration

Configure `settings.json` to associate schemas with data files automatically:

```json
{
  "json.schemas": [
    {
      "fileMatch": ["/src/data/authors/**"],
      "url": "./.astro/collections/authors.schema.json"
    }
  ]
}
```

### YAML Files with Red Hat YAML Extension

Add a schema directive comment at the top of the YAML file:

```yaml
# yaml-language-server: $schema=../../../.astro/collections/authors.schema.json
name: Jane Doe
bio: Technical writer and web developer.
```

## Common Pitfalls

1. **Non-deterministic sort order** -- `getCollection()` does not guarantee entry order. Always call `.sort()` explicitly when displaying ordered content like blog post lists.

2. **Schema validation errors at build time** -- If frontmatter does not match the Zod schema, the build fails with a clear error. Use `z.coerce.date()` instead of `z.date()` for date fields parsed from YAML/Markdown strings.

3. **render() import location** -- Import `render` from `astro:content`, not from the entry itself. The correct pattern is `const { Content } = await render(entry)`.

4. **Missing strictNullChecks** -- Without `strictNullChecks: true` in `tsconfig.json`, TypeScript types for collection data will not be inferred correctly, leading to silent type errors.

5. **Forgetting to export collections** -- The `src/content.config.ts` file must export a `collections` object. Omitting the export means Astro will not discover any collections.

6. **SSR null checks** -- In server-rendered pages, `getEntry()` can return `undefined` for invalid IDs. Always guard against this with a redirect or 404 response.

7. **file() loader requires id field** -- Each entry in a JSON/YAML array loaded with `file()` must have an `id` field. Without it, Astro cannot uniquely identify entries.
