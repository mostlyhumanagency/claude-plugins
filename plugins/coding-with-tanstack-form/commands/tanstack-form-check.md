---
description: "Scan TanStack Form codebase for anti-patterns: missing handlers, validation gaps, performance issues, and suboptimal configurations"
---

# tanstack-form-check

Scan the codebase for common TanStack Form anti-patterns.

## Process

1. Check field patterns:
   - Inputs missing field.handleBlur — onBlur validation silently broken
   - Inputs missing field.handleChange — field state never updates
   - Fields without validators — no validation on user input
   - field.state.value used without defaultValues — undefined initial state
2. Check validation patterns:
   - onBlur validators without field.handleBlur on the input element
   - Async validators without asyncDebounceMs — excessive network requests
   - Form-level and field-level validators on same field — field-level overwrites form-level
   - Dynamic validation (onDynamic) without revalidateLogic() — validators never called
3. Check submission patterns:
   - form.handleSubmit() without e.preventDefault() on form onSubmit
   - Schema transforms expected in onSubmit — only input data available, must re-parse
   - Missing canSubmit check on submit button
   - Missing onSubmitInvalid for focus management
4. Check reactivity patterns:
   - useStore without selector — subscribes to entire store, excessive re-renders
   - Accessing form.state directly instead of useStore/form.Subscribe — stale values
   - form.Subscribe wrapping large component trees instead of small sections
5. Check composition patterns:
   - Repeated field patterns that should use createFormHook
   - withForm render prop as arrow function — ESLint issues, use named function
   - useTypedAppFormContext without type alignment warning
6. Check array patterns:
   - Array fields missing mode="array"
   - Subfield names without bracket notation (people.0.name vs people[0].name)
   - Missing key prop when mapping array items
7. Report each finding with file path, line number, severity, and fix
8. Summarize: total issues by severity, recommended action order
