---
name: using-react-actions
description: Use when working with React forms, async actions, or needing optimistic UI updates
---

## Overview

React Actions are async functions used in transitions that automatically handle pending states, errors, forms, and optimistic updates. They unify form handling through three key hooks: `useActionState` for managing submission state, `useFormStatus` for reading parent form status, and `useOptimistic` for immediate UI feedback.

## When to Use

- Handling form submissions with built-in pending/error states
- Creating reusable submit buttons that reflect form status
- Showing optimistic UI updates before server response
- Managing complex form workflows with validation and errors
- Coordinating multiple async operations with user feedback

**When NOT to use:**
- Simple onClick handlers without forms (use regular async functions)
- Read-only data fetching (use server components or queries)
- Non-form transitions (use `useTransition` directly)

## Core Patterns

### Form with useActionState

Manages form submission state, errors, and pending status in one hook.

```tsx
import { useActionState } from "react";

async function addToCart(prevState: { message: string } | null, formData: FormData) {
  const itemId = formData.get("itemId") as string;
  const result = await api.addToCart(itemId);
  if (!result.success) return { message: result.error };
  return null;
}

function AddToCartForm({ itemId }: { itemId: string }) {
  const [state, formAction, isPending] = useActionState(addToCart, null);

  return (
    <form action={formAction}>
      <input type="hidden" name="itemId" value={itemId} />
      <button type="submit" disabled={isPending}>
        {isPending ? "Adding..." : "Add to Cart"}
      </button>
      {state?.message && <p className="error">{state.message}</p>}
    </form>
  );
}
```

### Reusable Submit Button with useFormStatus

Read parent form status without prop drilling — must be a child of `<form>`.

```tsx
import { useFormStatus } from "react-dom";

function SubmitButton({ label = "Submit" }: { label?: string }) {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending}>
      {pending ? "Submitting..." : label}
    </button>
  );
}

// Usage
<form action={submitAction}>
  <input name="email" type="email" required />
  <SubmitButton label="Subscribe" />
</form>
```

### Optimistic Updates with useOptimistic

Show immediate feedback while async action completes, auto-reverts on error.

```tsx
import { useOptimistic } from "react";

function TodoList({ todos, addTodoAction }: {
  todos: Todo[];
  addTodoAction: (formData: FormData) => Promise<void>;
}) {
  const [optimisticTodos, addOptimistic] = useOptimistic(
    todos,
    (current, newTodo) => [...current, { ...newTodo, sending: true }]
  );

  async function handleSubmit(formData: FormData) {
    const text = formData.get("text") as string;
    addOptimistic({ id: crypto.randomUUID(), text });
    await addTodoAction(formData);
  }

  return (
    <>
      <ul>
        {optimisticTodos.map((todo) => (
          <li key={todo.id} style={{ opacity: todo.sending ? 0.5 : 1 }}>
            {todo.text}
          </li>
        ))}
      </ul>
      <form action={handleSubmit}>
        <input name="text" required />
        <SubmitButton label="Add" />
      </form>
    </>
  );
}
```

## Quick Reference

| Hook | Returns | Purpose |
|------|---------|---------|
| `useActionState(fn, initial)` | `[state, formAction, isPending]` | Form state + submission |
| `useFormStatus()` | `{ pending, data, method, action }` | Read parent form status |
| `useOptimistic(value, reducer)` | `[optimisticState, setOptimistic]` | Immediate UI feedback |

See [reference.md](./reference.md) for full API details and advanced patterns.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `useFormStatus` in same component as `<form>` | Move to a child component rendered inside `<form>` |
| Creating action fn inside render | Define outside component or use `useCallback` |
| `useActionState` fn missing first arg | First arg is always previous state: `fn(prevState, formData)` |
| Forgetting `type="submit"` on button | Add `type="submit"` to trigger form action |
| `useOptimistic` called outside transition | Call setter inside `startTransition` or form action |
