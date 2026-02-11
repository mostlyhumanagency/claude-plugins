---
name: submitting-tanstack-form
description: Use when handling TanStack Form submission — onSubmit, onSubmitMeta for multiple submit actions, canSubmit, isPristine, isSubmitting, schema transforms in onSubmit, focus management with onSubmitInvalid
---

# Submitting TanStack Form

## Basic Submission

Call `form.handleSubmit()` inside your form's `onSubmit` handler. Always call `e.preventDefault()` first.

```tsx
<form
  onSubmit={(e) => {
    e.preventDefault()
    form.handleSubmit()
  }}
>
```

## onSubmitMeta: Multiple Submit Actions

Use `onSubmitMeta` to pass metadata that distinguishes different submit actions. The metadata is available in the `onSubmit` callback via `meta`.

```tsx
type FormMeta = { submitAction: 'continue' | 'backToMenu' | null }

const form = useForm({
  defaultValues: { data: '' },
  onSubmitMeta: { submitAction: null } as FormMeta,
  onSubmit: async ({ value, meta }) => {
    console.log(`Selected action - ${meta.submitAction}`, value)
  },
})

// Button: form.handleSubmit({ submitAction: 'continue' })
```

## canSubmit and isSubmitting

Subscribe to `canSubmit` and `isSubmitting` to control button state.

```tsx
<form.Subscribe
  selector={(state) => [state.canSubmit, state.isSubmitting]}
  children={([canSubmit, isSubmitting]) => (
    <button type="submit" disabled={!canSubmit}>
      {isSubmitting ? '...' : 'Submit'}
    </button>
  )}
/>
```

## isPristine

Combine `isPristine` with `canSubmit` to prevent submission until the user has made changes.

## Schema Transforms in onSubmit

Schemas validate input data but `onSubmit` receives the original input, not the transformed output. If your schema uses `.transform()`, parse again inside `onSubmit` to get the transformed values.

```tsx
const schema = z.object({ age: z.string().transform((age) => Number(age)) })

onSubmit: ({ value }) => {
  const result = schema.parse(value)
}
```

## Focus Management with onSubmitInvalid

Use `onSubmitInvalid` to focus the first invalid field when submission fails validation.

### React DOM

Query for `[aria-invalid="true"]` and focus the first match.

```tsx
onSubmitInvalid() {
  const el = document.querySelector('[aria-invalid="true"]') as HTMLInputElement
  el?.focus()
}
```

### React Native

Maintain a ref array of inputs and iterate to find the first input with errors.
