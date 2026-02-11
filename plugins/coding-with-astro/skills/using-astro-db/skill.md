---
name: using-astro-db
description: Use when working with Astro DB — defining tables in db/config.ts with defineTable and column types, seeding data in db/seed.ts, querying with Drizzle ORM (select, insert, delete, where, join), filtering with eq/gt/like, batch operations, connecting to Turso/LibSQL for production, or pushing schema changes remotely.
---

# Using Astro DB

Astro DB is a built-in SQL database designed for Astro projects. It uses LibSQL (a SQLite fork) locally during development and connects to a hosted Turso database for production. The query layer is Drizzle ORM, giving you type-safe queries with zero configuration.

## Installation

```bash
npx astro add db
```

This creates the `db/` directory with `config.ts` and `seed.ts` files, and updates `astro.config.mjs`:

```js
// astro.config.mjs
import { defineConfig } from "astro/config";
import db from "@astrojs/db";

export default defineConfig({
  integrations: [db()],
});
```

## Defining Tables

Define your schema in `db/config.ts` using `defineTable` and `column` from `astro:db`:

```ts
// db/config.ts
import { defineDb, defineTable, column } from "astro:db";

const Author = defineTable({
  columns: {
    id: column.number({ primaryKey: true }),
    name: column.text(),
    email: column.text({ unique: true }),
    bio: column.text({ optional: true }),
    createdAt: column.date({ default: new Date() }),
  },
});

const Post = defineTable({
  columns: {
    id: column.number({ primaryKey: true }),
    title: column.text(),
    slug: column.text({ unique: true }),
    content: column.text(),
    published: column.boolean({ default: false }),
    authorId: column.number({ references: () => Author.columns.id }),
    tags: column.json({ default: [] }),
    publishedAt: column.date({ optional: true }),
    createdAt: column.date({ default: new Date() }),
  },
});

const Comment = defineTable({
  columns: {
    id: column.number({ primaryKey: true }),
    postId: column.number({ references: () => Post.columns.id }),
    authorName: column.text(),
    body: column.text(),
    approved: column.boolean({ default: false }),
    createdAt: column.date({ default: new Date() }),
  },
});

export default defineDb({
  tables: { Author, Post, Comment },
});
```

### Column Types

| Type | Function | Description |
|---|---|---|
| Text | `column.text()` | String values |
| Number | `column.number()` | Integer and float values |
| Boolean | `column.boolean()` | True/false values |
| Date | `column.date()` | Date objects, stored as ISO strings |
| JSON | `column.json()` | Arbitrary JSON-serializable data |

### Column Options

| Option | Description |
|---|---|
| `primaryKey: true` | Auto-incrementing primary key |
| `optional: true` | Column allows null values |
| `unique: true` | Values must be unique across all rows |
| `default: value` | Default value when not provided on insert |
| `references: () => Table.columns.col` | Foreign key relationship |

## Seeding Data

Populate the database with initial data in `db/seed.ts`. This file runs automatically during `astro dev` and `astro build`:

```ts
// db/seed.ts
import { db, Author, Post, Comment } from "astro:db";

export default async function seed() {
  await db.insert(Author).values([
    {
      id: 1,
      name: "Alice Johnson",
      email: "alice@example.com",
      bio: "Full-stack developer and technical writer.",
    },
    {
      id: 2,
      name: "Bob Smith",
      email: "bob@example.com",
      bio: "Frontend engineer specializing in Astro.",
    },
  ]);

  await db.insert(Post).values([
    {
      id: 1,
      title: "Getting Started with Astro DB",
      slug: "getting-started-astro-db",
      content: "Astro DB makes it easy to add a database to your Astro project...",
      published: true,
      authorId: 1,
      tags: ["astro", "database", "tutorial"],
      publishedAt: new Date("2026-01-15"),
    },
    {
      id: 2,
      title: "Advanced Drizzle Queries",
      slug: "advanced-drizzle-queries",
      content: "Learn how to write complex queries with Drizzle ORM...",
      published: true,
      authorId: 2,
      tags: ["drizzle", "sql", "advanced"],
      publishedAt: new Date("2026-01-20"),
    },
    {
      id: 3,
      title: "Draft Post",
      slug: "draft-post",
      content: "This post is not published yet.",
      published: false,
      authorId: 1,
      tags: ["draft"],
    },
  ]);

  await db.insert(Comment).values([
    {
      id: 1,
      postId: 1,
      authorName: "Charlie",
      body: "Great introduction, thanks!",
      approved: true,
    },
    {
      id: 2,
      postId: 1,
      authorName: "Dana",
      body: "This helped me get started quickly.",
      approved: true,
    },
  ]);
}
```

## Querying Data

Import `db` and your table references from `astro:db`. All queries use the Drizzle ORM API.

### Select All Rows

```astro
---
// src/pages/posts.astro
import { db, Post } from "astro:db";

const allPosts = await db.select().from(Post);
---

<ul>
  {allPosts.map((post) => (
    <li>
      <a href={`/posts/${post.slug}`}>{post.title}</a>
    </li>
  ))}
</ul>
```

### Select with Filtering

Import filter functions from `astro:db`:

```astro
---
// src/pages/posts/published.astro
import { db, Post, eq } from "astro:db";

const publishedPosts = await db
  .select()
  .from(Post)
  .where(eq(Post.published, true));
---

<ul>
  {publishedPosts.map((post) => (
    <li>{post.title} -- {post.publishedAt?.toLocaleDateString()}</li>
  ))}
</ul>
```

### Filter Functions

| Function | Usage | SQL Equivalent |
|---|---|---|
| `eq(col, val)` | Equal | `col = val` |
| `ne(col, val)` | Not equal | `col != val` |
| `gt(col, val)` | Greater than | `col > val` |
| `gte(col, val)` | Greater than or equal | `col >= val` |
| `lt(col, val)` | Less than | `col < val` |
| `lte(col, val)` | Less than or equal | `col <= val` |
| `like(col, pattern)` | Pattern match | `col LIKE pattern` |
| `inArray(col, values)` | In a set | `col IN (...)` |
| `and(...conditions)` | Combine with AND | `a AND b` |
| `or(...conditions)` | Combine with OR | `a OR b` |
| `not(condition)` | Negate | `NOT a` |

### Complex Filtering

```ts
import { db, Post, eq, gt, like, and, or, inArray } from "astro:db";

// Multiple conditions with AND
const recentPublished = await db
  .select()
  .from(Post)
  .where(
    and(
      eq(Post.published, true),
      gt(Post.publishedAt, new Date("2026-01-01"))
    )
  );

// OR conditions
const featured = await db
  .select()
  .from(Post)
  .where(
    or(
      like(Post.title, "%Astro%"),
      like(Post.title, "%Drizzle%")
    )
  );

// IN clause
const specificPosts = await db
  .select()
  .from(Post)
  .where(inArray(Post.id, [1, 2, 5]));
```

### Selecting Specific Columns

```ts
const titles = await db
  .select({ id: Post.id, title: Post.title, slug: Post.slug })
  .from(Post)
  .where(eq(Post.published, true));
```

### Ordering and Limiting

```ts
import { db, Post, desc, asc } from "astro:db";

const latestPosts = await db
  .select()
  .from(Post)
  .orderBy(desc(Post.publishedAt))
  .limit(5);

const oldestFirst = await db
  .select()
  .from(Post)
  .orderBy(asc(Post.createdAt))
  .limit(10)
  .offset(20);
```

### Count

```ts
import { db, Post, eq, count } from "astro:db";

const result = await db
  .select({ total: count() })
  .from(Post)
  .where(eq(Post.published, true));

const totalPublished = result[0].total;
```

## Inserting Data

```ts
import { db, Post } from "astro:db";

// Single insert
await db.insert(Post).values({
  title: "New Post",
  slug: "new-post",
  content: "Post content here.",
  authorId: 1,
  tags: ["new"],
});

// Multiple inserts
await db.insert(Post).values([
  { title: "Post A", slug: "post-a", content: "...", authorId: 1, tags: [] },
  { title: "Post B", slug: "post-b", content: "...", authorId: 2, tags: [] },
]);
```

### Insert with Returning

```ts
const [newPost] = await db
  .insert(Post)
  .values({
    title: "Created Post",
    slug: "created-post",
    content: "Content.",
    authorId: 1,
    tags: ["test"],
  })
  .returning();

console.log("New post ID:", newPost.id);
```

## Updating Data

```ts
import { db, Post, eq } from "astro:db";

await db
  .update(Post)
  .set({ published: true, publishedAt: new Date() })
  .where(eq(Post.id, 3));
```

## Deleting Data

```ts
import { db, Comment, eq } from "astro:db";

// Delete a single row
await db.delete(Comment).where(eq(Comment.id, 5));

// Delete with complex condition
import { and, lt } from "astro:db";

await db
  .delete(Comment)
  .where(
    and(
      eq(Comment.approved, false),
      lt(Comment.createdAt, new Date("2026-01-01"))
    )
  );
```

## Joins

### Inner Join

```ts
import { db, Post, Author, eq } from "astro:db";

const postsWithAuthors = await db
  .select({
    postTitle: Post.title,
    postSlug: Post.slug,
    authorName: Author.name,
    authorEmail: Author.email,
  })
  .from(Post)
  .innerJoin(Author, eq(Post.authorId, Author.id))
  .where(eq(Post.published, true));
```

### Left Join

```ts
const authorsWithPostCount = await db
  .select({
    authorName: Author.name,
    postCount: count(),
  })
  .from(Author)
  .leftJoin(Post, eq(Author.id, Post.authorId))
  .groupBy(Author.name);
```

### Multiple Joins

```ts
const commentsWithPostsAndAuthors = await db
  .select({
    commentBody: Comment.body,
    commentAuthor: Comment.authorName,
    postTitle: Post.title,
    postAuthorName: Author.name,
  })
  .from(Comment)
  .innerJoin(Post, eq(Comment.postId, Post.id))
  .innerJoin(Author, eq(Post.authorId, Author.id))
  .where(eq(Comment.approved, true));
```

## Batch Operations

Use `db.batch()` to execute multiple queries in a single transaction for better performance and atomicity:

```ts
import { db, Post, Comment, eq } from "astro:db";

const results = await db.batch([
  db.select().from(Post).where(eq(Post.published, true)),
  db.select({ total: count() }).from(Comment).where(eq(Comment.approved, true)),
  db.insert(Post).values({
    title: "Batch Post",
    slug: "batch-post",
    content: "Created in a batch.",
    authorId: 1,
    tags: [],
  }),
]);

const [posts, commentCount, insertResult] = results;
```

All operations in a batch succeed or fail together. If any query fails, the entire batch is rolled back.

## Raw SQL

For queries that Drizzle's query builder cannot express, use the `sql` template tag:

```ts
import { db, sql } from "astro:db";

const results = await db.run(
  sql`SELECT title, COUNT(*) as comment_count
      FROM Post
      LEFT JOIN Comment ON Post.id = Comment.postId
      GROUP BY Post.id
      HAVING comment_count > 5`
);
```

## Production Setup

Astro DB uses a local SQLite file during development. For production, connect to a hosted Turso or LibSQL database.

### Environment Variables

Set two environment variables for remote database access:

```bash
# .env
ASTRO_DB_REMOTE_URL=libsql://your-database.turso.io
ASTRO_DB_APP_TOKEN=your-auth-token
```

### Turso Connection

1. Create a Turso database:

```bash
turso db create my-astro-db
turso db show my-astro-db --url
turso db tokens create my-astro-db
```

2. Set the environment variables with the URL and token from Turso.

3. Build with the `--remote` flag:

```bash
astro build --remote
```

The `--remote` flag tells Astro to connect to the remote database instead of the local SQLite file during the build.

## Pushing Schema Changes

After modifying `db/config.ts`, push the schema to the remote database:

```bash
astro db push --remote
```

This applies non-destructive schema changes (adding new tables, adding new optional columns) to the remote database.

### Breaking Changes

For destructive changes (removing columns, changing column types, removing tables), use `--force-reset`:

```bash
astro db push --remote --force-reset
```

This drops and recreates the affected tables, destroying existing data. Use this only in development or when you have backups. In production, write migration scripts to transform data safely.

## Using with Actions

Astro DB works with Astro Actions for type-safe form handling with database operations:

```ts
// src/actions/index.ts
import { defineAction } from "astro:actions";
import { z } from "astro:schema";
import { db, Comment, eq } from "astro:db";

export const server = {
  addComment: defineAction({
    input: z.object({
      postId: z.number(),
      authorName: z.string().min(1).max(100),
      body: z.string().min(1).max(2000),
    }),
    handler: async (input) => {
      const [comment] = await db
        .insert(Comment)
        .values({
          postId: input.postId,
          authorName: input.authorName,
          body: input.body,
          approved: false,
        })
        .returning();

      return { id: comment.id, message: "Comment submitted for review." };
    },
  }),

  approveComment: defineAction({
    input: z.object({
      commentId: z.number(),
    }),
    handler: async (input) => {
      await db
        .update(Comment)
        .set({ approved: true })
        .where(eq(Comment.id, input.commentId));

      return { success: true };
    },
  }),

  deleteComment: defineAction({
    input: z.object({
      commentId: z.number(),
    }),
    handler: async (input) => {
      await db.delete(Comment).where(eq(Comment.id, input.commentId));
      return { success: true };
    },
  }),
};
```

Using the action in a page:

```astro
---
// src/pages/posts/[slug].astro
import { actions } from "astro:actions";
import { db, Post, Comment, eq, and } from "astro:db";

export const prerender = false;

const { slug } = Astro.params;

const [post] = await db.select().from(Post).where(eq(Post.slug, slug));

if (!post) {
  return Astro.redirect("/404");
}

const comments = await db
  .select()
  .from(Comment)
  .where(and(eq(Comment.postId, post.id), eq(Comment.approved, true)));
---

<article>
  <h1>{post.title}</h1>
  <div set:html={post.content} />
</article>

<section>
  <h2>Comments ({comments.length})</h2>
  {comments.map((comment) => (
    <div class="comment">
      <strong>{comment.authorName}</strong>
      <p>{comment.body}</p>
    </div>
  ))}
</section>

<form method="POST" action={actions.addComment}>
  <input type="hidden" name="postId" value={post.id} />
  <input type="text" name="authorName" placeholder="Your name" required />
  <textarea name="body" placeholder="Your comment" required></textarea>
  <button type="submit">Submit Comment</button>
</form>
```

## Common Pitfalls

1. **The seed file runs on every dev server start.** Insert operations in `db/seed.ts` execute each time you run `astro dev`. Use upsert patterns or check for existing data if you want idempotent seeds.

2. **Column references must use arrow functions.** Write `references: () => Author.columns.id`, not `references: Author.columns.id`. The arrow function prevents circular dependency issues during table definition.

3. **JSON columns are not queryable with SQL operators.** You cannot use `eq`, `like`, or other filters on the contents of a `column.json()` field. Filter JSON data in application code after fetching.

4. **`--remote` is required for production builds.** Without the `--remote` flag, `astro build` uses the local SQLite database. Production deployments must include `--remote` in the build command.

5. **`--force-reset` destroys data.** This flag drops and recreates tables. Never use it against a production database without a backup and a migration plan.

6. **Primary keys auto-increment.** When inserting data, you can omit the `id` field and let the database assign it automatically. Specifying IDs manually in seed files is fine but be aware of auto-increment conflicts.

7. **Dates are stored as ISO strings.** The `column.date()` type stores and retrieves JavaScript `Date` objects, but they are serialized as ISO 8601 strings in the underlying SQLite database. Comparisons with `gt`, `lt`, and `eq` work correctly on date columns.
