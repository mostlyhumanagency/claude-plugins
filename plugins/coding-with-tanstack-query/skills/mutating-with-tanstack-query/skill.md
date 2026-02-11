---
name: mutating-with-tanstack-query
description: Use when working with TanStack Query mutations — useMutation hook, mutationFn, mutate and mutateAsync functions, isPending isError isSuccess mutation states, onMutate onSuccess onError onSettled lifecycle callbacks, mutation variables, reset mutation state, mutation scopes for serial execution, mutationKey, component-level callbacks on mutate, or retry configuration for mutations.
---

# Mutations with TanStack Query

Mutations handle create, update, and delete operations. Unlike queries, they're explicitly triggered.

## Basic useMutation

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query'

function AddTodo() {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn: (newTodo: { title: string }) => {
      return fetch('/api/todos', {
        method: 'POST',
        body: JSON.stringify(newTodo),
        headers: { 'Content-Type': 'application/json' },
      }).then(res => {
        if (!res.ok) throw new Error('Failed')
        return res.json()
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] })
    },
  })

  return (
    <button
      onClick={() => mutation.mutate({ title: 'New Todo' })}
      disabled={mutation.isPending}
    >
      {mutation.isPending ? 'Adding...' : 'Add Todo'}
    </button>
  )
}
```

## Mutation States

| Property | Meaning |
|----------|---------|
| `isIdle` | Not yet triggered |
| `isPending` | Currently executing |
| `isError` | Failed |
| `isSuccess` | Completed successfully |
| `data` | Success response data |
| `error` | Error object |
| `variables` | Variables passed to `mutate()` |

## Lifecycle Callbacks

```tsx
useMutation({
  mutationFn: updateTodo,
  onMutate: (variables) => {
    // Fires BEFORE mutation — use for optimistic updates
    // Return value is passed to onError/onSettled as context
    console.log('Starting with:', variables)
    return { previousData: getCurrentData() }
  },
  onSuccess: (data, variables, context) => {
    // Fires on success
    // context = return value from onMutate
    queryClient.invalidateQueries({ queryKey: ['todos'] })
  },
  onError: (error, variables, context) => {
    // Fires on failure — use for rollback
    console.error('Failed:', error.message)
  },
  onSettled: (data, error, variables, context) => {
    // Fires on BOTH success and error — use for cleanup
    queryClient.invalidateQueries({ queryKey: ['todos'] })
  },
})
```

### Callback Order

1. `onMutate` (before mutation)
2. Mutation executes
3. `onSuccess` OR `onError`
4. `onSettled` (always)

## mutate vs mutateAsync

```tsx
const mutation = useMutation({ mutationFn: createTodo })

// Fire-and-forget (use callbacks for side effects)
mutation.mutate(data)

// Promise-based (for sequential operations)
try {
  const result = await mutation.mutateAsync(data)
  console.log('Created:', result)
} catch (error) {
  console.error('Failed:', error)
}
```

## Component-Level Callbacks

Override or extend callbacks per `mutate()` call:

```tsx
mutation.mutate(data, {
  onSuccess: (data) => {
    // Fires AFTER hook-level onSuccess
    toast.success('Saved!')
    navigate('/dashboard')
  },
  onError: (error) => {
    toast.error(error.message)
  },
})
```

Hook-level callbacks fire first, then component-level callbacks.

## Resetting Mutation State

```tsx
function Form() {
  const mutation = useMutation({ mutationFn: submitForm })

  return (
    <div>
      {mutation.isError && (
        <div>
          <p>Error: {mutation.error.message}</p>
          <button onClick={() => mutation.reset()}>Dismiss</button>
        </div>
      )}
      <button onClick={() => mutation.mutate(formData)}>Submit</button>
    </div>
  )
}
```

## Mutation Scopes (Serial Execution)

Force mutations with the same scope to run sequentially:

```tsx
const mutation = useMutation({
  mutationFn: updateTodo,
  scope: { id: 'todo-updates' },
})
// Queued mutations start with isPaused: true until previous completes
```

## Mutation Keys

Use `mutationKey` to track mutations across components:

```tsx
// In component A
useMutation({
  mutationKey: ['addTodo'],
  mutationFn: addTodo,
})

// In component B — read mutation state
import { useMutationState } from '@tanstack/react-query'

const pendingTodos = useMutationState({
  filters: { mutationKey: ['addTodo'], status: 'pending' },
  select: (mutation) => mutation.state.variables,
})
```

## Retry

```tsx
useMutation({
  mutationFn: createTodo,
  retry: 3,           // Retry 3 times
  retryDelay: 1000,   // 1 second between retries
})
```

## Common Mistakes

- Calling `mutate()` in render — causes infinite loop, use in event handlers or effects
- Not invalidating queries after mutation — UI shows stale data
- Using `mutateAsync` without try/catch — unhandled rejections
- Accessing `mutation.data` before checking `isSuccess` — data is undefined
- Forgetting that component callbacks fire AFTER hook callbacks
