---
name: testing-tanstack-query
description: Use when testing TanStack Query hooks and components — creating QueryClient wrapper for tests, renderHook from testing-library, disabling retries in test config, mocking network requests with msw or nock, waitFor for async assertions, testing custom hooks wrapping useQuery, gcTime Infinity for Jest, or isolating QueryClient per test.
---

# Testing TanStack Query

## Test Wrapper Setup

Every test needs an isolated `QueryClient`:

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, renderHook, waitFor } from '@testing-library/react'

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,          // Don't retry in tests — fail immediately
        gcTime: Infinity,      // Prevent "Jest did not exit" warnings
      },
    },
  })
}

function createWrapper() {
  const queryClient = createTestQueryClient()
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  )
}
```

## Testing Components

```tsx
import { render, screen, waitFor } from '@testing-library/react'

test('renders posts', async () => {
  const queryClient = createTestQueryClient()

  render(
    <QueryClientProvider client={queryClient}>
      <PostList />
    </QueryClientProvider>
  )

  // Wait for data to load
  await waitFor(() => {
    expect(screen.getByText('First Post')).toBeInTheDocument()
  })
})
```

## Testing Custom Hooks

```tsx
import { renderHook, waitFor } from '@testing-library/react'

test('usePost fetches post data', async () => {
  const { result } = renderHook(() => usePost('1'), {
    wrapper: createWrapper(),
  })

  await waitFor(() => {
    expect(result.current.isSuccess).toBe(true)
  })

  expect(result.current.data).toEqual({ id: '1', title: 'Test Post' })
})
```

## Mocking Network Requests

### With MSW (Mock Service Worker) — Recommended

```tsx
import { setupServer } from 'msw/node'
import { http, HttpResponse } from 'msw'

const server = setupServer(
  http.get('/api/posts', () => {
    return HttpResponse.json([
      { id: '1', title: 'First Post' },
      { id: '2', title: 'Second Post' },
    ])
  }),
  http.post('/api/posts', async ({ request }) => {
    const body = await request.json()
    return HttpResponse.json({ id: '3', ...body }, { status: 201 })
  })
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

### With nock

```tsx
import nock from 'nock'

test('fetches posts', async () => {
  nock('http://localhost')
    .get('/api/posts')
    .reply(200, [{ id: '1', title: 'Post' }])

  const { result } = renderHook(() => useQuery({
    queryKey: ['posts'],
    queryFn: () => fetch('/api/posts').then(r => r.json()),
  }), { wrapper: createWrapper() })

  await waitFor(() => expect(result.current.isSuccess).toBe(true))
})
```

## Testing Mutations

```tsx
test('creates a todo', async () => {
  const queryClient = createTestQueryClient()

  const { result } = renderHook(
    () => useMutation({
      mutationFn: (title: string) =>
        fetch('/api/todos', {
          method: 'POST',
          body: JSON.stringify({ title }),
        }).then(r => r.json()),
    }),
    { wrapper: createWrapper() }
  )

  result.current.mutate('New Todo')

  await waitFor(() => {
    expect(result.current.isSuccess).toBe(true)
  })

  expect(result.current.data).toEqual({ id: '1', title: 'New Todo' })
})
```

## Testing Error States

```tsx
test('handles fetch error', async () => {
  // Mock error response
  server.use(
    http.get('/api/posts', () => {
      return HttpResponse.json({ message: 'Server Error' }, { status: 500 })
    })
  )

  const { result } = renderHook(() => usePosts(), {
    wrapper: createWrapper(),
  })

  await waitFor(() => {
    expect(result.current.isError).toBe(true)
  })

  expect(result.current.error.message).toContain('Server Error')
})
```

## Testing with Pre-Seeded Cache

```tsx
test('renders cached data immediately', () => {
  const queryClient = createTestQueryClient()

  // Pre-seed the cache
  queryClient.setQueryData(['posts'], [
    { id: '1', title: 'Cached Post' },
  ])

  render(
    <QueryClientProvider client={queryClient}>
      <PostList />
    </QueryClientProvider>
  )

  // Data available immediately — no waitFor needed
  expect(screen.getByText('Cached Post')).toBeInTheDocument()
})
```

## Key Testing Settings

| Setting | Value | Why |
|---------|-------|-----|
| `retry: false` | Fail immediately | Prevents 3x retries with backoff (slow tests) |
| `gcTime: Infinity` | Keep cached | Prevents "Jest did not exit" timer warnings |
| `staleTime: 0` | Default | Ensures queries refetch for each test |

## Isolation Tips

- Create a new `QueryClient` per test — prevents cross-test cache pollution
- Use `afterEach(() => server.resetHandlers())` with MSW
- Don't run tests in parallel that share network mocks
- Clear the client between tests if reusing: `queryClient.clear()`

## Common Mistakes

- Shared `QueryClient` across tests — cached data bleeds between tests
- Not disabling retries — tests take 3x longer to fail
- Missing `waitFor` — assertions run before async data resolves
- Forgetting `gcTime: Infinity` — Jest warns about open handles
