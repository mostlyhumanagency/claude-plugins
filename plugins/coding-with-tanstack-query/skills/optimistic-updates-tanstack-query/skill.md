---
name: optimistic-updates-tanstack-query
description: Use when implementing optimistic updates with TanStack Query — updating UI before server confirms, onMutate for cache snapshots, setQueryData for optimistic cache manipulation, rollback on error with onError callback, cancelQueries before optimistic update, useMutationState for cross-component access, or choosing between UI variables approach vs cache manipulation approach.
---

# Optimistic Updates

Update the UI immediately before the server confirms, providing instant feedback.

## Approach 1: Via UI Variables (Simple)

Don't touch the cache — use mutation variables directly in the UI:

```tsx
function TodoList() {
  const queryClient = useQueryClient()
  const { data: todos } = useQuery({ queryKey: ['todos'], queryFn: fetchTodos })

  const addMutation = useMutation({
    mutationFn: (newTodo: string) => postTodo(newTodo),
    onSettled: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
  })

  return (
    <ul>
      {todos?.map(todo => <li key={todo.id}>{todo.text}</li>)}
      {addMutation.isPending && (
        <li style={{ opacity: 0.5 }}>{addMutation.variables}</li>
      )}
      {addMutation.isError && (
        <li style={{ color: 'red' }}>
          {addMutation.variables}
          <button onClick={() => addMutation.mutate(addMutation.variables)}>
            Retry
          </button>
        </li>
      )}
    </ul>
  )
}
```

### Cross-Component with useMutationState

```tsx
// Component that triggers mutation
const addTodo = useMutation({
  mutationKey: ['addTodo'],
  mutationFn: postTodo,
})

// Any component that reads pending state
const pendingTodos = useMutationState<string>({
  filters: { mutationKey: ['addTodo'], status: 'pending' },
  select: (mutation) => mutation.state.variables,
})
```

**When to use**: Single display location, simple cases, no rollback management needed.

## Approach 2: Via Cache Manipulation (Advanced)

Directly update the cache in `onMutate`, snapshot for rollback:

### Adding to a List

```tsx
const addMutation = useMutation({
  mutationFn: postTodo,
  onMutate: async (newTodo) => {
    // 1. Cancel outgoing refetches to prevent overwriting optimistic update
    await queryClient.cancelQueries({ queryKey: ['todos'] })

    // 2. Snapshot previous value for rollback
    const previousTodos = queryClient.getQueryData(['todos'])

    // 3. Optimistically update cache
    queryClient.setQueryData(['todos'], (old) => [
      ...old,
      { id: Date.now(), text: newTodo, done: false },
    ])

    // 4. Return snapshot for rollback context
    return { previousTodos }
  },
  onError: (err, newTodo, context) => {
    // Rollback on error
    queryClient.setQueryData(['todos'], context.previousTodos)
  },
  onSettled: () => {
    // Always refetch to sync with server
    queryClient.invalidateQueries({ queryKey: ['todos'] })
  },
})
```

### Updating a Single Item

```tsx
const updateMutation = useMutation({
  mutationFn: ({ id, ...updates }) => patchTodo(id, updates),
  onMutate: async (updatedTodo) => {
    await queryClient.cancelQueries({ queryKey: ['todo', updatedTodo.id] })

    const previousTodo = queryClient.getQueryData(['todo', updatedTodo.id])

    queryClient.setQueryData(['todo', updatedTodo.id], (old) => ({
      ...old,
      ...updatedTodo,
    }))

    return { previousTodo }
  },
  onError: (err, updatedTodo, context) => {
    queryClient.setQueryData(['todo', updatedTodo.id], context.previousTodo)
  },
  onSettled: (data, error, { id }) => {
    queryClient.invalidateQueries({ queryKey: ['todo', id] })
    queryClient.invalidateQueries({ queryKey: ['todos'] })
  },
})
```

### Deleting from a List

```tsx
const deleteMutation = useMutation({
  mutationFn: (todoId) => deleteTodo(todoId),
  onMutate: async (todoId) => {
    await queryClient.cancelQueries({ queryKey: ['todos'] })
    const previousTodos = queryClient.getQueryData(['todos'])

    queryClient.setQueryData(['todos'], (old) =>
      old.filter(t => t.id !== todoId)
    )

    return { previousTodos }
  },
  onError: (err, todoId, context) => {
    queryClient.setQueryData(['todos'], context.previousTodos)
  },
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['todos'] })
  },
})
```

**When to use**: Multiple components need to see the update, complex UIs, need rollback.

## The Pattern (Cache Approach)

Every optimistic update follows 4 steps:

1. **Cancel** — `cancelQueries` to prevent race conditions
2. **Snapshot** — `getQueryData` to save current state
3. **Optimistic update** — `setQueryData` to update cache immediately
4. **Return context** — return snapshot from `onMutate` for `onError` rollback

Plus cleanup:
- `onError` — restore snapshot
- `onSettled` — `invalidateQueries` to sync with server truth

## Common Mistakes

- Forgetting `cancelQueries` before `setQueryData` — refetch overwrites optimistic update
- Not returning snapshot from `onMutate` — `context` is undefined in `onError`
- Forgetting `onSettled` invalidation — cache stays out of sync with server
- Using `onSuccess` instead of `onSettled` for invalidation — errors leave stale cache
