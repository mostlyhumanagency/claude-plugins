---
name: using-astro-actions
description: Use when defining or calling Astro Actions — defineAction in src/actions/index.ts, Zod input validation, calling actions from client with astro:actions, form actions with method POST, ActionError for error handling, isInputError for field validation, Astro.getActionResult, Astro.callAction, or organizing actions in nested objects.
---

# Astro Actions

Astro Actions are type-safe backend functions defined with `defineAction()`. They handle JSON parsing, input validation via Zod, and standardized error handling. Actions eliminate the need for manual API endpoint scaffolding while providing full type safety across client-server boundaries.

Requirements: Actions require on-demand rendering (SSR). Pages using actions must not be prerendered. Actions are publicly accessible at `/_actions/actionName` -- treat them like public API routes.

## Defining Actions

All actions live in `src/actions/index.ts` and are exported from a `server` object.

```ts
// src/actions/index.ts
import { defineAction } from 'astro:actions';
import { z } from 'astro/zod';

export const server = {
  getGreeting: defineAction({
    input: z.object({
      name: z.string(),
    }),
    handler: async (input) => {
      return `Hello, ${input.name}!`;
    },
  }),
};
```

The `defineAction()` function accepts:

| Property | Required | Description |
|----------|----------|-------------|
| `handler` | Yes | Server-side function receiving validated input and an `ActionAPIContext` as second arg |
| `input` | No | Zod schema for runtime validation. Returns `BAD_REQUEST` on failure |
| `accept` | No | `"json"` (default) or `"form"` for FormData |

The handler can return values serialized via devalue, which supports `Date`, `Map`, `Set`, and `URL` in addition to standard JSON types.

### Handler Context

The handler receives a second argument with a subset of the Astro global (cookies, locals, request, url, etc.):

```ts
getGreeting: defineAction({
  input: z.object({ name: z.string() }),
  handler: async (input, context) => {
    // context.cookies, context.locals, context.request, context.url
    const user = context.locals.user;
    return `Hello, ${input.name}! Welcome back, ${user.email}.`;
  },
}),
```

### Actions Without Input

When no validation is needed, omit the `input` property. The handler receives `undefined` as its first argument:

```ts
getRandomNumber: defineAction({
  handler: async () => {
    return Math.random();
  },
}),
```

## Zod Input Validation

### JSON Input (Default)

Use standard Zod schemas for JSON payloads:

```ts
createPost: defineAction({
  input: z.object({
    title: z.string().min(1).max(200),
    body: z.string().min(10),
    tags: z.array(z.string()).optional(),
    publishAt: z.date().optional(),
  }),
  handler: async (input) => {
    // input is fully typed: { title: string; body: string; tags?: string[]; publishAt?: Date }
    const post = await db.insert(posts).values(input);
    return { id: post.id };
  },
}),
```

### Form Input (accept: 'form')

Set `accept: 'form'` to accept FormData from HTML forms. Special Zod coercions apply for form fields:

```ts
submitComment: defineAction({
  accept: 'form',
  input: z.object({
    // Text fields
    author: z.string(),
    body: z.string().min(1),

    // Number inputs -- use z.number(), Astro coerces automatically
    rating: z.number().min(1).max(5),

    // Checkboxes -- use z.boolean(), Astro coerces automatically
    subscribe: z.boolean(),

    // File uploads -- use z.instanceof(File)
    avatar: z.instanceof(File).optional(),

    // Multiple values (e.g. multiple checkboxes with same name) -- use z.array()
    categories: z.array(z.string()),
  }),
  handler: async (input) => {
    // input.rating is number, input.subscribe is boolean, input.avatar is File
    await saveComment(input);
  },
}),
```

Key rules for form input:
- Empty text fields become `null`, not empty strings.
- `z.number()` and `z.boolean()` are automatically coerced from form strings.
- `z.instanceof(File)` handles file uploads. The form must use `enctype="multipart/form-data"`.
- `z.array(validator)` collects multiple fields with the same `name` attribute.
- Use `.refine()`, `.transform()`, and `.pipe()` on the `z.object()` for cross-field validation.

### Discriminated Unions for Form Variants

Use `z.discriminatedUnion()` when one form handles create and update operations:

```ts
manageProduct: defineAction({
  accept: 'form',
  input: z.discriminatedUnion('intent', [
    z.object({ intent: z.literal('create'), name: z.string(), price: z.number() }),
    z.object({ intent: z.literal('update'), id: z.string(), name: z.string(), price: z.number() }),
  ]),
  handler: async (input) => {
    if (input.intent === 'create') {
      return await createProduct(input);
    }
    return await updateProduct(input.id, input);
  },
}),
```

## Calling Actions from the Client

Import actions from `astro:actions` and call them directly. Works from any client-side script or framework component (React, Vue, Svelte, etc.).

### Safe Calls (data/error Destructuring)

Returns `{ data, error }` -- never throws:

```ts
import { actions } from 'astro:actions';

const { data, error } = await actions.getGreeting({ name: 'Houston' });

if (error) {
  // error is ActionError with code, message, and optional fields
  console.error(error.code, error.message);
  return;
}

// data is the typed return value from the handler
console.log(data); // "Hello, Houston!"
```

### Throwing Calls (.orThrow)

Throws `ActionError` on failure instead of returning it:

```ts
import { actions } from 'astro:actions';

try {
  const greeting = await actions.getGreeting.orThrow({ name: 'Houston' });
  console.log(greeting);
} catch (e) {
  // e is ActionError
  console.error(e.code, e.message);
}
```

Use `.orThrow()` when you want exceptions to propagate to an error boundary or global handler.

### Calling from a React Component

```tsx
import { actions } from 'astro:actions';
import { useState } from 'react';

function LikeButton({ postId }: { postId: string }) {
  const [likes, setLikes] = useState(0);
  const [error, setError] = useState<string | null>(null);

  async function handleClick() {
    const { data, error } = await actions.likePost({ postId });
    if (error) {
      setError(error.message);
      return;
    }
    setLikes(data.likes);
  }

  return (
    <>
      <button onClick={handleClick}>Like ({likes})</button>
      {error && <p className="error">{error}</p>}
    </>
  );
}
```

## Error Handling

### ActionError

Throw `ActionError` from handlers to return structured errors with HTTP status codes:

```ts
import { defineAction, ActionError } from 'astro:actions';
import { z } from 'astro/zod';

export const server = {
  deletePost: defineAction({
    input: z.object({ postId: z.string() }),
    handler: async (input, context) => {
      if (!context.locals.user) {
        throw new ActionError({
          code: 'UNAUTHORIZED',
          message: 'You must be logged in to delete a post.',
        });
      }

      const post = await db.query.posts.findFirst({ where: eq(posts.id, input.postId) });
      if (!post) {
        throw new ActionError({
          code: 'NOT_FOUND',
          message: `Post ${input.postId} not found.`,
        });
      }

      if (post.authorId !== context.locals.user.id) {
        throw new ActionError({
          code: 'FORBIDDEN',
          message: 'You can only delete your own posts.',
        });
      }

      await db.delete(posts).where(eq(posts.id, input.postId));
      return { deleted: true };
    },
  }),
};
```

### Error Codes

ActionError codes map to HTTP statuses:

| Code | HTTP Status |
|------|-------------|
| `BAD_REQUEST` | 400 |
| `UNAUTHORIZED` | 401 |
| `FORBIDDEN` | 403 |
| `NOT_FOUND` | 404 |
| `TIMEOUT` | 405 |
| `CONFLICT` | 409 |
| `PRECONDITION_FAILED` | 412 |
| `PAYLOAD_TOO_LARGE` | 413 |
| `UNSUPPORTED_MEDIA_TYPE` | 415 |
| `UNPROCESSABLE_CONTENT` | 422 |
| `TOO_MANY_REQUESTS` | 429 |
| `CLIENT_CLOSED_REQUEST` | 499 |
| `INTERNAL_SERVER_ERROR` | 500 |
| `SERVICE_UNAVAILABLE` | 503 |
| `GATEWAY_TIMEOUT` | 504 |

### Handling Errors on the Client

```ts
import { actions, isInputError, isActionError } from 'astro:actions';

const { data, error } = await actions.submitComment({ body: '' });

if (error) {
  if (isInputError(error)) {
    // Validation error -- access per-field messages
    const bodyErrors = error.fields.body;
    // bodyErrors is string[] e.g. ["String must contain at least 1 character(s)"]
    console.log('Validation errors:', error.fields);
  } else if (isActionError(error)) {
    // Application error thrown with ActionError
    console.error(`${error.code}: ${error.message}`);
  }
}
```

### isInputError for Field-Level Validation

`isInputError()` is only available when the action's input uses `z.object()`. It provides a `fields` property mapping field names to arrays of error messages:

```astro
---
import { actions, isInputError } from 'astro:actions';

const result = Astro.getActionResult(actions.register);
const inputErrors = result?.error && isInputError(result.error) ? result.error.fields : {};
---

<form method="POST" action={actions.register}>
  <label>
    Email
    <input name="email" type="email" />
    {inputErrors.email && <p class="error">{inputErrors.email.join(', ')}</p>}
  </label>
  <label>
    Password
    <input name="password" type="password" />
    {inputErrors.password && <p class="error">{inputErrors.password.join(', ')}</p>}
  </label>
  <button type="submit">Register</button>
</form>
```

## HTML Form Actions

### Basic Form Submission

Set `method="POST"` and pass the action to the `action` attribute:

```astro
---
import { actions } from 'astro:actions';
---

<form method="POST" action={actions.newsletter}>
  <label>
    Email
    <input name="email" type="email" required />
  </label>
  <button type="submit">Subscribe</button>
</form>
```

### File Upload Forms

Add `enctype="multipart/form-data"` for file uploads:

```astro
---
import { actions } from 'astro:actions';
---

<form method="POST" action={actions.uploadAvatar} enctype="multipart/form-data">
  <label>
    Choose file
    <input name="avatar" type="file" accept="image/*" />
  </label>
  <button type="submit">Upload</button>
</form>
```

### Server-Side Result Handling with Astro.getActionResult

Retrieve the result of a form action in the same Astro component after submission:

```astro
---
import { actions } from 'astro:actions';

const result = Astro.getActionResult(actions.newsletter);

if (result && !result.error) {
  // Action succeeded -- redirect or show success
}
---

{result?.error && <p class="error">{result.error.message}</p>}
{result?.data && <p class="success">Subscribed.</p>}

<form method="POST" action={actions.newsletter}>
  <input name="email" type="email" required />
  <button type="submit">Subscribe</button>
</form>
```

### Redirect on Success

Combine `Astro.getActionResult` with `Astro.redirect`:

```astro
---
import { actions } from 'astro:actions';

const result = Astro.getActionResult(actions.createProduct);
if (result && !result.error) {
  return Astro.redirect(`/products/${result.data.id}`);
}
---

<form method="POST" action={actions.createProduct}>
  <input name="name" required />
  <input name="price" type="number" step="0.01" required />
  <button type="submit">Create Product</button>
</form>
```

### No-Input Form Actions

For actions without input (e.g. logout), the form needs no fields:

```astro
<form method="POST" action={actions.logout}>
  <button type="submit">Log out</button>
</form>
```

## Calling Actions from Astro Components

Use `Astro.callAction()` to call actions server-side from `.astro` component frontmatter:

```astro
---
import { actions } from 'astro:actions';

const searchQuery = Astro.url.searchParams.get('q');
if (searchQuery) {
  const { data, error } = await Astro.callAction(actions.findProducts, {
    query: searchQuery,
  });
}
---

<form>
  <input name="q" type="search" value={searchQuery} />
  <button type="submit">Search</button>
</form>

{data && (
  <ul>
    {data.products.map((product) => (
      <li>{product.name} - ${product.price}</li>
    ))}
  </ul>
)}
```

From API endpoints, use `context.callAction()`:

```ts
// src/pages/api/search.ts
import type { APIRoute } from 'astro';
import { actions } from 'astro:actions';

export const GET: APIRoute = async (context) => {
  const query = context.url.searchParams.get('q') ?? '';
  const { data, error } = await context.callAction(actions.findProducts, { query });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 });
  }

  return new Response(JSON.stringify(data));
};
```

## Organizing Actions

### Nested Objects

Group related actions into nested objects by splitting them into separate files:

```ts
// src/actions/user.ts
import { defineAction } from 'astro:actions';
import { z } from 'astro/zod';

export const user = {
  getProfile: defineAction({
    input: z.object({ userId: z.string() }),
    handler: async (input) => {
      return await db.query.users.findFirst({ where: eq(users.id, input.userId) });
    },
  }),
  updateProfile: defineAction({
    accept: 'form',
    input: z.object({
      displayName: z.string().min(1).max(50),
      bio: z.string().max(500).optional(),
    }),
    handler: async (input, context) => {
      await db.update(users).set(input).where(eq(users.id, context.locals.user.id));
    },
  }),
};
```

```ts
// src/actions/posts.ts
import { defineAction } from 'astro:actions';
import { z } from 'astro/zod';

export const posts = {
  create: defineAction({
    input: z.object({ title: z.string(), body: z.string() }),
    handler: async (input, context) => {
      return await db.insert(postsTable).values({ ...input, authorId: context.locals.user.id });
    },
  }),
  delete: defineAction({
    input: z.object({ id: z.string() }),
    handler: async (input) => {
      await db.delete(postsTable).where(eq(postsTable.id, input.id));
    },
  }),
};
```

```ts
// src/actions/index.ts
import { user } from './user';
import { posts } from './posts';

export const server = {
  user,
  posts,
};
```

Call nested actions with dot notation:

```ts
import { actions } from 'astro:actions';

// From client
const { data } = await actions.user.getProfile({ userId: '123' });

// From form
<form method="POST" action={actions.posts.create}>
```

## Middleware Integration

### getActionContext

Use `getActionContext()` in middleware to intercept, authorize, or transform action calls before they reach the handler:

```ts
// src/middleware.ts
import { defineMiddleware } from 'astro:middleware';
import { getActionContext } from 'astro:actions';

export const onRequest = defineMiddleware(async (context, next) => {
  const { action, setActionResult, serializeActionResult } = getActionContext(context);

  if (!action) {
    // Not an action request -- continue normally
    return next();
  }

  // action.calledFrom is "rpc" (client JS) or "form" (HTML form POST)
  // action.name is the action path, e.g. "user.getProfile"
  // action.handler() executes the action and returns SafeResult

  return next();
});
```

### Authorization in Middleware

Block unauthorized action calls before the handler runs:

```ts
// src/middleware.ts
import { defineMiddleware } from 'astro:middleware';
import { getActionContext, ActionError } from 'astro:actions';

const PUBLIC_ACTIONS = ['login', 'register', 'newsletter'];

export const onRequest = defineMiddleware(async (context, next) => {
  const { action } = getActionContext(context);

  if (action && !PUBLIC_ACTIONS.includes(action.name)) {
    const session = context.cookies.get('session')?.value;
    if (!session) {
      if (action.calledFrom === 'rpc') {
        return new Response(
          JSON.stringify({ error: { code: 'UNAUTHORIZED', message: 'Not logged in' } }),
          { status: 401 }
        );
      }
      return context.redirect('/login');
    }

    // Attach user to locals for handler access
    context.locals.user = await getUserFromSession(session);
  }

  return next();
});
```

### POST/Redirect/GET Pattern

Persist action results across redirects to avoid duplicate form submissions:

```ts
// src/middleware.ts
import { defineMiddleware } from 'astro:middleware';
import { getActionContext } from 'astro:actions';

export const onRequest = defineMiddleware(async (context, next) => {
  const { action, setActionResult, serializeActionResult } = getActionContext(context);

  if (action?.calledFrom === 'form') {
    const result = await action.handler();
    setActionResult(action.name, serializeActionResult(result));
    // Result is now available via Astro.getActionResult() after redirect
  }

  return next();
});
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Defining actions outside `export const server` | All actions must be properties of the exported `server` object |
| Using actions on prerendered pages | Actions require on-demand rendering; set `export const prerender = false` |
| Forgetting `accept: 'form'` for form submissions | JSON is the default; add `accept: 'form'` to handle FormData |
| Missing `enctype="multipart/form-data"` for file uploads | Add the enctype attribute to the form element |
| Using `z.coerce.number()` instead of `z.number()` for form input | Astro handles coercion automatically; use `z.number()` directly |
| Calling `Astro.getActionResult()` without `method="POST"` on the form | The form must use `method="POST"` and an action attribute |
| Treating actions as private endpoints | Actions are public at `/_actions/*`; always validate authorization |

## View Transitions

When using Astro view transitions, add `transition:persist` to form elements to preserve user input when validation errors cause a re-render:

```astro
<form method="POST" action={actions.register} transition:persist>
  <!-- form fields preserved across navigation -->
</form>
```

## Type Utilities

| Type | Import | Purpose |
|------|--------|---------|
| `ActionAPIContext` | `astro:actions` | Handler context type (subset of Astro global) |
| `ActionErrorCode` | `astro:actions` | Union of valid error code strings |
| `ActionInputSchema<T>` | `astro:actions` | Extract Zod input type from an action |
| `ActionReturnType<T>` | `astro:actions` | Extract return type from an action handler |
