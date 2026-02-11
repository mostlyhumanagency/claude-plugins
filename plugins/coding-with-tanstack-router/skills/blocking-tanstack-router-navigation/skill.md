---
name: blocking-tanstack-router-navigation
description: Use when working with TanStack Router navigation blocking — useBlocker hook, Block component, shouldBlockFn callback, withResolver for custom confirmation UI, proceed and reset functions, enableBeforeUnload for browser dialog on tab close, preventing navigation with unsaved changes, or custom confirmation dialogs.
---

# Navigation Blocking

Prevent users from navigating away during critical operations (unsaved forms, in-progress payments).

## How It Works

- **Router-controlled navigation**: Blocker functions run sequentially. Navigation proceeds only if ALL blockers return `true`.
- **Browser events** (tab close, refresh): The `onbeforeunload` event shows the browser's native dialog.

## useBlocker Hook

### Simple Confirmation

```tsx
import { useBlocker } from '@tanstack/react-router'

function EditForm() {
  const [isDirty, setIsDirty] = useState(false)

  useBlocker({
    shouldBlockFn: () => {
      if (!isDirty) return false           // Allow navigation
      return !window.confirm('Discard unsaved changes?')  // Block if user cancels
    },
  })

  return <form onChange={() => setIsDirty(true)}>...</form>
}
```

### Custom UI with withResolver

For custom confirmation dialogs instead of `window.confirm`:

```tsx
function EditForm() {
  const [isDirty, setIsDirty] = useState(false)

  const { proceed, reset, status } = useBlocker({
    shouldBlockFn: () => isDirty,
    withResolver: true,
  })

  return (
    <>
      <form onChange={() => setIsDirty(true)}>...</form>

      {status === 'blocked' && (
        <div className="modal-overlay">
          <div className="modal">
            <h2>Unsaved Changes</h2>
            <p>You have unsaved changes. What would you like to do?</p>
            <button onClick={proceed}>Discard & Leave</button>
            <button onClick={reset}>Stay on Page</button>
          </div>
        </div>
      )}
    </>
  )
}
```

### shouldBlockFn Parameters

```tsx
useBlocker({
  shouldBlockFn: ({ current, next }) => {
    // current — current location
    // next — destination location
    // Return true to block, false to allow
    if (next.pathname === '/save') return false  // Always allow save
    return isDirty
  },
})
```

## Block Component

Component-based alternative to the hook:

```tsx
import { Block } from '@tanstack/react-router'

function EditForm() {
  const [isDirty, setIsDirty] = useState(false)

  return (
    <>
      <form onChange={() => setIsDirty(true)}>...</form>

      <Block shouldBlockFn={() => isDirty} withResolver>
        {({ status, proceed, reset }) =>
          status === 'blocked' ? (
            <ConfirmDialog
              onConfirm={proceed}
              onCancel={reset}
              message="Discard unsaved changes?"
            />
          ) : null
        }
      </Block>
    </>
  )
}
```

## Browser beforeunload

Control the native browser dialog for tab close/refresh:

```tsx
useBlocker({
  shouldBlockFn: () => isDirty,
  enableBeforeUnload: () => isDirty,  // Show browser dialog on tab close
  withResolver: true,
})
```

- `enableBeforeUnload` is evaluated separately from `shouldBlockFn`
- The browser dialog is always the native one — you can't customize it
- Some browsers ignore the custom message and show a generic one

## Multiple Blockers

Multiple blockers can coexist. Navigation only proceeds if ALL return `false` (non-blocking):

```tsx
// Form blocker
useBlocker({ shouldBlockFn: () => formIsDirty })

// Payment blocker
useBlocker({ shouldBlockFn: () => paymentInProgress })
```

## Common Mistakes

- Using `window.confirm` with `withResolver: true` — pick one approach, not both
- Not conditionally blocking — always returning `true` blocks ALL navigation
- Forgetting `enableBeforeUnload` — tab close/refresh won't be caught
- Blocking after form submit — clear `isDirty` after successful save
