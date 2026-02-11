---
name: ssr-tanstack-form
description: Use when integrating TanStack Form with server-side rendering — TanStack Start (createServerValidate, mergeForm, useTransform), Next.js App Router (Server Actions, useActionState), Remix (route actions), shared formOptions pattern
---

# SSR with TanStack Form

## Overview

TanStack Form supports server-side rendering across TanStack Start, Next.js, and Remix. All three frameworks follow a common pattern:

1. **`formOptions()`** for shared config between client and server
2. **`createServerValidate`** for server-side validation
3. **`mergeForm` + `useTransform`** for syncing server state back to the client form

## Common Pattern: formOptions

Define shared form configuration in a separate file so both client and server can import it.

```tsx
// shared/form-options.ts
import { formOptions } from '@tanstack/react-form'

export const signupFormOpts = formOptions({
  defaultValues: {
    email: '',
    password: '',
    confirmPassword: '',
  },
})
```

## TanStack Start

Import SSR utilities from `@tanstack/react-form-start`.

### Server Function

```tsx
// server/validate-signup.ts
import { createServerFn } from '@tanstack/react-start'
import { createServerValidate } from '@tanstack/react-form-start'
import { ServerValidateError } from '@tanstack/react-form'
import { signupFormOpts } from '../shared/form-options'

const serverValidate = createServerValidate({
  ...signupFormOpts,
  onServerValidate({ value }) {
    if (value.password !== value.confirmPassword) {
      return {
        fields: {
          confirmPassword: 'Passwords do not match',
        },
      }
    }
  },
})

export const handleForm = createServerFn({ method: 'POST' })
  .validator((formData) => {
    if (!(formData instanceof FormData)) {
      throw new Error('Expected FormData')
    }
    return formData
  })
  .handler(async ({ data: formData }) => {
    try {
      await serverValidate(formData)
    } catch (e) {
      if (e instanceof ServerValidateError) {
        return e.response
      }
      throw e
    }
    // Validation passed — save to DB, etc.
  })
```

### Client Component

```tsx
import { useForm, mergeForm } from '@tanstack/react-form'
import { useTransform } from '@tanstack/react-form-start'
import { signupFormOpts } from '../shared/form-options'
import { handleForm } from '../server/validate-signup'

export function SignupForm() {
  const form = useForm({
    ...signupFormOpts,
    transform: useTransform(
      (baseForm) => mergeForm(baseForm, state),
      [state],
    ),
    onSubmit: async ({ value }) => {
      console.log('Client submit:', value)
    },
  })

  return (
    <form
      action={handleForm.url}
      method="post"
      encType="multipart/form-data"
      onSubmit={() => form.handleSubmit()}
    >
      {/* fields here */}
    </form>
  )
}
```

## Next.js App Router

Import SSR utilities from `@tanstack/react-form-nextjs`.

### Server Action

```tsx
// app/signup/action.ts
'use server'

import { createServerValidate, ServerValidateError } from '@tanstack/react-form'

import { signupFormOpts } from './form-options'

const serverValidate = createServerValidate({
  ...signupFormOpts,
  onServerValidate({ value }) {
    if (value.password !== value.confirmPassword) {
      return {
        fields: {
          confirmPassword: 'Passwords do not match',
        },
      }
    }
  },
})

export async function signupAction(prev: unknown, formData: FormData) {
  try {
    await serverValidate(formData)
  } catch (e) {
    if (e instanceof ServerValidateError) {
      return e.formState
    }
    throw e
  }
  // Validation passed — save to DB, redirect, etc.
}
```

### Client Component

```tsx
// app/signup/signup-form.tsx
'use client'

import { useActionState } from 'react'
import { useForm, mergeForm } from '@tanstack/react-form'
import { useTransform } from '@tanstack/react-form-nextjs'
import { signupFormOpts } from './form-options'
import { signupAction } from './action'

const initialFormState = {
  errorMap: { onServer: undefined },
  errors: [],
}

export function SignupForm() {
  const [state, action] = useActionState(signupAction, initialFormState)

  const form = useForm({
    ...signupFormOpts,
    transform: useTransform(
      (baseForm) => mergeForm(baseForm, state),
      [state],
    ),
    onSubmit: async ({ value }) => {
      console.log('Client submit:', value)
    },
  })

  return (
    <form action={action} onSubmit={() => form.handleSubmit()}>
      <form.Field
        name="email"
        children={(field) => (
          <div>
            <label htmlFor="email">Email</label>
            <input
              id="email"
              name="email"
              value={field.state.value}
              onChange={(e) => field.handleChange(e.target.value)}
            />
            {field.state.meta.errors.map((error, i) => (
              <p key={i} style={{ color: 'red' }}>{error}</p>
            ))}
          </div>
        )}
      />

      <form.Field
        name="password"
        children={(field) => (
          <div>
            <label htmlFor="password">Password</label>
            <input
              id="password"
              name="password"
              type="password"
              value={field.state.value}
              onChange={(e) => field.handleChange(e.target.value)}
            />
          </div>
        )}
      />

      <form.Field
        name="confirmPassword"
        children={(field) => (
          <div>
            <label htmlFor="confirmPassword">Confirm Password</label>
            <input
              id="confirmPassword"
              name="confirmPassword"
              type="password"
              value={field.state.value}
              onChange={(e) => field.handleChange(e.target.value)}
            />
            {field.state.meta.errors.map((error, i) => (
              <p key={i} style={{ color: 'red' }}>{error}</p>
            ))}
          </div>
        )}
      />

      <form.Subscribe
        selector={(state) => ({
          canSubmit: state.canSubmit,
          isSubmitting: state.isSubmitting,
        })}
        children={({ canSubmit, isSubmitting }) => (
          <button type="submit" disabled={!canSubmit || isSubmitting}>
            {isSubmitting ? 'Signing up...' : 'Sign Up'}
          </button>
        )}
      />
    </form>
  )
}
```

**Warning:** Do not import client-only code from `@tanstack/react-form-nextjs` in server files. The `useTransform` hook is client-only.

## Remix

Import SSR utilities from `@tanstack/react-form-remix`.

### Route Action

```tsx
// app/routes/signup.tsx
import type { ActionFunctionArgs } from '@remix-run/node'
import { useActionData } from '@remix-run/react'
import { Form } from '@remix-run/react'
import { useForm, mergeForm } from '@tanstack/react-form'
import { createServerValidate, ServerValidateError } from '@tanstack/react-form'
import { useTransform } from '@tanstack/react-form-remix'
import { signupFormOpts } from '../shared/form-options'

const serverValidate = createServerValidate({
  ...signupFormOpts,
  onServerValidate({ value }) {
    if (value.password !== value.confirmPassword) {
      return {
        fields: {
          confirmPassword: 'Passwords do not match',
        },
      }
    }
  },
})

export async function action({ request }: ActionFunctionArgs) {
  const formData = await request.formData()
  try {
    await serverValidate(formData)
  } catch (e) {
    if (e instanceof ServerValidateError) {
      return e.formState
    }
    throw e
  }
  // Validation passed
}

export default function SignupRoute() {
  const actionData = useActionData<typeof action>()

  const form = useForm({
    ...signupFormOpts,
    transform: useTransform(
      (baseForm) => mergeForm(baseForm, actionData ?? initialFormState),
      [actionData],
    ),
  })

  return (
    <Form method="post">
      {/* form.Field components here */}
    </Form>
  )
}
```

## Summary of Framework Differences

| Feature | TanStack Start | Next.js | Remix |
|---|---|---|---|
| SSR import | `@tanstack/react-form-start` | `@tanstack/react-form-nextjs` | `@tanstack/react-form-remix` |
| Server handler | `createServerFn` | Server Action (`'use server'`) | Route `action` |
| Error return | `e.response` | `e.formState` | `e.formState` |
| Form element | `<form action={fn.url}>` | `<form action={action}>` | `<Form method="post">` |
| State source | Server function state | `useActionState` | `useActionData` |
| Transform hook | `useTransform` from start | `useTransform` from nextjs | `useTransform` from remix |

All three use `formOptions()` for shared defaults, `createServerValidate` + `ServerValidateError` for server validation, and `mergeForm` + `useTransform` to sync server state to the client.
