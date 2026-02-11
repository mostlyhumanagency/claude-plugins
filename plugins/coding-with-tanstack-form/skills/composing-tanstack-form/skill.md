---
name: composing-tanstack-form
description: Use when composing TanStack Form with reusable components — createFormHook, createFormHookContexts, useFieldContext, AppField, AppForm, withForm HOC, withFieldGroup, field groups, field mapping, tree-shaking with React.lazy
---

# Composing TanStack Form

## The Problem

Using `useForm` + `form.Field` directly works for small forms, but becomes verbose and repetitive in large applications. You end up duplicating input markup, labels, error rendering, and validation logic across every form.

## createFormHook: Pre-Bound Form Hook

Create a shared form hook with pre-registered field and form components using `createFormHookContexts` and `createFormHook`:

```tsx
// src/hooks/form.ts
import { createFormHookContexts, createFormHook } from '@tanstack/react-form'
import { TextField } from '../components/TextField'
import { NumberField } from '../components/NumberField'
import { SubmitButton } from '../components/SubmitButton'

export const { fieldContext, formContext } = createFormHookContexts()

export const { useAppForm } = createFormHook({
  fieldContext,
  formContext,
  fieldComponents: {
    TextField,
    NumberField,
  },
  formComponents: {
    SubmitButton,
  },
})
```

## Reusable Field Components with useFieldContext

Use `useFieldContext` to build reusable field components that receive their field state from context rather than props:

```tsx
// src/components/TextField.tsx
import { useFieldContext } from '../hooks/form'

export function TextField({ label }: { label: string }) {
  const field = useFieldContext<string>()

  return (
    <div>
      <label htmlFor={field.name}>{label}</label>
      <input
        id={field.name}
        value={field.state.value}
        onChange={(e) => field.handleChange(e.target.value)}
        onBlur={field.handleBlur}
      />
      {field.state.meta.errors.length > 0 && (
        <em>{field.state.meta.errors.join(', ')}</em>
      )}
    </div>
  )
}
```

```tsx
// src/components/NumberField.tsx
import { useFieldContext } from '../hooks/form'

export function NumberField({ label }: { label: string }) {
  const field = useFieldContext<number>()

  return (
    <div>
      <label htmlFor={field.name}>{label}</label>
      <input
        id={field.name}
        type="number"
        value={field.state.value}
        onChange={(e) => field.handleChange(Number(e.target.value))}
        onBlur={field.handleBlur}
      />
      {field.state.meta.errors.length > 0 && (
        <em>{field.state.meta.errors.join(', ')}</em>
      )}
    </div>
  )
}
```

## Using Pre-Bound Field Components

Use `form.AppField` instead of `form.Field` to access registered field components:

```tsx
import { useAppForm } from '../hooks/form'

function ProfileForm() {
  const form = useAppForm({
    defaultValues: {
      firstName: '',
      lastName: '',
      age: 0,
    },
    onSubmit: async ({ value }) => {
      await updateProfile(value)
    },
  })

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        form.handleSubmit()
      }}
    >
      <form.AppField name="firstName">
        {(field) => <field.TextField label="First Name" />}
      </form.AppField>
      <form.AppField name="lastName">
        {(field) => <field.TextField label="Last Name" />}
      </form.AppField>
      <form.AppField name="age">
        {(field) => <field.NumberField label="Age" />}
      </form.AppField>
      <form.AppForm>
        <SubmitButton />
      </form.AppForm>
    </form>
  )
}
```

### Performance Note

The context values use TanStack Store static class instances under the hood, so they do not cause unnecessary re-renders. Only components subscribed to specific field state will re-render when that state changes.

## Pre-Bound Form Components with useFormContext

Use `useFormContext` for shared form-level components (like submit buttons) that need access to the form instance:

```tsx
// src/components/SubmitButton.tsx
import { useFormContext } from '../hooks/form'

export function SubmitButton() {
  const form = useFormContext()

  return (
    <form.Subscribe selector={(state) => state.canSubmit}>
      {(canSubmit) => (
        <button type="submit" disabled={!canSubmit}>
          Submit
        </button>
      )}
    </form.Subscribe>
  )
}
```

Wrap with `form.AppForm` to provide form context:

```tsx
<form.AppForm>
  <SubmitButton />
</form.AppForm>
```

## withForm HOC: Breaking Large Forms into Pieces

Use `withForm` to split a large form into smaller components without prop drilling. It provides strong type-safety on the form instance:

```tsx
import { useAppForm } from '../hooks/form'
import { withForm } from '@tanstack/react-form'

const PersonalInfoSection = withForm({
  // Provide the form options so TypeScript can infer the form shape
  ...formOpts,
  // Use a named render function for ESLint rules-of-hooks compliance
  render: function PersonalInfoSection({ form }) {
    return (
      <div>
        <h2>Personal Info</h2>
        <form.AppField name="firstName">
          {(field) => <field.TextField label="First Name" />}
        </form.AppField>
        <form.AppField name="lastName">
          {(field) => <field.TextField label="Last Name" />}
        </form.AppField>
      </div>
    )
  },
})

const ContactInfoSection = withForm({
  ...formOpts,
  render: function ContactInfoSection({ form }) {
    return (
      <div>
        <h2>Contact Info</h2>
        <form.AppField name="email">
          {(field) => <field.TextField label="Email" />}
        </form.AppField>
        <form.AppField name="phone">
          {(field) => <field.TextField label="Phone" />}
        </form.AppField>
      </div>
    )
  },
})

function FullForm() {
  const form = useAppForm({
    ...formOpts,
    onSubmit: async ({ value }) => { /* ... */ },
  })

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.handleSubmit() }}>
      <PersonalInfoSection form={form} />
      <ContactInfoSection form={form} />
      <button type="submit">Submit</button>
    </form>
  )
}
```

**Important:** Use a named function expression for the `render` property (e.g., `render: function PersonalInfoSection({ form })`) so ESLint's rules-of-hooks can properly detect hooks used inside the render function.

## withFieldGroup: Reusable Groups of Related Fields

Use `withFieldGroup` to create reusable groups of related fields that can be composed into any form:

```tsx
import { withFieldGroup } from '@tanstack/react-form'

const PasswordGroup = withFieldGroup({
  render: function PasswordGroup({ form }) {
    return (
      <div>
        <form.AppField name="password">
          {(field) => <field.TextField label="Password" />}
        </form.AppField>
        <form.AppField name="confirmPassword">
          {(field) => <field.TextField label="Confirm Password" />}
        </form.AppField>
      </div>
    )
  },
})
```

Nest it inside a form with the `fields` prop:

```tsx
function SignupForm() {
  const form = useAppForm({
    defaultValues: {
      email: '',
      password: '',
      confirmPassword: '',
    },
    onSubmit: async ({ value }) => { /* ... */ },
  })

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.handleSubmit() }}>
      <form.AppField name="email">
        {(field) => <field.TextField label="Email" />}
      </form.AppField>
      <PasswordGroup form={form} />
      <button type="submit">Submit</button>
    </form>
  )
}
```

### Field Mapping

Map group field names to different positions in the form's data structure:

```tsx
function AccountForm() {
  const form = useAppForm({
    defaultValues: {
      email: '',
      security: {
        password: '',
        confirmPassword: '',
      },
    },
    onSubmit: async ({ value }) => { /* ... */ },
  })

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.handleSubmit() }}>
      <PasswordGroup
        form={form}
        fields={{
          password: 'security.password',
          confirmPassword: 'security.confirmPassword',
        }}
      />
      <button type="submit">Submit</button>
    </form>
  )
}
```

## Tree-Shaking with React.lazy

Use `React.lazy()` for field components to enable tree-shaking and code splitting:

```tsx
import { lazy, Suspense } from 'react'
import { createFormHookContexts, createFormHook } from '@tanstack/react-form'

export const { fieldContext, formContext } = createFormHookContexts()

const TextField = lazy(() => import('../components/TextField'))
const RichTextEditor = lazy(() => import('../components/RichTextEditor'))

export const { useAppForm } = createFormHook({
  fieldContext,
  formContext,
  fieldComponents: {
    TextField,
    RichTextEditor,
  },
  formComponents: {},
})
```

Wrap usage with Suspense:

```tsx
<Suspense fallback={<div>Loading...</div>}>
  <form.AppField name="bio">
    {(field) => <field.RichTextEditor label="Bio" />}
  </form.AppField>
</Suspense>
```

## useTypedAppFormContext: Router Outlet Integration

When you cannot pass the form instance directly (e.g., through a Router Outlet), use `useTypedAppFormContext` as a fallback. Note that this trades type safety for convenience:

```tsx
import { useTypedAppFormContext } from '../hooks/form'

function OutletChild() {
  // WARNING: No type safety — form type is not checked at compile time
  const form = useTypedAppFormContext<typeof formOpts>()

  return (
    <form.AppField name="firstName">
      {(field) => <field.TextField label="First Name" />}
    </form.AppField>
  )
}
```

Prefer `withForm` or explicit prop passing whenever possible. Only use `useTypedAppFormContext` when the component tree makes direct form passing impossible.

## Common Mistakes

- Forgetting to wrap form-level components with `form.AppForm` — `useFormContext` throws without it
- Using `form.Field` instead of `form.AppField` — registered components are not available on plain `form.Field`
- Using an arrow function for `withForm`'s render — ESLint cannot detect hooks violations; always use a named function
- Forgetting `<Suspense>` when using lazy-loaded field components — causes React error
