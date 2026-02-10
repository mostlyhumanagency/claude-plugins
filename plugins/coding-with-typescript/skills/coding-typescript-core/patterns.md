# Common Patterns

Standard immutable updates and error-handling patterns.

## Immutable Updates

```typescript
// ✅ Immutable array operations
const added = [...items, newItem];
const updated = items.map(item =>
  item.id === id ? { ...item, name } : item
);
const filtered = items.filter(item => item.active);
const sorted = [...items].sort((a, b) => a.name.localeCompare(b.name));

// ✅ Immutable object updates
const updated = { ...obj, field: newValue };
const merged = { ...defaults, ...overrides };
```

## Type-Safe Error Handling

```typescript
try {
  const data: unknown = JSON.parse(input);
  // Validate before use
  if (isValidUser(data)) {
    return { ok: true, value: data };
  }
  return { ok: false, error: new Error("Invalid format") };
} catch (error) {
  if (error instanceof Error) {
    return { ok: false, error };
  }
  return { ok: false, error: new Error("Unknown error") };
}
```
