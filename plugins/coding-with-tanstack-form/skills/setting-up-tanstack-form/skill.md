---
name: setting-up-tanstack-form
description: Use when setting up TanStack Form in a React project — installing, useForm hook, defaultValues, formOptions, form.Field component, handleSubmit, DevTools configuration
---

# Setting Up TanStack Form

## Installation

```bash
npm install @tanstack/react-form
# Optional: validator adapter for schema-based validation
npm install @tanstack/zod-form-adapter zod
```

## useForm Hook

Create a form instance with `useForm`. Pass `defaultValues` and an `onSubmit` handler:

```tsx
import { useForm } from '@tanstack/react-form'

function SignupForm() {
  const form = useForm({
    defaultValues: {
      username: '',
      email: '',
      age: 0,
    },
    onSubmit: async ({ value }) => {
      // value is fully typed: { username: string; email: string; age: number }
      await createUser(value)
    },
  })

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        form.handleSubmit()
      }}
    >
      {/* fields go here */}
      <button type="submit">Sign Up</button>
    </form>
  )
}
```

## form.Field Component

`form.Field` renders a controlled field with a type-safe `name` prop and a render function:

```tsx
<form.Field name="username">
  {(field) => (
    <div>
      <label htmlFor={field.name}>Username</label>
      <input
        id={field.name}
        value={field.state.value}
        onChange={(e) => field.handleChange(e.target.value)}
        onBlur={field.handleBlur}
      />
      {field.state.meta.errors.length > 0 && (
        <span>{field.state.meta.errors.join(', ')}</span>
      )}
    </div>
  )}
</form.Field>
```

### Field State and Handlers

- **field.state.value** — current value of the field
- **field.handleChange(value)** — update the field value (type-safe)
- **field.handleBlur** — call on blur to trigger onBlur validators

### Field Metadata (`field.state.meta`)

| Property | Type | Description |
|---|---|---|
| `isTouched` | `boolean` | Field has been blurred at least once |
| `isDirty` | `boolean` | Value differs from defaultValue (persistent — reverts if you set it back) |
| `isPristine` | `boolean` | Opposite of isDirty |
| `isBlurred` | `boolean` | Currently in a blurred state |
| `isDefaultValue` | `boolean` | Current value strictly equals defaultValue |
| `errors` | `string[]` | Flattened array of current errors |

### Persistent Dirty Tracking

Unlike React Hook Form, TanStack Form's `isDirty` is persistent. If a user types "hello" and then deletes it back to the default value, `isDirty` returns to `false`. Use `isDefaultValue` if you want non-persistent behavior that just compares to the initial value.

## formOptions for Shared Configuration

Use `formOptions()` to define reusable form configuration shared across multiple forms:

```tsx
import { formOptions, useForm } from '@tanstack/react-form'

const userFormOpts = formOptions({
  defaultValues: {
    firstName: '',
    lastName: '',
    email: '',
  },
})

function CreateUserForm() {
  const form = useForm({
    ...userFormOpts,
    onSubmit: async ({ value }) => {
      await createUser(value)
    },
  })
  // ...
}

function EditUserForm({ user }: { user: User }) {
  const form = useForm({
    ...userFormOpts,
    defaultValues: user, // override defaults
    onSubmit: async ({ value }) => {
      await updateUser(value)
    },
  })
  // ...
}
```

## Validators on useForm

You can pass form-level validators directly to useForm:

```tsx
const form = useForm({
  defaultValues: { password: '', confirmPassword: '' },
  validators: {
    onChange: ({ value }) => {
      if (value.password !== value.confirmPassword) {
        return {
          form: 'Passwords do not match',
          fields: {
            confirmPassword: 'Must match password',
          },
        }
      }
      return undefined
    },
  },
  onSubmit: async ({ value }) => {
    // ...
  },
})
```

## Reset Handling

When adding a reset button, always use `event.preventDefault()` to prevent the HTML default reset from conflicting with TanStack Form's controlled state:

```tsx
<button
  type="button"
  onClick={(e) => {
    e.preventDefault()
    form.reset()
  }}
>
  Reset
</button>
```

## DevTools

Install the DevTools packages:

```bash
npm install @tanstack/react-devtools @tanstack/react-form-devtools
```

Add DevTools to your app:

```tsx
import { TanStackDevtools } from '@tanstack/react-devtools'
import { formDevtoolsPlugin } from '@tanstack/react-form-devtools'

function App() {
  return (
    <>
      <YourApp />
      <TanStackDevtools plugins={[formDevtoolsPlugin]} />
    </>
  )
}
```

DevTools are tree-shaken in production builds.

## Common Mistakes

- Forgetting `e.preventDefault()` on the form's `onSubmit` — causes page reload
- Not calling `form.handleSubmit()` — form submission never fires
- Mutating `field.state.value` directly instead of using `field.handleChange`
- Forgetting `onBlur={field.handleBlur}` — onBlur validators never trigger
- Using a reset button without `preventDefault()` — causes HTML default reset to fight with controlled state
