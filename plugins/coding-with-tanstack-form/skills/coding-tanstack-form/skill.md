---
name: coding-tanstack-form
description: Use only when a user wants an overview of available TanStack Form skills or when unsure which TanStack Form skill applies. Routes to the correct sub-skill.
---

# TanStack Form Overview

TanStack Form is a headless, type-safe form management library for React (and other frameworks). It provides controlled inputs with first-class TypeScript inference, built-in Standard Schema validation (Zod, Valibot, ArkType), and fine-grained reactivity with no unnecessary re-renders.

## Quick Start

```bash
npm install @tanstack/react-form
```

```tsx
import { useForm } from '@tanstack/react-form'

function App() {
  const form = useForm({
    defaultValues: { firstName: '', age: 0 },
    onSubmit: async ({ value }) => console.log(value),
  })

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.handleSubmit() }}>
      <form.Field name="firstName">
        {(field) => (
          <input
            value={field.state.value}
            onChange={(e) => field.handleChange(e.target.value)}
          />
        )}
      </form.Field>
      <button type="submit">Submit</button>
    </form>
  )
}
```

## Core Concepts

- **useForm** — create a form instance with defaultValues, onSubmit, and validators
- **form.Field** — type-safe field component with render prop for controlled inputs
- **Validation** — field-level and form-level, sync and async, with Standard Schema support
- **Composition** — createFormHook and withForm for reusable, tree-shakeable form components
- **Array Fields** — pushValue, removeValue, and moveValue for dynamic lists
- **Submission** — handleSubmit, canSubmit, onSubmitMeta for server function integration
- **Linked Fields** — listeners and onChangeListenTo for cross-field reactivity
- **Reactivity** — useStore and form.Subscribe for fine-grained subscriptions
- **SSR** — server-side rendering with Next.js, TanStack Start, and Remix
- **Type Safety** — full type inference, typed errors, and Register interface

## Skill Routing

| Task | Skill |
|---|---|
| useForm, defaultValues, formOptions | `setting-up-tanstack-form` |
| Validators, async, schema, debounce, errorMap | `validating-tanstack-form` |
| createFormHook, withForm, withFieldGroup | `composing-tanstack-form` |
| Array fields, pushValue, removeValue | `using-tanstack-form-arrays` |
| onSubmit, onSubmitMeta, canSubmit, focus | `submitting-tanstack-form` |
| Linked fields, listeners, onChangeListenTo | `linking-tanstack-form-fields` |
| useStore, form.Subscribe, selectors | `reacting-to-tanstack-form` |
| SSR, Next.js, TanStack Start, Remix | `ssr-tanstack-form` |
| Type inference, typed errors, Register | `typing-tanstack-form` |
