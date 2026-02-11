---
description: "Audit TanStack Form project health: installation, useForm configuration, validation setup, composition patterns, and common misconfigurations"
---

# tanstack-form-doctor

Audit the health of a TanStack Form setup.

## Process

1. Read `package.json` and verify:
   - `@tanstack/react-form` is installed
   - Version is current (v1+)
   - Validator adapter installed if using schema validation (zod, valibot, etc.)
   - DevTools packages in devDependencies (@tanstack/react-devtools, @tanstack/react-form-devtools)
2. Find useForm usage and check:
   - defaultValues provided for all fields (prevents uncontrolled input warnings)
   - onSubmit handler defined
   - Validators configured at form or field level
3. Check form composition patterns:
   - createFormHook used for apps with multiple forms (reduces boilerplate)
   - withForm/withFieldGroup for large multi-section forms
   - Consistent field component patterns across the app
4. Check validation patterns:
   - Schema validation (Zod/Valibot/ArkType) used consistently
   - Async validators have debouncing configured
   - Both field-level and form-level validation present where appropriate
5. Check SSR setup if applicable:
   - Correct framework adapter imported (react-form-start, react-form-nextjs, react-form-remix)
   - createServerValidate configured
   - mergeForm + useTransform used for state synchronization
6. Scan for common misconfigurations:
   - Missing field.handleBlur on inputs with onBlur validation
   - form.handleSubmit() called without e.preventDefault()
   - Array fields without mode="array"
   - Linked fields without onChangeListenTo/onBlurListenTo
7. Report findings with severity and suggested fix
8. Summarize: total issues, health score, top priorities
