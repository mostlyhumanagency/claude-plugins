---
name: typing-tanstack-query
description: Use when typing TanStack Query with TypeScript — type inference from queryFn, Register interface for global error and meta types, queryOptions helper for type-safe reusable configs, mutationOptions helper, typing custom errors, skipToken for type-safe conditional queries, generics on useQuery useMutation, narrowing data with status checks, or type-safe query keys.
---

# TypeScript with TanStack Query

## Automatic Type Inference

Types flow from `queryFn` automatically:

```tsx
const { data } = useQuery({
  queryKey: ['todos'],
  queryFn: (): Promise<Todo[]> => fetch('/api/todos').then(r => r.json()),
})
// data is Todo[] | undefined
```

**Best practice**: Type the fetch function, not the hook generics:

```tsx
// GOOD — type the function
async function fetchTodos(): Promise<Todo[]> {
  const res = await fetch('/api/todos')
  if (!res.ok) throw new Error('Failed')
  return res.json()
}

const { data } = useQuery({ queryKey: ['todos'], queryFn: fetchTodos })
// data is Todo[] | undefined ✅

// AVOID — explicit generics (reduces inference)
const { data } = useQuery<Todo[], Error>({ queryKey: ['todos'], queryFn: fetchTodos })
```

## Type Narrowing

Use status checks to narrow `data`:

```tsx
const { data, isSuccess, isPending, isError, error } = useQuery({
  queryKey: ['todos'],
  queryFn: fetchTodos,
})

if (isPending) return <Spinner />  // data is undefined here
if (isError) return <p>{error.message}</p>  // error is Error here

// data is Todo[] here (narrowed by discriminated union)
return <ul>{data.map(t => <li key={t.id}>{t.title}</li>)}</ul>
```

## queryOptions Helper

Create type-safe, reusable query configurations:

```tsx
import { queryOptions } from '@tanstack/react-query'

function todoQueryOptions(todoId: string) {
  return queryOptions({
    queryKey: ['todo', todoId] as const,
    queryFn: () => fetchTodo(todoId),
    staleTime: 5 * 60 * 1000,
  })
}

// Full type inference everywhere:
useQuery(todoQueryOptions('1'))
useSuspenseQuery(todoQueryOptions('1'))
queryClient.prefetchQuery(todoQueryOptions('1'))
queryClient.ensureQueryData(todoQueryOptions('1'))

// queryKey carries its queryFn types:
const data = queryClient.getQueryData(todoQueryOptions('1').queryKey)
// data is Todo | undefined ✅
```

## mutationOptions Helper

```tsx
import { mutationOptions } from '@tanstack/react-query'

function createTodoMutationOptions() {
  return mutationOptions({
    mutationFn: (newTodo: { title: string }) => postTodo(newTodo),
    mutationKey: ['createTodo'],
  })
}

const mutation = useMutation(createTodoMutationOptions())
```

## Global Type Registration

Register custom types for the entire app:

```tsx
declare module '@tanstack/react-query' {
  interface Register {
    defaultError: AxiosError        // All errors typed as AxiosError
    queryMeta: { source?: string }  // Custom meta fields
    mutationMeta: { audit?: boolean }
  }
}
```

### Custom Error Types

```tsx
// Option 1: Global registration (affects all hooks)
interface Register {
  defaultError: ApiError
}

// Option 2: Per-query narrowing (no generics needed)
const { error } = useQuery({ queryKey: ['todos'], queryFn: fetchTodos })
if (error && isApiError(error)) {
  console.log(error.statusCode)  // Narrowed to ApiError
}
```

## skipToken for Conditional Queries

Type-safe alternative to `enabled: false` (required for Suspense):

```tsx
import { skipToken, useQuery, useSuspenseQuery } from '@tanstack/react-query'

// With useQuery
const { data } = useQuery({
  queryKey: ['todo', todoId],
  queryFn: todoId ? () => fetchTodo(todoId) : skipToken,
})

// With useSuspenseQuery (enabled is not available)
const { data } = useSuspenseQuery({
  queryKey: ['todo', todoId],
  queryFn: todoId ? () => fetchTodo(todoId) : skipToken,
})
```

## select Type Transformation

```tsx
const { data } = useQuery({
  ...todoQueryOptions('1'),
  select: (todo) => todo.title,  // Transforms Todo → string
})
// data is string | undefined
```

## Typing Query Keys

Register structured keys globally:

```tsx
declare module '@tanstack/react-query' {
  interface Register {
    queryKey: readonly ['todos', ...unknown[]] | readonly ['users', ...unknown[]]
  }
}
```

## Common Mistakes

- Using explicit generics `useQuery<Data, Error>()` when inference works — less type safety
- Typing `error` as `Error` when using Axios — register `defaultError: AxiosError` instead
- Forgetting `as const` on query keys — array types are too wide
- Not using `queryOptions` helper — duplicating types across prefetch and useQuery
- Using `enabled: false` with `useSuspenseQuery` — not supported, use `skipToken`
