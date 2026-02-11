---
name: validating-tanstack-form
description: Use when adding validation to TanStack Form fields — field-level and form-level validators, sync and async validation, debouncing, Standard Schema (Zod/Valibot/ArkType), custom error types, errorMap, disableErrorFlat, dynamic validation with revalidateLogic
---

# Validating TanStack Form

## Field-Level Validators

Add `validators` to individual `form.Field` components. Validators return a string error message or `undefined` for valid:

```tsx
<form.Field
  name="firstName"
  validators={{
    onChange: ({ value }) =>
      value.length < 2 ? 'Must be at least 2 characters' : undefined,
  }}
>
  {(field) => (
    <div>
      <input
        value={field.state.value}
        onChange={(e) => field.handleChange(e.target.value)}
        onBlur={field.handleBlur}
      />
      {field.state.meta.errors.length > 0 && (
        <em>{field.state.meta.errors.join(', ')}</em>
      )}
    </div>
  )}
</form.Field>
```

## Multiple Validators Per Field

Combine `onChange` and `onBlur` to validate at different times:

```tsx
<form.Field
  name="email"
  validators={{
    onChange: ({ value }) =>
      !value ? 'Email is required' : undefined,
    onBlur: ({ value }) =>
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
        ? 'Invalid email format'
        : undefined,
  }}
>
  {(field) => (
    <div>
      <input
        value={field.state.value}
        onChange={(e) => field.handleChange(e.target.value)}
        onBlur={field.handleBlur}
      />
      {field.state.meta.errors.length > 0 && (
        <em>{field.state.meta.errors.join(', ')}</em>
      )}
    </div>
  )}
</form.Field>
```

## Form-Level Validators

Add validators to `useForm` to validate across multiple fields. Return an object with `form` (form-wide error) and/or `fields` (per-field errors):

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
  onSubmit: async ({ value }) => { /* ... */ },
})
```

**Important:** Field-level errors overwrite form-level errors for the same field name. If both a field validator and a form validator set an error on `confirmPassword`, only the field-level error is shown.

## Async Validation

Use `onChangeAsync` and `onBlurAsync` for async validators like server-side checks:

```tsx
<form.Field
  name="username"
  validators={{
    onChangeAsync: async ({ value }) => {
      const taken = await checkUsernameTaken(value)
      return taken ? 'Username is already taken' : undefined
    },
  }}
>
  {(field) => (
    <div>
      <input
        value={field.state.value}
        onChange={(e) => field.handleChange(e.target.value)}
      />
      {field.state.meta.isValidating && <span>Checking...</span>}
      {field.state.meta.errors.length > 0 && (
        <em>{field.state.meta.errors.join(', ')}</em>
      )}
    </div>
  )}
</form.Field>
```

### Sync + Async Interaction

When both `onChange` (sync) and `onChangeAsync` exist, the sync validator runs first. The async validator only runs if the sync validator passes. To always run async regardless, set `asyncAlways: true`:

```tsx
<form.Field
  name="username"
  asyncAlways={true}
  validators={{
    onChange: ({ value }) =>
      value.length < 3 ? 'Too short' : undefined,
    onChangeAsync: async ({ value }) => {
      const taken = await checkUsernameTaken(value)
      return taken ? 'Already taken' : undefined
    },
  }}
>
  {(field) => /* ... */}
</form.Field>
```

## Debouncing Async Validators

Use `asyncDebounceMs` on the Field to debounce all async validators, or use per-validator overrides:

```tsx
<form.Field
  name="username"
  asyncDebounceMs={500}
  validators={{
    onChangeAsync: async ({ value }) => {
      const taken = await checkUsernameTaken(value)
      return taken ? 'Username is already taken' : undefined
    },
    onBlurAsync: async ({ value }) => {
      // This one gets a custom debounce
      const valid = await validateUsernameFormat(value)
      return valid ? undefined : 'Invalid format'
    },
    onBlurAsyncDebounceMs: 200,
  }}
>
  {(field) => /* ... */}
</form.Field>
```

## Standard Schema Validation (Zod / Valibot / ArkType)

Pass a Zod, Valibot, or ArkType schema directly as a validator value — no adapter needed:

```tsx
import { z } from 'zod'

<form.Field
  name="age"
  validators={{
    onChange: z.number().min(18, 'Must be 18 or older'),
  }}
>
  {(field) => (
    <input
      type="number"
      value={field.state.value}
      onChange={(e) => field.handleChange(Number(e.target.value))}
    />
  )}
</form.Field>
```

### Combining Schema with Custom Logic

Use `fieldApi.parseValueWithSchema()` to run a schema validator and then layer on custom logic:

```tsx
<form.Field
  name="email"
  validators={{
    onChange: ({ value, fieldApi }) => {
      // Run schema first
      const schemaError = fieldApi.parseValueWithSchema(
        z.string().email('Invalid email'),
      )
      if (schemaError) return schemaError

      // Custom logic after schema passes
      if (value.endsWith('@banned.com')) {
        return 'This email domain is not allowed'
      }
      return undefined
    },
  }}
>
  {(field) => /* ... */}
</form.Field>
```

## Custom Error Types

Errors are not limited to strings. Any truthy value is treated as an error — you can use numbers, booleans, objects, or arrays:

```tsx
<form.Field
  name="age"
  validators={{
    onChange: ({ value }) => {
      if (value < 18) {
        return { code: 'TOO_YOUNG', minimum: 18, actual: value }
      }
      return undefined
    },
  }}
>
  {(field) => (
    <div>
      <input
        type="number"
        value={field.state.value}
        onChange={(e) => field.handleChange(Number(e.target.value))}
      />
      {field.state.meta.errors.map((error) => {
        if (typeof error === 'object' && error.code === 'TOO_YOUNG') {
          return <em key="age">Must be at least {error.minimum}</em>
        }
        return null
      })}
    </div>
  )}
</form.Field>
```

## errorMap: Errors by Source

By default, errors from all sources (onChange, onBlur, onSubmit) are flattened into a single `errors` array. Use `errorMap` to access errors by their validation source:

```tsx
<form.Field
  name="email"
  validators={{
    onChange: ({ value }) =>
      !value ? 'Required' : undefined,
    onBlur: ({ value }) =>
      !/\S+@\S+\.\S+/.test(value) ? 'Invalid email' : undefined,
  }}
>
  {(field) => (
    <div>
      <input
        value={field.state.value}
        onChange={(e) => field.handleChange(e.target.value)}
        onBlur={field.handleBlur}
      />
      {/* Show onChange errors inline */}
      {field.state.meta.errorMap.onChange && (
        <em>{field.state.meta.errorMap.onChange}</em>
      )}
      {/* Show onBlur errors after user leaves field */}
      {field.state.meta.errorMap.onBlur && (
        <em>{field.state.meta.errorMap.onBlur}</em>
      )}
    </div>
  )}
</form.Field>
```

## disableErrorFlat

By default, all errors are merged into `field.state.meta.errors`. Set `disableErrorFlat: true` on the field to preserve error sources and only use `errorMap`:

```tsx
<form.Field
  name="email"
  disableErrorFlat={true}
  validators={{
    onChange: ({ value }) => !value ? 'Required' : undefined,
    onBlur: ({ value }) => !/\S+@\S+/.test(value) ? 'Invalid' : undefined,
  }}
>
  {(field) => (
    <div>
      <input
        value={field.state.value}
        onChange={(e) => field.handleChange(e.target.value)}
        onBlur={field.handleBlur}
      />
      {/* field.state.meta.errors is empty when disableErrorFlat is true */}
      {/* Use errorMap instead */}
      {field.state.meta.errorMap.onChange && (
        <em>{field.state.meta.errorMap.onChange}</em>
      )}
    </div>
  )}
</form.Field>
```

## Dynamic Validation with revalidateLogic

Use `onDynamic` with `revalidateLogic` to change validation behavior before and after submission:

```tsx
<form.Field
  name="username"
  validators={{
    onDynamic: revalidateLogic({
      mode: 'onBlur',              // Before submit: validate on blur only
      modeAfterSubmission: 'onChange', // After submit: validate on every change
    }),
  }}
>
  {(field) => (
    <input
      value={field.state.value}
      onChange={(e) => field.handleChange(e.target.value)}
      onBlur={field.handleBlur}
    />
  )}
</form.Field>
```

This provides a better UX: lenient validation while the user fills out the form, strict validation after they attempt to submit.

## canSubmit Flag

`form.state.canSubmit` is `false` when any field has errors AND has been touched. Use it to disable the submit button:

```tsx
<form.Subscribe selector={(state) => state.canSubmit}>
  {(canSubmit) => (
    <button type="submit" disabled={!canSubmit}>
      Submit
    </button>
  )}
</form.Subscribe>
```

## Common Mistakes

- Forgetting `onBlur={field.handleBlur}` — onBlur validators never fire
- Returning `''` (empty string) from a validator — this is falsy, so it is treated as valid, not an error
- Expecting form-level field errors to survive when a field-level validator also exists — field-level always wins
- Not debouncing expensive async validators — causes excessive API calls on every keystroke
- Using `asyncAlways: true` without understanding it runs async even when sync fails
