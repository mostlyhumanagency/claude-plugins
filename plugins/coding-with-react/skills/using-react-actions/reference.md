# React Actions Reference

## Full API Signatures

### useActionState

```tsx
function useActionState<State, Payload>(
  action: (prevState: State, payload: Payload) => State | Promise<State>,
  initialState: State,
  permalink?: string
): [state: State, dispatch: (payload: Payload) => void, isPending: boolean]
```

**Parameters:**
- `action`: Function that receives previous state and payload (typically FormData), returns new state
- `initialState`: Initial value for state before first action completes
- `permalink` (optional): URL for progressive enhancement when JS hasn't loaded

**Returns:**
- `state`: Current state value (initialState before first action completes)
- `dispatch`: Function to trigger the action (use as form's `action` prop)
- `isPending`: Boolean indicating if action is currently running

**Key behaviors:**
- First parameter to action function is ALWAYS previous state
- Second parameter is the payload (FormData when used with forms)
- State updates after action completes
- Automatically handles transitions and pending states

### useFormStatus

```tsx
function useFormStatus(): {
  pending: boolean;
  data: FormData | null;
  method: string | null;
  action: string | ((formData: FormData) => void) | null;
}
```

**Returns:**
- `pending`: True if parent form is submitting
- `data`: FormData being submitted (null if not submitting)
- `method`: HTTP method (GET/POST) or null
- `action`: Form action URL or function

**Critical requirement:**
- MUST be called from a component rendered inside a `<form>` element
- Will NOT work in the same component that renders the `<form>`
- Returns default values (`pending: false`, etc.) if no parent form exists

### useOptimistic

```tsx
function useOptimistic<State>(
  state: State,
  updateFn?: (currentState: State, optimisticValue: State) => State
): [optimisticState: State, addOptimistic: (optimisticValue: State) => void]
```

**Parameters:**
- `state`: Base state to show when no optimistic update is active
- `updateFn` (optional): Reducer to compute optimistic state (defaults to replacing state)

**Returns:**
- `optimisticState`: Current state (base state or optimistically updated)
- `addOptimistic`: Function to apply optimistic update (call inside transition)

**Key behaviors:**
- Optimistic state shown immediately when `addOptimistic` is called
- Automatically reverts to base state when transition completes
- If transition fails, reverts to base state (no special error handling needed)
- Must be called within a transition (form action or `startTransition`)

## Advanced Pattern: Combining All Three Hooks

```tsx
import { useActionState, useOptimistic } from "react";
import { useFormStatus } from "react-dom";

interface User {
  id: string;
  name: string;
  email: string;
}

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending}>
      {pending ? "Saving..." : "Save Changes"}
    </button>
  );
}

function EditProfile({ user }: { user: User }) {
  const [optimisticName, setOptimisticName] = useOptimistic(user.name);
  const [optimisticEmail, setOptimisticEmail] = useOptimistic(user.email);

  const [error, formAction, isPending] = useActionState(
    async (prevError: string | null, formData: FormData) => {
      const name = formData.get("name") as string;
      const email = formData.get("email") as string;

      setOptimisticName(name);
      setOptimisticEmail(email);

      const result = await updateProfile(user.id, name, email);
      return result; // Return error string or null
    },
    null
  );

  return (
    <div>
      <div className="profile-preview">
        <h2>{optimisticName}</h2>
        <p>{optimisticEmail}</p>
      </div>

      <form action={formAction}>
        <label htmlFor="name">Name:</label>
        <input id="name" name="name" defaultValue={user.name} required />

        <label htmlFor="email">Email:</label>
        <input id="email" name="email" type="email" defaultValue={user.email} required />

        {error && <p className="error">{error}</p>}
        <SubmitButton />
      </form>
    </div>
  );
}
```

## Additional Patterns

### FormData Access

```tsx
async function myAction(prevState, formData) {
  const email = formData.get("email");
  const isSubscribed = formData.get("subscribe") === "on";
  const tags = formData.getAll("tags"); // Multiple values
  const data = Object.fromEntries(formData);
  return await processForm(data);
}
```

### Progressive Enhancement

Use the `permalink` parameter for forms that should work without JavaScript:

```tsx
const [state, formAction] = useActionState(
  submitAction,
  initialState,
  "/submit-fallback" // Server endpoint for no-JS fallback
);
```

### Error Handling Patterns

```tsx
// Return structured errors as state
async function action(prev, formData) {
  const result = await validate(formData);
  if (!result.valid) {
    return { errors: result.errors }; // { email: "Invalid", password: "Too short" }
  }
  await save(formData);
  return { errors: null };
}
```

### TypeScript Types

```tsx
// Action state with typed state
type FormState = {
  message: string;
  errors?: Record<string, string>;
} | null;

async function action(
  prevState: FormState,
  formData: FormData
): Promise<FormState> {
  // ...
}

const [state, formAction, isPending] = useActionState<FormState, FormData>(
  action,
  null
);

// Optimistic with typed reducer
const [optimisticTodos, addOptimisticTodo] = useOptimistic<Todo[]>(
  todos,
  (current, newTodo: Todo) => [...current, newTodo]
);
```
