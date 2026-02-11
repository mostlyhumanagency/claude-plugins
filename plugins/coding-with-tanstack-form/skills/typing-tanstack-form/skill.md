---
name: typing-tanstack-form
description: Use when working with TypeScript in TanStack Form — type inference from defaultValues, strict mode requirement, typed errors and errorMap, disableErrorFlat type narrowing, TS 5.4+ requirement, version pinning advice
---

# TypeScript with TanStack Form

## Requirements

- **TypeScript 5.4 or later** is required
- **`strict: true`** must be enabled in `tsconfig.json`

TanStack Form is built with 100% TypeScript and provides full type inference. The goal is that "you should not be able to distinguish between JavaScript usage and TypeScript usage" — types flow automatically from your configuration.

## Type Inference from defaultValues

Types are inferred from `defaultValues`. You do not need to provide manual generics.

```tsx
const form = useForm({
  defaultValues: {
    firstName: '',        // inferred as string
    age: 0,               // inferred as number
    isActive: false,      // inferred as boolean
    tags: [] as string[], // explicit cast for empty arrays
  },
  onSubmit: async ({ value }) => {
    // value is { firstName: string; age: number; isActive: boolean; tags: string[] }
    console.log(value)
  },
})
```

Field names are type-safe. Typos throw TypeScript errors:

```tsx
// Correct — 'firstName' exists in defaultValues
<form.Field name="firstName" children={(field) => {
  // field.state.value is string
  return <input value={field.state.value} onChange={(e) => field.handleChange(e.target.value)} />
}} />

// TypeScript error — 'fistName' does not exist
<form.Field name="fistName" children={(field) => { /* ... */ }} />
```

## Typed Errors

Validator return types are tracked per-validator. The `errors` array is a union of all possible error types, while `errorMap` gives exact types per validation event.

```tsx
<form.Field
  name="password"
  validators={{
    onChange: ({ value }) =>
      value.length < 8 ? 'Too short' : undefined,
    onBlur: ({ value }) => {
      if (!/[A-Z]/.test(value)) {
        return { message: 'Missing uppercase', level: 'warning' }
      }
      return undefined
    },
  }}
  children={(field) => {
    // field.state.meta.errors is (string | { message: string; level: string })[]
    // field.state.meta.errorMap.onChange is string | undefined
    // field.state.meta.errorMap.onBlur is { message: string; level: string } | undefined

    return (
      <div>
        <input
          value={field.state.value}
          onChange={(e) => field.handleChange(e.target.value)}
          onBlur={field.handleBlur}
        />
        {field.state.meta.errorMap.onChange && (
          <p style={{ color: 'red' }}>{field.state.meta.errorMap.onChange}</p>
        )}
        {field.state.meta.errorMap.onBlur && (
          <p style={{ color: 'orange' }}>{field.state.meta.errorMap.onBlur.message}</p>
        )}
      </div>
    )
  }}
/>
```

## disableErrorFlat for Strict errorMap Typing

By default, `errors` is a flattened array of all validator return types. Use `disableErrorFlat` to get precise per-event types in `errorMap` without any flattening.

```tsx
<form.Field
  name="email"
  disableErrorFlat
  validators={{
    onChange: ({ value }): string | undefined =>
      !value.includes('@') ? 'Invalid email' : undefined,
    onBlur: ({ value }): { code: number; message: string } | undefined =>
      !value.endsWith('.com')
        ? { code: 100, message: 'Wrong domain' }
        : undefined,
  }}
  children={(field) => {
    // With disableErrorFlat, errorMap types are exact per event
    const onChangeError: string | undefined = field.state.meta.errorMap.onChange
    const onBlurError: { code: number; message: string } | undefined =
      field.state.meta.errorMap.onBlur

    return (
      <div>
        <input
          value={field.state.value}
          onChange={(e) => field.handleChange(e.target.value)}
          onBlur={field.handleBlur}
        />
        {onChangeError && <p style={{ color: 'red' }}>{onChangeError}</p>}
        {onBlurError && (
          <p style={{ color: 'red' }}>
            Error {onBlurError.code}: {onBlurError.message}
          </p>
        )}
      </div>
    )
  }}
/>
```

## Version Pinning

Type changes in TanStack Form are considered non-breaking and may be released as **patch versions**. If your project is sensitive to type changes, pin to a specific patch version in `package.json`:

```json
{
  "dependencies": {
    "@tanstack/react-form": "1.2.3"
  }
}
```

Use an exact version (no `^` or `~` prefix) to avoid surprise type changes on install.

## Debugging Common Type Issues

### "unknown" field value type

If `field.state.value` resolves to `unknown`, the form type is too complex for TypeScript to fully infer. Solutions:

- Break the form into smaller components, each handling a subset of fields
- Use `as` cast on the value: `field.state.value as string`
- Simplify `defaultValues` by reducing nesting

### "Type instantiation excessively deep"

This is an edge case in TypeScript's type system with deeply nested or recursive form types. The code works correctly at runtime. Solutions:

- Report the issue on GitHub with a reproduction
- Simplify the form structure if possible
- Use `// @ts-expect-error` as a temporary workaround

### Uncontrolled input warning

If you see "A component is changing an uncontrolled input to be controlled," you are missing a field in `defaultValues`. When a field starts as `undefined` and transitions to `""`, React treats it as uncontrolled-to-controlled.

```tsx
// Wrong — missing 'name' in defaultValues
const form = useForm({
  defaultValues: { email: '' },
})
// <form.Field name="name" /> — value starts as undefined

// Correct — include all fields
const form = useForm({
  defaultValues: { email: '', name: '' },
})
```
