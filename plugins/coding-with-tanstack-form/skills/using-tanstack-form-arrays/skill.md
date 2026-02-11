---
name: using-tanstack-form-arrays
description: Use when working with array fields in TanStack Form — mode="array", pushValue, removeValue, swapValues, moveValue, nested subfields with bracket notation
---

# Using TanStack Form Arrays

## Array Field Setup

Use `form.Field` with `mode="array"` to work with array fields. Initialize the array in `defaultValues`.

```tsx
const form = useForm({
  defaultValues: { people: [] as Array<{ name: string; age: number }> },
  onSubmit: async ({ value }) => console.log(value),
})
```

## Accessing Array Values

Inside an array field, access `field.state.value` to get the current array and map over items.

## Array Manipulation Methods

- **Add items**: `field.pushValue({ name: '', age: 0 })`
- **Remove items**: `field.removeValue(index)`
- **Swap items**: `field.swapValues(indexA, indexB)`
- **Move items**: `field.moveValue(fromIndex, toIndex)`

## Nested Subfields

Access nested fields within array items using bracket notation: `people[${i}].name`

## Complete Example

```tsx
const form = useForm({
  defaultValues: { people: [] as Array<{ name: string; age: number }> },
  onSubmit: async ({ value }) => console.log(value),
})

// ...
<form.Field name="people" mode="array">
  {(field) => (
    <div>
      {field.state.value.map((_, i) => (
        <div key={i}>
          <form.Field name={`people[${i}].name`}>
            {(subField) => (
              <input
                value={subField.state.value}
                onChange={(e) => subField.handleChange(e.target.value)}
              />
            )}
          </form.Field>
          <button onClick={() => field.removeValue(i)}>Remove</button>
        </div>
      ))}
      <button onClick={() => field.pushValue({ name: '', age: 0 })}>
        Add Person
      </button>
    </div>
  )}
</form.Field>
```
