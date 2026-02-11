---
name: linking-tanstack-form-fields
description: Use when linking TanStack Form fields together — onChangeListenTo and onBlurListenTo for cross-field validation, listeners API for side effects (onChange/onBlur/onMount/onSubmit), debounced listeners, form-level listeners
---

# Linking TanStack Form Fields

## Cross-Field Validation with onChangeListenTo

When one field's validation depends on another field's value (e.g., password and confirm_password), use `onChangeListenTo` to specify which fields should trigger re-validation.

```tsx
<form.Field
  name="confirm_password"
  validators={{
    onChangeListenTo: ['password'],
    onChange: ({ value, fieldApi }) => {
      if (value !== fieldApi.form.getFieldValue('password')) {
        return 'Passwords do not match'
      }
      return undefined
    },
  }}
>
  {(field) => <input value={field.state.value} onChange={(e) => field.handleChange(e.target.value)} />}
</form.Field>
```

## onBlurListenTo

Same concept as `onChangeListenTo` but triggers re-validation on blur events instead of change events.

## Listeners API: Side Effects on Field Events

The listeners API lets you react to field events and dispatch side effects. There are four events: `onChange`, `onBlur`, `onMount`, and `onSubmit`.

### Example: Reset Province When Country Changes

```tsx
<form.Field
  name="country"
  listeners={{
    onChange: ({ value }) => {
      form.setFieldValue('province', '')
    },
  }}
>
  {(field) => <select value={field.state.value} onChange={(e) => field.handleChange(e.target.value)}>
    {/* options */}
  </select>}
</form.Field>
```

## Debouncing Listeners

Use `onChangeDebounceMs` and `onBlurDebounceMs` to debounce listener callbacks.

```tsx
listeners: {
  onChangeDebounceMs: 500,
  onChange: ({ value }) => {
    /* fires only after 500ms pause */
  },
}
```

## Form-Level Listeners

Access higher-level events that apply to the entire form.

```tsx
useForm({
  listeners: {
    onMount: ({ formApi }) => {
      /* form initialized */
    },
    onChange: ({ fieldApi, formApi }) => {
      /* any field changed */
    },
    onChangeDebounceMs: 500,
  },
})
```

## Listener Parameters

- `onMount` and `onSubmit` receive `formApi`
- `onChange` and `onBlur` receive both `fieldApi` and `formApi`
