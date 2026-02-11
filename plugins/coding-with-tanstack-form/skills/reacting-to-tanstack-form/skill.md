---
name: reacting-to-tanstack-form
description: Use when subscribing to TanStack Form state reactively — useStore hook with selectors, form.Subscribe component, performance optimization, avoiding unnecessary re-renders
---

# Reacting to TanStack Form State

## Core Concept

TanStack Form does NOT automatically trigger re-renders during form interactions. You must explicitly subscribe to the form state values you need. There are two methods: the `useStore` hook and the `form.Subscribe` component.

## useStore Hook

Use `useStore` to access form values in component logic. It takes `form.store` and a selector function.

**ALWAYS include a selector** to avoid subscribing to the entire store and causing unnecessary re-renders.

```tsx
import { useStore } from '@tanstack/react-store'
import { useForm } from '@tanstack/react-form'

function MyForm() {
  const form = useForm({
    defaultValues: {
      firstName: '',
      lastName: '',
      email: '',
    },
    onSubmit: async ({ value }) => {
      console.log(value)
    },
  })

  // Subscribe to specific values with selectors
  const firstName = useStore(form.store, (state) => state.values.firstName)
  const errors = useStore(form.store, (state) => state.errorMap)
  const isSubmitting = useStore(form.store, (state) => state.isSubmitting)

  // Now you can use these in component logic
  if (isSubmitting) {
    return <p>Submitting...</p>
  }

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        form.handleSubmit()
      }}
    >
      <form.Field
        name="firstName"
        children={(field) => (
          <input
            value={field.state.value}
            onChange={(e) => field.handleChange(e.target.value)}
          />
        )}
      />
      {firstName && <p>Hello, {firstName}!</p>}
    </form>
  )
}
```

**Caveat:** When the subscribed value changes, the entire component re-renders — not just the part that uses the value.

## form.Subscribe Component

Use `form.Subscribe` to react to state changes in JSX without re-rendering the parent component. Only the `Subscribe` component's children re-render when the selected value changes.

```tsx
function MyForm() {
  const form = useForm({
    defaultValues: {
      firstName: '',
      lastName: '',
    },
    onSubmit: async ({ value }) => {
      console.log(value)
    },
  })

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        form.handleSubmit()
      }}
    >
      <form.Field
        name="firstName"
        children={(field) => (
          <input
            value={field.state.value}
            onChange={(e) => field.handleChange(e.target.value)}
          />
        )}
      />

      {/* Only this Subscribe block re-renders when firstName changes */}
      <form.Subscribe
        selector={(state) => state.values.firstName}
        children={(firstName) => <p>Hello, {firstName}</p>}
      />

      {/* Subscribe to multiple values */}
      <form.Subscribe
        selector={(state) => ({
          canSubmit: state.canSubmit,
          isSubmitting: state.isSubmitting,
        })}
        children={({ canSubmit, isSubmitting }) => (
          <button type="submit" disabled={!canSubmit || isSubmitting}>
            {isSubmitting ? 'Submitting...' : 'Submit'}
          </button>
        )}
      />
    </form>
  )
}
```

## When to Use Which

| Scenario | Use |
|---|---|
| Conditional rendering in component logic | `useStore` |
| Side effects based on form state | `useStore` |
| Display text, buttons, UI labels | `form.Subscribe` |
| Disabling/enabling submit button | `form.Subscribe` |
| Showing validation summary | `form.Subscribe` |

**Prefer `form.Subscribe`** whenever possible to isolate re-renders. Use `useStore` only when you need the value in component logic outside of JSX.

## Performance Tips

- **Never omit the selector.** Subscribing to the entire store (`useStore(form.store, (state) => state)`) causes re-renders on every single state change.
- **Use `form.Subscribe` over `useStore`** when the value is only needed in JSX — it isolates re-renders to just the Subscribe children.
- **Subscribe to specific values, not entire objects.** Select `state.values.firstName` instead of `state.values`.
- **Keep selectors stable.** If your selector returns a new object reference every render, use a memoized selector or select primitive values.
